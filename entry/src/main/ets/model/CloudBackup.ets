import { cloudStorage } from '@kit.CloudFoundationKit';
import { request, BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CloudBackupProvider } from './BackupService';

/**
 * AGC 云存储备份实现（Cloud Foundation Kit）。
 * - 存储实例：AGC 云开发「云存储」默认实例（本项目：carbonlife-z58pd）
 * - 备份对象：backup/snapshot.json（整包快照，见 CarbonStore.exportSnapshot）
 * - 上传/下载接口要求文件位于 context.cacheDir 下，故先在缓存目录读写再上传。
 *
 * 前置条件（云侧 / 设备侧）：
 * 1. 已在 AGC 开通云存储并存在默认实例；
 * 2. module.json5 已声明 ohos.permission.INTERNET；
 * 3. 已通过 CloudAuth 完成 AGC 登录并 cloudCommon.init(authProvider)——
 *    云存储安全规则为 `if request.auth != null`，缺少用户凭证会返回 403 Authentication failed；
 * 4. 模拟器调试需在 HarmonyOS 开发者中心注册「模拟器调试凭据」，真机需正常签名。
 *
 * 未开通云存储 / 初始化失败时 isEnabled() 返回 false，本地备份不受影响。
 */
const DOMAIN: number = 0x0000;
const TAG: string = 'CloudBackup';
const OBJECT_PATH: string = 'backup/snapshot.json';
const CACHE_NAME: string = 'carbon_backup_cloud.json';

export class CloudStorageBackupProvider implements CloudBackupProvider {
  private static readonly TASK_TIMEOUT_MS: number = 30000;
  private ctx: common.Context | null = null;
  private bucket: cloudStorage.StorageBucket | null = null;
  private enabled: boolean = false;

  init(ctx: common.Context): void {
    this.ctx = ctx;
    try {
      this.bucket = cloudStorage.bucket();
      this.enabled = true;
      hilog.info(DOMAIN, TAG, 'cloud storage bucket ready');
    } catch (e) {
      this.bucket = null;
      this.enabled = false;
      hilog.warn(DOMAIN, TAG, 'cloud storage unavailable: %{public}s', CloudStorageBackupProvider.describe(e));
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
      hilog.info(DOMAIN, TAG, 'cloud upload succeeded');
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'cloud upload failed: %{public}s', CloudStorageBackupProvider.describe(e));
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
      // overwrite: 上次异常退出可能残留同名缓存，默认 false 会直接失败
      const task = await bucket.downloadFile(ctx, { cloudPath: OBJECT_PATH, localPath: path, overwrite: true });
      await CloudStorageBackupProvider.waitTask(task);
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      const readLen = fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const bytes = new Uint8Array(buf.slice(0, readLen));
      return util.TextDecoder.create('utf-8').decodeToString(bytes);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'cloud download failed: %{public}s', CloudStorageBackupProvider.describe(e));
      return '';
    } finally {
      try { fs.unlinkSync(path); } catch (e) { }
    }
  }

  // 上传/下载为任务式接口：start() 只启动任务，需等 completed/failed 事件才知结果；
  // 加超时兜底，避免任务卡住时 Promise 永不结算（UI 会一直「无响应」）。
  private static waitTask(task: request.agent.Task): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      let settled: boolean = false;
      let timeoutId: number = -1;
      // 先声明占位再赋值：避免「在声明前使用 settle」的严格检查
      let settle: (ok: boolean) => void = (): void => {};
      const onCompleted = (): void => { settle(true); };
      const onFailed = (): void => { settle(false); };
      settle = (ok: boolean): void => {
        if (settled) {
          return;
        }
        settled = true;
        if (timeoutId >= 0) {
          clearTimeout(timeoutId);
          timeoutId = -1;
        }
        // 任务对象可能在超时后仍持有回调，主动解绑避免悬挂
        try { task.off('completed', onCompleted); } catch (e) { }
        try { task.off('failed', onFailed); } catch (e) { }
        if (ok) {
          resolve();
        } else {
          reject(new Error('cloud task failed'));
        }
      };
      task.on('completed', onCompleted);
      task.on('failed', onFailed);
      timeoutId = setTimeout(() => settle(false), CloudStorageBackupProvider.TASK_TIMEOUT_MS);
      task.start((err: BusinessError) => {
        if (err) {
          settle(false);
        }
      });
    });
  }

  // 统一把异常/错误码转成可读日志（BusinessError 带 code/message）
  private static describe(e: Object): string {
    const err = e as BusinessError;
    if (err !== null && err !== undefined && err.code !== undefined) {
      const msg = err.message !== undefined ? err.message : '';
      return 'code=' + err.code.toString() + ' message=' + msg;
    }
    if (e instanceof Error) {
      return e.message;
    }
    return JSON.stringify(e);
  }
}
