import { display } from '@kit.ArkUI';
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
  // 克制的切 Tab 过渡：仅内容区淡入（导航栏不动）
  @State contentFade: boolean = true;
  @State ready: boolean = false;
  // 深浅模式跟随系统：colorMode 变化时重建 Tabs 子树，令全部 AppColor.* 重新求值
  @StorageLink('colorMode') @Watch('onColorMode') colorMode: string = 'dark';
  @State themeKey: number = 0;
  // 背景光斑缓慢漂移（呼吸感），受 reduceMotion 控制
  @State drift: boolean = false;
  // 宽屏断点（平板/折叠/大屏）：宽度 ≥840vp 启用左侧导航 + 多列内容
  @StorageLink('isWide') isWide: boolean = false;
  // 沉浸式下状态栏高度（px），用于把内容顶部内缩，避免被状态栏遮挡
  @StorageLink('statusBarPx') statusBarPx: number = 0;

  private topInsetVp(): number {
    return this.statusBarPx > 0 ? px2vp(this.statusBarPx) : 0;
  }

  // 用 display 的物理宽换算 vp 判断宽屏；比 mediaquery 的字符串条件更可靠
  private computeWide(): boolean {
    try {
      const d = display.getDefaultDisplaySync();
      return px2vp(d.width) >= 840;
    } catch (e) {
      return false;
    }
  }

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 50);
    setTimeout(() => this.drift = true, AppMotion.reduceMotion() ? 0 : 120);
    this.isWide = this.computeWide();
  }

  onColorMode(): void {
    this.themeKey = this.themeKey + 1;
  }

  @Builder
  tabItem(icon: Resource, title: ResourceStr, index: number) {
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

      Tabs({ barPosition: this.isWide ? BarPosition.Start : BarPosition.End, controller: this.controller }) {
        TabContent() { Column() { HomeTab({ controller: this.controller }) }.width('100%').height('100%').opacity(this.contentFade ? 1 : 0).animation({ duration: AppMotion.reduceMotion() ? 0 : 180, curve: Curve.EaseOut }) }.tabBar(this.tabItem($r('app.media.ic_nav_home'), $r('app.string.tab_home'), 0))
        TabContent() { Column() { RecordTab({ controller: this.controller }) }.width('100%').height('100%').opacity(this.contentFade ? 1 : 0).animation({ duration: AppMotion.reduceMotion() ? 0 : 180, curve: Curve.EaseOut }) }.tabBar(this.tabItem($r('app.media.ic_nav_record'), $r('app.string.tab_record'), 1))
        TabContent() { Column() { DashboardTab() }.width('100%').height('100%').opacity(this.contentFade ? 1 : 0).animation({ duration: AppMotion.reduceMotion() ? 0 : 180, curve: Curve.EaseOut }) }.tabBar(this.tabItem($r('app.media.ic_nav_dashboard'), $r('app.string.tab_dashboard'), 2))
        TabContent() { Column() { RewardsTab() }.width('100%').height('100%').opacity(this.contentFade ? 1 : 0).animation({ duration: AppMotion.reduceMotion() ? 0 : 180, curve: Curve.EaseOut }) }.tabBar(this.tabItem($r('app.media.ic_nav_rewards'), $r('app.string.tab_rewards'), 3))
        TabContent() { Column() { KnowledgeTab() }.width('100%').height('100%').opacity(this.contentFade ? 1 : 0).animation({ duration: AppMotion.reduceMotion() ? 0 : 180, curve: Curve.EaseOut }) }.tabBar(this.tabItem($r('app.media.ic_nav_knowledge'), $r('app.string.tab_knowledge'), 4))
      }
      .vertical(this.isWide)
      .barMode(BarMode.Fixed)
      .barWidth(this.isWide ? 88 : '100%')
      .barHeight(this.isWide ? '100%' : 64)
      .padding({ top: this.topInsetVp() })
      .barBackgroundColor(AppColor.GLASS_STRONG)
      .divider({ strokeWidth: 1, color: AppColor.DIVIDER, startMargin: 0, endMargin: 0 })
      .scrollable(false)
      .animationDuration(AppMotion.reduceMotion() ? 0 : 280)
      .backgroundColor(Color.Transparent)
      .id('carbonlife-tabs-' + this.themeKey)
      .onChange((index: number) => {
        this.currentIndex = index;
        // 内容区快速淡入（不上移），保留即时切换的手感
        this.contentFade = false;
        setTimeout(() => { this.contentFade = true; }, 16);
      })
      .opacity(this.ready ? 1 : 0)
      .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColor.BG_WASH_TOP)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
