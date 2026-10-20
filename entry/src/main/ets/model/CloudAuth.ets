import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cloudCommon } from '@kit.CloudFoundationKit';
import auth, { AuthUser } from '@hw-agconnect/auth';

const DOMAIN: number = 0x0000;
const TAG: string = 'CloudAuth';
const CONFIG_FILE: string = 'agconnect-services.json';

/**
 * AGC 认证服务接入（Cloud Foundation Kit 的前置条件）。
 *
 * 背景：云存储实例的安全规则为 `allow read, write: if request.auth != null;`，
 * 即请求必须携带「已登录用户」的凭证。若未登录 / 未向 cloudCommon 注入 AuthProvider，
 * 云存储接口会直接返回 `1008221001 / 403:Authentication failed`。
 *
 * 做法（官方 AuthProvider「方式一」）：
 * 1. 读取 resources/rawfile/agconnect-services.json，初始化 AGC 认证 SDK；
 * 2. 未登录时执行「游客匿名登录」(signInAnonymously) 获取用户身份；
 * 3. 通过 auth.getAuthProvider() 拿到 AuthProvider 并注入 cloudCommon.init()。
 *
 * 之后 cloudStorage.bucket() 等云存储调用才会带上用户凭证。
 * 任何一步失败都返回 false，云备份功能自动降级（本地备份不受影响）。
 */
export class CloudAuth {
  private static sdkInited: boolean = false;
  private static pending: Promise<boolean> | null = null;

  /** 确保已完成登录 + cloudCommon 初始化；可重复调用（结果缓存）。 */
  static ensure(context: common.Context): Promise<boolean> {
    if (CloudAuth.pending === null) {
      CloudAuth.pending = CloudAuth.doEnsure(context);
    }
    return CloudAuth.pending;
  }

  private static async doEnsure(context: common.Context): Promise<boolean> {
    try {
      if (!CloudAuth.sdkInited) {
        const bytes: Uint8Array = context.resourceManager.getRawFileContentSync(CONFIG_FILE);
        const json: string = buffer.from(bytes.buffer).toString('utf8');
        auth.init(context, json);
        CloudAuth.sdkInited = true;
        hilog.info(DOMAIN, TAG, 'auth sdk init ok');
      }

      // 注：AGC SDK 的 .d.ets 被混淆过，lint 无法识别其返回 Promise，
      // 这里用 Promise.resolve 兜底，运行时与 await 行为一致。
      let user: AuthUser | null = await Promise.resolve(auth.getCurrentUser());
      if (user === null) {
        const result = await Promise.resolve(auth.signInAnonymously());
        user = result.getUser();
        hilog.info(DOMAIN, TAG, 'anonymous sign-in ok');
      } else {
        hilog.info(DOMAIN, TAG, 'reuse existing sign-in');
      }

      const authProvider: cloudCommon.AuthProvider = auth.getAuthProvider();
      cloudCommon.init({
        region: cloudCommon.CloudRegion.CHINA,
        authProvider: authProvider
      });

      hilog.info(DOMAIN, TAG, 'cloud auth ready uid=%{public}s', user.getUid());
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'cloud auth failed: %{public}s', JSON.stringify(e));
      return false;
    }
  }
}
