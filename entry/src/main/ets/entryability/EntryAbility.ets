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
    this.applyConfiguration(this.context.config);
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
    // 系统减弱动效接口为 API 23+，当前版本默认 false；
    // 如需读取系统设置，可在高版本设备上通过 accessibility 模块查询并覆盖此值。
    AppStorage.setOrCreate('reduceMotion', false);
  }

  private async requestDistributedPermission(): Promise<void> {
    const permission: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const authResults = await atManager.requestPermissionsFromUser(this.context, [permission]);
      if (authResults.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        hilog.info(DOMAIN, TAG, 'DISTRIBUTED_DATASYNC granted');
      } else {
        hilog.warn(DOMAIN, TAG, 'DISTRIBUTED_DATASYNC denied');
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'request permission failed: %{public}s', JSON.stringify(e));
    }
  }
}
