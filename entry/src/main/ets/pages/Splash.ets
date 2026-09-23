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
  @State pulse: boolean = false;
  @State orbit: number = 0;

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

    // 光晕呼吸 + 卫星环轨：让启动页有「活着」的细节
    this.uiContext.animateTo({ duration: 1600, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
      this.pulse = true;
    });
    this.uiContext.animateTo({ duration: 4200, curve: Curve.Linear, iterations: -1 }, () => {
      this.orbit = 360;
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

        // 呼吸光晕
        Column()
          .width(220)
          .height(220)
          .borderRadius(110)
          .radialGradient({ center: ['50%', '50%'], radius: 110, colors: [['rgba(182,255,46,0.34)', 0.0], ['rgba(182,255,46,0.0)', 1.0]] })
          .scale({ x: this.pulse ? 1.16 : 0.86, y: this.pulse ? 1.16 : 0.86 })
          .opacity(this.pulse ? 0.55 : 1)
          .animation({ duration: 1600, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate })

        // 环轨卫星
        Column() {
          Column()
            .width(7)
            .height(7)
            .borderRadius(4)
            .backgroundColor(AppColor.SIGNAL)
            .shadow({ radius: 8, color: 'rgba(182,255,46,0.9)', offsetX: 0, offsetY: 0 })
        }
        .width(170)
        .height(170)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .rotate({ angle: this.orbit })
        .animation({ duration: 4200, curve: Curve.Linear, iterations: -1 })
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
