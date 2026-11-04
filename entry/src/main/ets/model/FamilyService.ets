import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { CarbonStore } from './CarbonStore';
import { AppConst } from '../common/Constants';
import { FamilyKvStore } from './FamilyKvStore';

/**
 * 家庭组：基于分布式 KV 的跨设备成员聚合（docs/ROADMAP.md 方案 A）。
 *
 * key   = member:<deviceId>
 * value = JSON.stringify(MemberData)
 * store = 家庭码（未加入时用本地 store）
 */
export interface MemberData {
  deviceId: string;
  nickname: string;
  saved: number;
  points: number;
  updatedAt: number;
  /**
   * 已退出家庭的墓碑标记。
   * 不能直接 delete key：对端离线时没收到删除，等它上线会把缓存里的旧值 PUSH 回来，
   * 于是「已经退出的人」永远留在对端成员列表里。墓碑是一份带时间戳的正式数据，
   * 能按 per-key 最新值规则压住旧记录。
   */
  deleted?: boolean;
}

const LOCAL_STORE = 'carbonlife_family_local_v2';
/**
 * 对端不在线时的退避重试间隔。
 * 冷启动那一刻软总线往往还没发现对端，getAvailableDeviceListSync() 返回空，
 * 若此时不重试，这一轮家庭数据就永远推不出去——这正是「拔掉调试线就不同步」的主因。
 */
const RETRY_DELAYS: number[] = [1000, 3000, 10000, 30000];

export class FamilyService {
  private static instance: FamilyService | null = null;
  private kv: FamilyKvStore = new FamilyKvStore();
  private ctx: common.Context | null = null;
  private members: MemberData[] = [];
  private localDeviceId: string = '';
  private sessionId: string = '';
  private nickname: string = '我';
  private initialized: boolean = false;
  private versionCounter: number = 1;
  private changeListeners: Array<() => void> = [];
  private retryTimer: number = -1;
  private retryStep: number = 0;
  private pendingSync: boolean = false;
  private tickTimer: number = -1;

  static get(): FamilyService {
    if (FamilyService.instance === null) {
      FamilyService.instance = new FamilyService();
    }
    return FamilyService.instance;
  }

  async init(ctx: common.Context): Promise<void> {
    if (this.initialized) {
      return;
    }
    this.ctx = ctx;
    this.localDeviceId = await this.ensureDeviceId();
    this.nickname = await CarbonStore.get().getSetting(AppConst.KEY_FAMILY_NAME, '我');
    let saved = await CarbonStore.get().getSetting(AppConst.KEY_FAMILY_SESSION, '');
    if (saved !== '' && !/^[A-Za-z0-9_]{1,64}$/.test(saved)) {
      console.warn('FamilyService drop invalid/legacy session ' + saved);
      await CarbonStore.get().setSetting(AppConst.KEY_FAMILY_SESSION, '');
      saved = '';
    }
    this.sessionId = saved;
    try {
      const storeId = saved === '' ? LOCAL_STORE : 'fam2_' + saved;
      await this.kv.open(ctx, storeId);
      this.kv.onChanged(() => {
        void this.reload();
      });
      await this.reload();
      // 先挂上线监听再补推，避免「挂监听之前对端刚好上线」这类事件被错过
      this.kv.watchPeers(() => {
        console.info('FamilyService peer online -> resync');
        this.resync();
      });
      this.initialized = true;
      this.resync();
      this.pushLocal();
      console.info('FamilyService init ok store=' + storeId + ' members=' + this.members.length);
    } catch (e) {
      console.error('FamilyService init failed: ' + JSON.stringify(e));
    }
  }

  /**
   * 补一次双向同步。对端不在线时按 1s/3s/10s/30s 退避重试。
   * 三个入口会调它：冷启动 init、对端上线（deviceStateChange）、App 回到前台。
   */
  resync(): void {
    // init() 一开始就会设 ctx，但此时 KV 可能还没打开；用 initialized 挡住，
    // 否则冷启动的前台回调会先闪一次「待同步」。init 末尾自己会补一次。
    if (this.ctx === null || !this.initialized) {
      return;
    }
    // 未加入家庭时不存在需要共享的数据。此时若仍 sync，会把各设备「独处时」
    // 的旧记录互相对拉，表现为退出家庭组后本地又冒出 2 个成员。
    if (this.sessionId === '') {
      this.pendingSync = false;
      this.clearRetry();
      return;
    }
    const targets = this.kv.sync();
    if (targets > 0) {
      this.pendingSync = false;
      this.clearRetry();
      this.notify();
      return;
    }
    this.pendingSync = true;
    this.scheduleRetry();
    this.notify();
  }

  private scheduleRetry(): void {
    if (this.retryTimer !== -1 || this.retryStep >= RETRY_DELAYS.length) {
      return;
    }
    const delay: number = RETRY_DELAYS[this.retryStep];
    this.retryStep = this.retryStep + 1;
    console.info('FamilyService retry in ' + delay + 'ms step=' + this.retryStep);
    this.retryTimer = setTimeout(() => {
      this.retryTimer = -1;
      this.resync();
    }, delay);
  }

  private clearRetry(): void {
    if (this.retryTimer !== -1) {
      clearTimeout(this.retryTimer);
      this.retryTimer = -1;
    }
    this.retryStep = 0;
  }

  /**
   * 前台保活心跳。退避重试 4 次（共 44 秒）就会停，若对端更晚才上线，
   * 只靠 deviceStateChange 也可能被系统省电策略吞掉，这里再兜一层。
   * 只在有积压时动作，没有积压就是空转，开销可忽略。
   */
  startTicker(): void {
    if (this.tickTimer !== -1) {
      return;
    }
    this.tickTimer = setInterval(() => {
      if (this.pendingSync) {
        console.info('FamilyService ticker retry');
        this.resync();
      }
    }, 30000);
    console.info('FamilyService ticker started');
  }

  /** 进后台停掉，避免在后台空耗电量；回到前台会重新拉起。 */
  stopTicker(): void {
    if (this.tickTimer !== -1) {
      clearInterval(this.tickTimer);
      this.tickTimer = -1;
      console.info('FamilyService ticker stopped');
    }
  }

  private async ensureDeviceId(): Promise<string> {
    // 成员键必须跨重装稳定：用 Preferences 里的随机 UUID。
    // 系统 getLocalDeviceId 会随签名/安装变化，不能当成员身份。
    let id = await CarbonStore.get().getSetting(AppConst.KEY_FAMILY_DEVICE_ID, '');
    if (id === '') {
      id = util.generateRandomUUID(true);
      await CarbonStore.get().setSetting(AppConst.KEY_FAMILY_DEVICE_ID, id);
    }
    return id;
  }

  private async reload(): Promise<void> {
    try {
      const raw = await this.kv.readAll();
      const list: MemberData[] = [];
      raw.forEach((json: string) => {
        try {
          const m = JSON.parse(json) as MemberData;
          if (m.deleted === true) {
            return;
          }
          list.push(m);
        } catch (e) {
          console.error('FamilyService bad member json: ' + json);
        }
      });
      this.members = list;
      console.info('FamilyService reload members=' + list.length + ' ids=' +
        list.map((m: MemberData) => m.deviceId).join(','));
      this.notify();
    } catch (e) {
      console.error('FamilyService reload failed: ' + JSON.stringify(e));
    }
  }

  async genSession(): Promise<string> {
    const code = Math.floor(1000000000 + Math.random() * 9000000000).toString();
    await this.applySession(code);
    console.info('FamilyService genSession code=' + code);
    return code;
  }

  async joinSession(sessionId: string): Promise<void> {
    await this.applySession(sessionId);
    console.info('FamilyService joinSession code=' + sessionId);
  }

  async leaveSession(): Promise<void> {
    // 不删 key，改写墓碑：对端离线时收不到删除，回来会把旧值 PUSH 回来。
    // 切换 store 会 close 当前 store，所以先留一个同步窗口，让墓碑推出去再走。
    const tomb: MemberData = {
      deviceId: this.localDeviceId,
      nickname: this.nickname,
      saved: 0,
      points: 0,
      updatedAt: Date.now(),
      deleted: true
    };
    try {
      await this.kv.put(this.localDeviceId, JSON.stringify(tomb));
      const targets = this.kv.sync();
      console.info('FamilyService leave tombstone targets=' + targets);
      if (targets > 0) {
        await this.delay(1200);
      }
    } catch (e) {
      console.error('FamilyService leave tombstone failed: ' + JSON.stringify(e));
    }
    await this.applySession('');
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  /** 切换 KVStore 组；失败直接抛给 UI，不把无效 session 写进本地。 */
  private async applySession(code: string): Promise<void> {
    if (this.ctx === null) {
      throw new Error('FamilyService not initialized');
    }
    const storeId = code === '' ? LOCAL_STORE : 'fam2_' + code;
    await this.kv.open(this.ctx, storeId);
    this.kv.onChanged(() => {
      void this.reload();
    });
    this.sessionId = code;
    await CarbonStore.get().setSetting(AppConst.KEY_FAMILY_SESSION, code);
    await this.reload();
    this.pushLocal();
    this.notify();
  }

  private afterPut(): void {
    // 同 resync()：未加入家庭时本地 store 只服务本机，不做跨设备同步
    if (this.sessionId === '') {
      this.pendingSync = false;
      this.clearRetry();
      void this.reload();
      return;
    }
    const targets = this.kv.sync();
    this.pendingSync = targets === 0;
    if (this.pendingSync) {
      this.scheduleRetry();
    } else {
      this.clearRetry();
    }
    void this.reload();
  }

  pushLocal(): void {
    if (this.ctx === null || this.localDeviceId === '') {
      return;
    }
    const store = CarbonStore.get();
    const member: MemberData = {
      deviceId: this.localDeviceId,
      nickname: this.nickname,
      saved: store.totalSaved(),
      points: store.pointsBalance(),
      updatedAt: Date.now(),
      deleted: false
    };
    void this.kv.put(member.deviceId, JSON.stringify(member)).then(() => {
      this.afterPut();
    }).catch((e: Error) => {
      console.error('FamilyService pushLocal failed: ' + JSON.stringify(e));
    });
  }

  setNickname(name: string): void {
    this.nickname = name === '' ? '我' : name;
    CarbonStore.get().setSetting(AppConst.KEY_FAMILY_NAME, this.nickname);
    this.pushLocal();
    this.notify();
  }

  getNickname(): string {
    return this.nickname;
  }

  getSaved(): number {
    return this.members.reduce((sum: number, m: MemberData) => sum + m.saved, 0);
  }

  getPoints(): number {
    return this.members.reduce((sum: number, m: MemberData) => sum + m.points, 0);
  }

  getMembers(): MemberData[] {
    return this.members.slice();
  }

  isLocal(deviceId: string): boolean {
    return deviceId === this.localDeviceId;
  }

  getSessionId(): string {
    return this.sessionId;
  }

  isPeerOnline(): boolean {
    return this.members.length > 1;
  }

  /** 有本地写入还没推出去，正在退避重试。 */
  isSyncPending(): boolean {
    return this.pendingSync;
  }

  /** 上次同步成功的时间戳；0 表示本次进程内还没成功过。 */
  lastSyncAt(): number {
    return this.kv.lastSuccessAt();
  }

  addChangeListener(cb: () => void): void {
    this.changeListeners.push(cb);
  }

  removeChangeListener(cb: () => void): void {
    this.changeListeners = this.changeListeners.filter((l: () => void) => l !== cb);
  }

  private notify(): void {
    this.versionCounter = this.versionCounter + 1;
    AppStorage.setOrCreate('familyVersion', this.versionCounter);
    this.changeListeners.forEach((l: () => void) => l());
  }
}
