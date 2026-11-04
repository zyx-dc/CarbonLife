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
}

const LOCAL_STORE = 'carbonlife_family_local_v2';

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
      const storeId = saved === '' ? LOCAL_STORE : 'fam_' + saved;
      await this.kv.open(ctx, storeId);
      this.kv.onChanged(() => {
        void this.reload();
      });
      await this.reload();
      this.kv.sync();
      this.initialized = true;
      this.pushLocal();
      console.info('FamilyService init ok store=' + storeId + ' members=' + this.members.length);
    } catch (e) {
      console.error('FamilyService init failed: ' + JSON.stringify(e));
    }
  }

  private async ensureDeviceId(): Promise<string> {
    // 系统级设备 ID 由 udid-hash + appid 派生，两台设备天然不同；
    // 旧的随机 UUID 存在 Preferences 里，备份恢复到另一台设备会撞 key。
    const systemId = this.kv.localDeviceId();
    if (systemId !== '') {
      return systemId;
    }
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
          list.push(JSON.parse(json) as MemberData);
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
    await this.kv.remove(this.localDeviceId);
    this.kv.sync();
    await this.applySession('');
  }

  /** 切换 KVStore 组；失败直接抛给 UI，不把无效 session 写进本地。 */
  private async applySession(code: string): Promise<void> {
    if (this.ctx === null) {
      throw new Error('FamilyService not initialized');
    }
    const storeId = code === '' ? LOCAL_STORE : 'fam_' + code;
    await this.kv.open(this.ctx, storeId);
    this.kv.onChanged(() => {
      void this.reload();
    });
    this.sessionId = code;
    await CarbonStore.get().setSetting(AppConst.KEY_FAMILY_SESSION, code);
    await this.reload();
    this.kv.sync();
    this.pushLocal();
    this.notify();
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
      updatedAt: Date.now()
    };
    void this.kv.put(member.deviceId, JSON.stringify(member)).then(() => {
      this.kv.sync();
      return this.reload();
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
