import { AppColor } from '../common/Constants';
import { HomeTab } from '../view/HomeTab';
import { RecordTab } from '../view/RecordTab';
import { DashboardTab } from '../view/DashboardTab';
import { RewardsTab } from '../view/RewardsTab';
import { KnowledgeTab } from '../view/KnowledgeTab';
import { AppMotion, AppTypography } from '../common/Theme';

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController();
  @State currentIndex: number = 0;
  @State ready: boolean = false;
  // 深浅模式跟随系统：colorMode 变化时重建 Tabs 子树，令全部 AppColor.* 重新求值
  @StorageLink('colorMode') @Watch('onColorMode') colorMode: string = 'dark';
  @State themeKey: number = 0;
  // 背景光斑缓慢漂移（呼吸感），受 reduceMotion 控制
  @State drift: boolean = false;

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 50);
    setTimeout(() => this.drift = true, AppMotion.reduceMotion() ? 0 : 120);
  }

  onColorMode(): void {
    this.themeKey = this.themeKey + 1;
  }

  @Builder
  tabItem(icon: Resource, title: string, index: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .opacity(this.currentIndex === index ? 1 : 0.65)
        .scale({ x: this.currentIndex === index ? 1.1 : 1, y: this.currentIndex === index ? 1.1 : 1 })
        .animation(AppMotion.pressOptions());
      Text(title)
        .fontSize(AppTypography.SMALL.size)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
        .letterSpacing(0.4)
        .fontColor(this.currentIndex === index ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .animation(AppMotion.pressOptions());
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [AppColor.BG_WASH_TOP, 0.0],
            [AppColor.BG_WASH_BOTTOM, 1.0]
          ]
        })

      Column()
        .width(420)
        .height(420)
        .radialGradient({ center: ['50%', '50%'], radius: 200, colors: [[AppColor.BLOB_A, 0.0], [AppColor.BLOB_A_FADE, 1.0]] })
        .position({ x: -120, y: -60 })
        .translate({ x: this.drift ? 26 : -18, y: this.drift ? 20 : -14 })
        .scale({ x: this.drift ? 1.08 : 0.96, y: this.drift ? 1.08 : 0.96 })
        .animation(AppMotion.loopOptions(9000, true))

      Column()
        .width(460)
        .height(460)
        .radialGradient({ center: ['50%', '50%'], radius: 230, colors: [[AppColor.BLOB_B, 0.0], [AppColor.BLOB_B_FADE, 1.0]] })
        .position({ x: 140, y: 360 })
        .translate({ x: this.drift ? -22 : 16, y: this.drift ? -18 : 24 })
        .scale({ x: this.drift ? 0.95 : 1.07, y: this.drift ? 0.95 : 1.07 })
        .animation(AppMotion.loopOptions(11000, true))

      Column()
        .width(360)
        .height(360)
        .radialGradient({ center: ['50%', '50%'], radius: 180, colors: [[AppColor.BLOB_C, 0.0], [AppColor.BLOB_C_FADE, 1.0]] })
        .position({ x: -80, y: 560 })
        .translate({ x: this.drift ? 20 : -14, y: this.drift ? -24 : 12 })
        .scale({ x: this.drift ? 1.1 : 0.94, y: this.drift ? 1.1 : 0.94 })
        .animation(AppMotion.loopOptions(13000, true))

      Column() {
        Blank()
        Column()
          .width('100%')
          .height(170)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              [AppColor.BG_WASH_FADE, 0.0],
              [AppColor.BG_WASH_BOTTOM, 1.0]
            ]
          })
      }
      .width('100%')
      .height('100%')

      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() { HomeTab({ controller: this.controller }) }.tabBar(this.tabItem($r('app.media.ic_nav_home'), '首页', 0))
        TabContent() { RecordTab() }.tabBar(this.tabItem($r('app.media.ic_nav_record'), '记录', 1))
        TabContent() { DashboardTab() }.tabBar(this.tabItem($r('app.media.ic_nav_dashboard'), '看板', 2))
        TabContent() { RewardsTab() }.tabBar(this.tabItem($r('app.media.ic_nav_rewards'), '积分', 3))
        TabContent() { KnowledgeTab() }.tabBar(this.tabItem($r('app.media.ic_nav_knowledge'), '科普', 4))
      }
      .barMode(BarMode.Fixed)
      .barHeight(64)
      .scrollable(false)
      .animationDuration(AppMotion.reduceMotion() ? 0 : 280)
      .backgroundColor(Color.Transparent)
      .id('carbonlife-tabs-' + this.themeKey)
      .onChange((index: number) => { this.currentIndex = index; })
      .opacity(this.ready ? 1 : 0)
      .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColor.BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
