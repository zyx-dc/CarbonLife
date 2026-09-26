import { CarbonStore } from './CarbonStore';

/**
 * 云备份提供方接口（预留 AGC Cloud DB / 城市碳普惠平台接入）。
 * 未注入时，云备份降级为不可用；本地整包备份 / 恢复始终可用。
 */
export interface CloudBackupProvider {
  isEnabled(): boolean;
  upload(snapshot: string): Promise<boolean>;
  download(): Promise<string>;
}

/**
 * 数据备份 / 恢复服务。
 * - 本地：整包快照（记录 + 兑换 + 任务奖励）导出 / 合并恢复。
 * - 云：通过 setCloudProvider 注入实现后启用（当前默认未接入）。
 */
export class BackupService {
  private static provider: CloudBackupProvider | null = null;

  static setCloudProvider(provider: CloudBackupProvider | null): void {
    BackupService.provider = provider;
  }

  static isCloudEnabled(): boolean {
    const p = BackupService.provider;
    return p !== null && p.isEnabled();
  }

  static snapshot(): string {
    return CarbonStore.get().exportSnapshot();
  }

  static restore(json: string): number {
    return CarbonStore.get().importSnapshot(json);
  }

  static async backupToCloud(): Promise<boolean> {
    const p = BackupService.provider;
    if (p === null || !p.isEnabled()) {
      return false;
    }
    return p.upload(BackupService.snapshot());
  }

  static async restoreFromCloud(): Promise<number> {
    const p = BackupService.provider;
    if (p === null || !p.isEnabled()) {
      return -1;
    }
    const json = await p.download();
    return json === '' ? -1 : BackupService.restore(json);
  }
}
