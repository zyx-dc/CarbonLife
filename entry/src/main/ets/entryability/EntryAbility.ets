import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { CarbonStore } from '../model/CarbonStore';
import { FamilyService } from '../model/FamilyService';

const DOMAIN: number = 0x0000;
const TAG: string = 'CarbonLife';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
    // 深浅模式跟随系统：冷启动读取系统 Configuration.colorMode，
    // 运行中切换系统主题由 onConfigurationUpdate 实时跟随。
    const isDark = this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('colorMode', isDark ? 'dark' : 'light');
    AppStorage.setOrCreate('reduceMotion', false);
    hilog.info(DOMAIN, TAG, 'init colorMode=%{public}s', isDark ? 'dark' : 'light');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    windowStage.loadContent('pages/Splash', (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
      // 窗口内容就绪后再申请权限，避免弹窗创建失败（12100009）
      this.requestDistributedPermission().then(() => {
        CarbonStore.get().init(this.context).then(async () => {
          await FamilyService.get().init(this.context);
          FamilyService.get().pushLocal();
          hilog.info(DOMAIN, TAG, 'store ready');
        });
      });
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN, TAG, 'onConfigurationUpdate colorMode=%{public}s', newConfig.colorMode);
    this.applyConfiguration(newConfig);
  }

  private applyConfiguration(config: Configuration): void {
    const isDark = config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('colorMode', isDark ? 'dark' : 'light');
    // 注意：不要在此覆盖 reduceMotion——它由用户在「首页 → 减弱动效」自行控制，
    // 若每次系统配置变化都写回 false，会静默清掉用户的选择。
  }

  /**
   * 运行时申请分布式数据同步权限。
   * - 先查已授权状态，避免重复弹窗；
   * - 在 loadContent 回调之后调用，规避 12100009（弹窗创建失败）；
   * - 模拟器/部分环境不支持该权限的动态申请，系统会直接返回「无需申请」，
   *   此时不视为崩溃，家庭同步功能自动降级（详见 DESIGN.md Known Gaps）。
   */
  private async requestDistributedPermission(): Promise<void> {
    const permission: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const tokenId = this.context.applicationInfo.accessTokenId;
      if (atManager.checkAccessTokenSync(tokenId, permission) ===
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, 'DISTRIBUTED_DATASYNC already granted');
        return;
      }
      const authResults = await atManager.requestPermissionsFromUser(this.context, [permission]);
      const result = authResults.authResults.length > 0 ? authResults.authResults[0] : -1;
      if (result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, 'DISTRIBUTED_DATASYNC granted');
      } else {
        hilog.warn(DOMAIN, TAG,
          'DISTRIBUTED_DATASYNC not granted (result=%{public}d); family sync degrades', result);
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'request permission failed: %{public}s', JSON.stringify(e));
    }
  }
}
