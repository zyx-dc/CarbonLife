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

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 50);
  }

  @Builder
  tabItem(icon: Resource, title: string, index: number) {
    Column({ space: 2 }) {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .opacity(this.currentIndex === index ? 1 : 0.7)
        .scale({ x: this.currentIndex === index ? 1.08 : 1, y: this.currentIndex === index ? 1.08 : 1 })
        .animation(AppMotion.pressOptions());
      Text(title)
        .fontSize(AppTypography.SMALL.size)
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(this.currentIndex === index ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .animation(AppMotion.pressOptions());
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
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
      .backgroundColor(AppColor.CARD)
      .onChange((index: number) => { this.currentIndex = index; })
      .opacity(this.ready ? 1 : 0)
      .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColor.BG);
  }
}
