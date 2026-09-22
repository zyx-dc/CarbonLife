import { UIContext } from '@kit.ArkUI';
import { AppColor } from '../common/Constants';
import { AppMotion, AppSpacing, AppTypography, ThemeTokens } from '../common/Theme';

@Entry
@Component
struct Splash {
  @StorageLink('reduceMotion') reduceMotion: boolean = false;
  @State logoScale: number = 0.9;
  @State logoOpacity: number = 0;
  @State taglineOpacity: number = 0;
  @State shimmerX: number = -160;

  private uiContext: UIContext = this.getUIContext();

  aboutToAppear(): void {
    if (this.reduceMotion) {
      this.logoScale = 1;
      this.logoOpacity = 1;
      this.taglineOpacity = 1;
      setTimeout(() => this.goHome(), 800);
      return;
    }

    this.uiContext.animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
      this.logoOpacity = 1;
      this.logoScale = 1;
    });

    this.uiContext.animateTo({ duration: 400, delay: 300, curve: Curve.EaseOut }, () => {
      this.taglineOpacity = 1;
    });

    this.uiContext.animateTo({ duration: 1500, curve: Curve.Linear, iterations: -1 }, () => {
      this.shimmerX = 500;
    });

    setTimeout(() => this.goHome(), 1800);
  }

  goHome(): void {
    this.uiContext.getRouter().replaceUrl({ url: 'pages/Index' });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [ThemeTokens.FOREST, 0.0],
            [ThemeTokens.FOREST_LIGHT, 0.6],
            [ThemeTokens.BG_LIGHT, 1.0]
          ]
        })

      if (!this.reduceMotion) {
        Column()
          .width(120)
          .height('100%')
          .backgroundColor('rgba(255,255,255,0.10)')
          .blur(20)
          .rotate({ angle: 12 })
          .translate({ x: this.shimmerX })
          .opacity(0.6)
          .animation({ duration: 1500, curve: Curve.Linear, iterations: -1 })
      }

      Column({ space: AppSpacing.MD }) {
        Image($r('app.media.ic_leaf'))
          .width(72)
          .height(72)
          .fillColor('rgba(255,255,255,0.95)')
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE })

        Text('CarbonLife')
          .fontSize(AppTypography.H1.size)
          .fontWeight(AppTypography.H1.weight)
          .fontColor('#FFFFFF')
          .opacity(this.logoOpacity)
          .scale({ x: this.logoScale, y: this.logoScale })
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE })

        Text('全民绿色生活 · 碳积分与减排指南')
          .fontSize(AppTypography.BODY.size)
          .fontColor('rgba(255,255,255,0.90)')
          .opacity(this.taglineOpacity)
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE, delay: 300 })
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
