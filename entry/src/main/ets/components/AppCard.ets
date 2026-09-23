import { AppColor } from '../common/Constants';
import { AppMotion, AppRadius, AppShadow, AppSpacing } from '../common/Theme';

@Component
export struct AppCard {
  @Prop cardPadding: number = AppSpacing.MD;
  @Prop cardRadius: number = AppRadius.XXL;
  @Prop showShadow: boolean = true;
  @Prop showBorder: boolean = true;
  @Prop enter: boolean = true;
  @Prop enterDelayIndex: number = 0;
  @Prop enterTranslateY: number = 20;
  @Prop marginBottom: number = 0;
  @Builder placeholder() {}
  @BuilderParam content: () => void = this.placeholder;

  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .padding(this.cardPadding)
    .backgroundColor(AppColor.GLASS)
    .backdropBlur(24)
    .borderRadius(this.cardRadius)
    .borderWidth(this.showBorder ? 1 : 0)
    .borderColor(AppColor.GLASS_BORDER)
    .shadow(this.showShadow ? AppShadow.soft() : { radius: 0, color: '#00000000' })
    .opacity(this.enter ? 1 : 0)
    .translate({ y: this.enter ? 0 : this.enterTranslateY })
    .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(this.enterDelayIndex) })
    .margin({ bottom: this.marginBottom });
  }
}
