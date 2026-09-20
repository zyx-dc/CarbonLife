import { distributedDataObject } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { CarbonStore } from './CarbonStore';

class FamilyData {
  nickname: string = '我';
  saved: number = 0;
  points: number = 0;
  updatedAt: number = 0;
}

export class FamilyService {
  private static instance: FamilyService | null = null;
  private obj: distributedDataObject.DataObject | null = null;
  private model: FamilyData = new FamilyData();
  private sessionId: string = '';
  private peerOnline: boolean = false;

  static get(): FamilyService {
    if (FamilyService.instance === null) {
      FamilyService.instance = new FamilyService();
    }
    return FamilyService.instance;
  }

  init(ctx: common.Context): void {
    if (this.obj !== null) {
      return;
    }
    this.obj = distributedDataObject.create(ctx, this.model);
    this.obj.on('change', (sessionId: string, fields: Array<string>) => {
      this.model.updatedAt = Date.now();
      this.notify();
    });
    this.obj.on('status', (sessionId: string, networkId: string, status: string) => {
      this.peerOnline = status === 'online';
      this.notify();
    });
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
    this.sessionId = sessionId;
    await this.obj.setSessionId(sessionId);
    this.notify();
  }

  async leaveSession(): Promise<void> {
    if (this.obj === null) {
      return;
    }
    this.sessionId = '';
    await this.obj.setSessionId('');
    this.notify();
  }

  pushLocal(): void {
    const store = CarbonStore.get();
    if (this.model.nickname === '') {
      this.model.nickname = '我';
    }
    this.model.saved = store.totalSaved();
    this.model.points = store.totalPoints();
    this.model.updatedAt = Date.now();
    this.notify();
  }

  setNickname(name: string): void {
    this.model.nickname = name === '' ? '我' : name;
    this.notify();
  }

  getNickname(): string {
    return this.model.nickname;
  }

  getSaved(): number {
    return this.model.saved;
  }

  getPoints(): number {
    return this.model.points;
  }

  getSessionId(): string {
    return this.sessionId;
  }

  isPeerOnline(): boolean {
    return this.peerOnline;
  }

  private notify(): void {
    const v = AppStorage.get<number>('familyVersion') ?? 0;
    AppStorage.setOrCreate('familyVersion', v + 1);
  }
}
