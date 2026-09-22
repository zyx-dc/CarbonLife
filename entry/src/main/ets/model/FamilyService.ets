import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { CarbonStore } from './CarbonStore';
import { AppConst } from '../common/Constants';

export class MemberData {
  deviceId: string = '';
  nickname: string = '我';
  saved: number = 0;
  points: number = 0;
  updatedAt: number = 0;
}

class FamilyData {
  members: MemberData[] = [];
}

export class FamilyService {
  private static instance: FamilyService | null = null;
  private obj: distributedDataObject.DataObject | null = null;
  private model: FamilyData = new FamilyData();
  private localDeviceId: string = '';
  private sessionId: string = '';
  private peerOnline: boolean = false;
  private versionCounter: number = 1;
  private changeListeners: Array<() => void> = [];

  static get(): FamilyService {
    if (FamilyService.instance === null) {
      FamilyService.instance = new FamilyService();
    }
    return FamilyService.instance;
  }

  async init(ctx: common.Context): Promise<void> {
    if (this.obj !== null) {
      return;
    }
    this.localDeviceId = await this.ensureDeviceId();
    // 清理历史版本可能残留的 deviceId 为空的幽灵成员
    this.model.members = this.model.members.filter((m: MemberData) => m.deviceId !== '');
    try {
      this.obj = distributedDataObject.create(ctx, this.model);
      this.obj.on('change', (sessionId: string, fields: Array<string>) => {
        this.notify();
      });
      this.obj.on('status', (sessionId: string, networkId: string, status: string) => {
        this.peerOnline = status === 'online';
        this.notify();
      });
    } catch (e) {
      console.error('FamilyService init failed: ' + JSON.stringify(e));
      return;
    }
    const name = await CarbonStore.get().getSetting(AppConst.KEY_FAMILY_NAME, '我');
    this.setNickname(name);
  }

  private async ensureDeviceId(): Promise<string> {
    let id = await CarbonStore.get().getSetting(AppConst.KEY_FAMILY_DEVICE_ID, '');
    if (id === '') {
      id = util.generateRandomUUID(true);
      await CarbonStore.get().setSetting(AppConst.KEY_FAMILY_DEVICE_ID, id);
    }
    return id;
  }

  private data(): FamilyData {
    return (this.obj ?? this.model) as FamilyData;
  }

  private localMember(): MemberData {
    const data = this.data();
    let member = data.members.find((m: MemberData) => m.deviceId === this.localDeviceId);
    if (!member) {
      member = new MemberData();
      member.deviceId = this.localDeviceId;
      // 仅在 deviceId 就绪后才写入成员表，避免 init 完成前产生幽灵成员
      if (this.localDeviceId !== '') {
        data.members.push(member);
      }
    }
    return member;
  }

  genSession(): string {
    this.sessionId = distributedDataObject.genSessionId();
    this.notify();
    return this.sessionId;
  }

  async joinSession(sessionId: string): Promise<void> {
    if (this.obj === null) {
      return;
    }
    try {
      this.sessionId = sessionId;
      await this.obj.setSessionId(sessionId);
      this.notify();
    } catch (e) {
      console.error('FamilyService joinSession failed: ' + JSON.stringify(e));
    }
  }

  async leaveSession(): Promise<void> {
    if (this.obj === null) {
      return;
    }
    try {
      this.sessionId = '';
      await this.obj.setSessionId('');
      this.notify();
    } catch (e) {
      console.error('FamilyService leaveSession failed: ' + JSON.stringify(e));
    }
  }

  pushLocal(): void {
    if (this.obj === null) {
      return;
    }
    const store = CarbonStore.get();
    const member = this.localMember();
    if (member.nickname === '') {
      member.nickname = '我';
    }
    member.saved = store.totalSaved();
    member.points = store.totalPoints();
    member.updatedAt = Date.now();
    this.notify();
  }

  setNickname(name: string): void {
    const member = this.localMember();
    member.nickname = name === '' ? '我' : name;
    CarbonStore.get().setSetting(AppConst.KEY_FAMILY_NAME, member.nickname);
    this.notify();
  }

  getNickname(): string {
    return this.localMember().nickname;
  }

  getSaved(): number {
    return this.data().members.reduce((sum: number, m: MemberData) => sum + m.saved, 0);
  }

  getPoints(): number {
    return this.data().members.reduce((sum: number, m: MemberData) => sum + m.points, 0);
  }

  getMembers(): MemberData[] {
    return this.data().members.slice();
  }

  isLocal(deviceId: string): boolean {
    return deviceId === this.localDeviceId;
  }

  getSessionId(): string {
    return this.sessionId;
  }

  isPeerOnline(): boolean {
    return this.peerOnline;
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
