import { AppColor } from '../common/Constants';
import { HomeTab } from '../view/HomeTab';
import { RecordTab } from '../view/RecordTab';
import { DashboardTab } from '../view/DashboardTab';
import { RewardsTab } from '../view/RewardsTab';
import { KnowledgeTab } from '../view/KnowledgeTab';

@Entry
@Component
struct Index {
  private controller: TabsController = new TabsController();
  @State currentIndex: number = 0;

  @Builder
  tabItem(icon: string, title: string, index: number) {
    Column() {
      Text(icon)
        .fontSize(20)
        .opacity(this.currentIndex === index ? 1 : 0.4)
      Text(title)
        .fontSize(11)
        .fontColor(this.currentIndex === index ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .margin({ top: 2 })
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() {
        HomeTab({ controller: this.controller })
      }
      .tabBar(this.tabItem('🏠', '首页', 0))

      TabContent() {
        RecordTab()
      }
      .tabBar(this.tabItem('📝', '记录', 1))

      TabContent() {
        DashboardTab()
      }
      .tabBar(this.tabItem('📊', '看板', 2))

      TabContent() {
        RewardsTab()
      }
      .tabBar(this.tabItem('🏅', '积分', 3))

      TabContent() {
        KnowledgeTab()
      }
      .tabBar(this.tabItem('📚', '科普', 4))
    }
    .barMode(BarMode.Fixed)
    .barHeight(56)
    .scrollable(false)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .backgroundColor(AppColor.BG)
  }
}
