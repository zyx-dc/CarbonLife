import { cloudStorage } from '@kit.CloudFoundationKit';
import { request } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { CloudBackupProvider } from './BackupService';

/**
 * AGC 云存储备份实现（Cloud Foundation Kit）。
 * - 存储实例：AGC 云开发「云存储」默认实例（本项目：carbonlife-z58pd）
 * - 备份对象：backup/snapshot.json（整包快照，见 CarbonStore.exportSnapshot）
 * - 上传/下载接口要求文件位于 context.cacheDir 下，故先在缓存目录读写再上传。
 *
 * 未开通云存储 / 初始化失败时 isEnabled() 返回 false，本地备份不受影响。
 */
const OBJECT_PATH: string = 'backup/snapshot.json';
const CACHE_NAME: string = 'carbon_backup_cloud.json';

export class CloudStorageBackupProvider implements CloudBackupProvider {
  private ctx: common.Context | null = null;
  private bucket: cloudStorage.StorageBucket | null = null;
  private enabled: boolean = false;

  init(ctx: common.Context): void {
    this.ctx = ctx;
    try {
      this.bucket = cloudStorage.bucket();
      this.enabled = true;
    } catch (e) {
      this.bucket = null;
      this.enabled = false;
    }
  }

  isEnabled(): boolean {
    return this.enabled && this.bucket !== null && this.ctx !== null;
  }

  async upload(snapshot: string): Promise<boolean> {
    const ctx = this.ctx;
    const bucket = this.bucket;
    if (ctx === null || bucket === null) {
      return false;
    }
    const path: string = ctx.cacheDir + '/' + CACHE_NAME;
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, snapshot);
      fs.closeSync(file);
      const task = await bucket.uploadFile(ctx, { localPath: path, cloudPath: OBJECT_PATH });
      await CloudStorageBackupProvider.waitTask(task);
      return true;
    } catch (e) {
      return false;
    } finally {
      try { fs.unlinkSync(path); } catch (e) { }
    }
  }

  async download(): Promise<string> {
    const ctx = this.ctx;
    const bucket = this.bucket;
    if (ctx === null || bucket === null) {
      return '';
    }
    const path: string = ctx.cacheDir + '/' + CACHE_NAME;
    try {
      const task = await bucket.downloadFile(ctx, { cloudPath: OBJECT_PATH, localPath: path });
      await CloudStorageBackupProvider.waitTask(task);
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      const readLen = fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const bytes = new Uint8Array(buf.slice(0, readLen));
      return util.TextDecoder.create('utf-8').decodeToString(bytes);
    } catch (e) {
      return '';
    } finally {
      try { fs.unlinkSync(path); } catch (e) { }
    }
  }

  // 上传/下载为任务式接口：start() 只启动任务，需等 completed/failed 事件才知结果
  private static waitTask(task: request.agent.Task): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      task.on('completed', () => { resolve(); });
      task.on('failed', () => { reject(new Error('cloud task failed')); });
      task.start((err: Error) => {
        if (err) {
          reject(err);
        }
      });
    });
  }
}
