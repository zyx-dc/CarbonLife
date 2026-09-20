import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { AppColor } from '../common/Constants';
import { DailyTask } from '../model/CarbonTypes';

@Component
export struct HomeTab {
  controller: TabsController = new TabsController();
  @StorageLink('recordsVersion') version: number = 0;
  @State showShare: boolean = false;

  @Builder
  statBlock(title: string, value: string, unit: string, color: string) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(unit)
        .fontSize(11)
        .fontColor(AppColor.TEXT_SUB)
      Text(title)
        .fontSize(12)
        .fontColor(AppColor.TEXT_SUB)
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  shareText(): string {
    const store = CarbonStore.get();
    return '我在「碳足迹」App 已累计减排 ' + store.totalSaved().toFixed(2) +
      ' kg CO₂e，获得 ' + store.totalPoints().toString() + ' 积分，种下 ' +
      Rewards.treeCount(store).toString() + ' 棵树。一起加入低碳生活吧！';
  }

  @Builder
  shareSheet() {
    Column({ space: 16 }) {
      Text('我的减排成果')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColor.TEXT)
      Column({ space: 10 }) {
        Text('🌍 碳足迹 · 低碳生活')
          .fontSize(14)
          .fontColor(AppColor.PRIMARY)
        Text(CarbonStore.get().totalSaved().toFixed(2) + ' kg')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.PRIMARY)
        Text('累计减排 CO₂e')
          .fontSize(12)
          .fontColor(AppColor.TEXT_SUB)
        Divider().color(AppColor.DIVIDER).margin({ top: 6, bottom: 6 })
        Row() {
          Column() {
            Text(CarbonStore.get().totalPoints().toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.ACCENT)
            Text('积分')
              .fontSize(11)
              .fontColor(AppColor.TEXT_SUB)
          }
          .layoutWeight(1)
          Column() {
            Text(Rewards.treeCount(CarbonStore.get()).toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.PRIMARY_LIGHT)
            Text('种树')
              .fontSize(11)
              .fontColor(AppColor.TEXT_SUB)
          }
          .layoutWeight(1)
          Column() {
            Text(CarbonStore.get().totalCount().toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.CHART_BLUE)
            Text('记录')
              .fontSize(11)
              .fontColor(AppColor.TEXT_SUB)
          }
          .layoutWeight(1)
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor(AppColor.BG)
      .borderRadius(16)
      .alignItems(HorizontalAlign.Center)

      Button('复制分享文案')
        .width('100%')
        .height(44)
        .backgroundColor(AppColor.PRIMARY)
        .fontColor(Color.White)
        .onClick(() => {
          const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareText());
          pasteboard.getSystemPasteboard().setData(data).then(() => {
            promptAction.showToast({ message: '分享文案已复制' });
            this.showShare = false;
          });
        })
      Button('关闭')
        .width('100%')
        .height(44)
        .backgroundColor(AppColor.CARD)
        .fontColor(AppColor.TEXT_SUB)
        .borderWidth(1)
        .borderColor(AppColor.DIVIDER)
        .onClick(() => {
          this.showShare = false;
        })
    }
    .width('100%')
    .padding(20)
  }

  build() {
    Stack() {
      Scroll() {
      Column({ space: 14 }) {
        Column() {
          Text('低碳生活 · 从我做起')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
          Text('记录每一次低碳行动，积少成多守护地球')
            .fontSize(12)
            .fontColor(AppColor.TEXT_SUB)
            .margin({ top: 6 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column() {
          Row() {
            this.statBlock('今日减排', CarbonStore.get().todaySaved().toFixed(2), 'kg CO₂e', AppColor.PRIMARY)
            Divider().vertical(true).height(40).color(AppColor.DIVIDER)
            this.statBlock('今日积分', CarbonStore.get().totalPoints().toString(), '分', AppColor.ACCENT)
          }
          .width('100%')

          Divider().color(AppColor.DIVIDER).margin({ top: 14, bottom: 14 })

          Row() {
            this.statBlock('累计减排', CarbonStore.get().totalSaved().toFixed(2), 'kg CO₂e', AppColor.CHART_BLUE)
            Divider().vertical(true).height(40).color(AppColor.DIVIDER)
            this.statBlock('累计种树', Rewards.treeCount(CarbonStore.get()).toString(), '棵', AppColor.PRIMARY_LIGHT)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Row({ space: 12 }) {
          Button('去记录低碳行为')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(AppColor.PRIMARY)
            .fontColor(Color.White)
            .onClick(() => {
              this.controller.changeIndex(1);
            })
          Button('生成成果卡片')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(AppColor.CARD)
            .fontColor(AppColor.PRIMARY)
            .borderWidth(1)
            .borderColor(AppColor.PRIMARY)
            .onClick(() => {
              this.showShare = true;
            })
        }
        .width('100%')

        Column() {
          Text('今日任务')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          ForEach(Rewards.TASKS, (task: DailyTask) => {
            Row() {
              Text(Rewards.taskDone(task.key, CarbonStore.get()) ? '✅' : '⬜')
                .fontSize(16)
              Column() {
                Text(task.name)
                  .fontSize(14)
                  .fontColor(AppColor.TEXT)
                Text(task.desc)
                  .fontSize(11)
                  .fontColor(AppColor.TEXT_SUB)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 8 })
              Text('+' + task.points.toString())
                .fontSize(13)
                .fontColor(AppColor.ACCENT)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (task: DailyTask) => task.key)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('智能低碳建议')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          ForEach(Rewards.suggestions(CarbonStore.get()), (tip: string, index: number) => {
            Row() {
              Text('💡')
                .fontSize(14)
              Text(tip)
                .fontSize(13)
                .fontColor(AppColor.TEXT_SUB)
                .layoutWeight(1)
                .margin({ left: 6 })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          }, (tip: string, index: number) => index.toString())
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)
        .margin({ bottom: 16 })
      }
      .width('100%')
      .padding(16)
    }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColor.BG)
      .scrollBar(BarState.Off)

      if (this.showShare) {
        Column() {
          Column() {
            this.shareSheet()
          }
          .width('88%')
          .backgroundColor(AppColor.CARD)
          .borderRadius(20)
          .onClick(() => {
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.45)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showShare = false;
        })
      }
    }
    .width('100%')
    .height('100%')
    .id('home_' + this.version.toString())
  }
}
