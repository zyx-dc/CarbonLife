import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { CarbonStore } from '../model/CarbonStore';
import { FamilyService } from '../model/FamilyService';
import { BackupService } from '../model/BackupService';
import { CloudStorageBackupProvider } from '../model/CloudBackup';

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
      // 沉浸式：内容铺满状态栏/导航栏，消除系统底条的突兀色带
      this.applyImmersiveBars(windowStage);
      // 窗口内容就绪后再申请权限，避免弹窗创建失败（12100009）
      this.requestDistributedPermission().then(() => {
        CarbonStore.get().init(this.context).then(async () => {
          await FamilyService.get().init(this.context);
          FamilyService.get().pushLocal();
          // 注入云备份实现（AGC 云存储）；未开通/初始化失败时 isEnabled() 为 false
          const cloud = new CloudStorageBackupProvider();
          cloud.init(this.context);
          BackupService.setCloudProvider(cloud);
          hilog.info(DOMAIN, TAG, 'store ready; cloud backup enabled=%{public}s', cloud.isEnabled() ? 'true' : 'false');
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
    // 同步系统栏图标颜色，保证深/浅色下都清晰
    this.updateBarContentColor(isDark);
    // 注意：不要在此覆盖 reduceMotion——它由用户在「首页 → 减弱动效」自行控制，
    // 若每次系统配置变化都写回 false，会静默清掉用户的选择。
  }

  /** 沉浸式：布局全屏并把状态栏/导航栏设为透明，让应用背景渐变铺满安全区。 */
  private applyImmersiveBars(windowStage: window.WindowStage): void {
    try {
      const win = windowStage.getMainWindowSync();
      win.setWindowLayoutFullScreen(true).then(() => {
        try {
          // 全屏后读取状态栏高度，供页面顶部内缩（背景铺满、内容避开状态栏）
          const area = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
          AppStorage.setOrCreate('statusBarPx', area.topRect.height);
        } catch (e) {
          hilog.warn(DOMAIN, TAG, 'getWindowAvoidArea failed: %{public}s', JSON.stringify(e));
        }
      }).catch((e: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', JSON.stringify(e));
      });
      const isDark = this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      const content: string = isDark ? '#FFFFFF' : '#1A1C18';
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: content,
        navigationBarContentColor: content
      }).catch((e: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'setWindowSystemBarProperties failed: %{public}s', JSON.stringify(e));
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'immersive bars setup failed: %{public}s', JSON.stringify(e));
    }
  }

  private updateBarContentColor(isDark: boolean): void {
    try {
      const win = window.getLastWindow(this.context);
      const run = (w: window.Window): void => {
        const content: string = isDark ? '#FFFFFF' : '#1A1C18';
        w.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: content,
          navigationBarContentColor: content
        }).catch((e: BusinessError) => {
          hilog.warn(DOMAIN, TAG, 'update bar color failed: %{public}s', JSON.stringify(e));
        });
      };
      win.then(run).catch((e: BusinessError) => {
        hilog.warn(DOMAIN, TAG, 'getLastWindow failed: %{public}s', JSON.stringify(e));
      });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'updateBarContentColor failed: %{public}s', JSON.stringify(e));
    }
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
