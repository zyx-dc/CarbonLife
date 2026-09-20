import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { AppColor } from '../common/Constants';
import { BadgeDef, DailyTask } from '../model/CarbonTypes';

@Component
export struct RewardsTab {
  @StorageLink('recordsVersion') version: number = 0;

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('积分与荣誉')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.TEXT)
          .width('100%')

        Column() {
          Text('我的碳积分')
            .fontSize(13)
            .fontColor(AppColor.TEXT_SUB)
          Text(CarbonStore.get().totalPoints().toString())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.ACCENT)
            .margin({ top: 4 })
          Text('累计减排 ' + CarbonStore.get().totalSaved().toFixed(2) + ' kg CO₂e')
            .fontSize(12)
            .fontColor(AppColor.TEXT_SUB)
            .margin({ top: 6 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            Text('🌳 我的植树证书')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.TEXT)
            Blank()
            Text(Rewards.treeCount(CarbonStore.get()).toString() + ' 棵')
              .fontSize(14)
              .fontColor(AppColor.PRIMARY)
          }
          .width('100%')
          Text(Rewards.treeCount(CarbonStore.get()) > 0
            ? '恭喜！你已累计减排 ' + CarbonStore.get().totalSaved().toFixed(2) + ' kg CO₂e，相当于种下 ' +
              Rewards.treeCount(CarbonStore.get()).toString() + ' 棵树。'
            : '每减排 10 kg CO₂e 即可种下 1 棵树，继续加油！')
            .fontSize(12)
            .fontColor(AppColor.TEXT_SUB)
            .margin({ top: 8 })
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

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
              Text(task.name)
                .fontSize(14)
                .fontColor(AppColor.TEXT)
                .layoutWeight(1)
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
          Row() {
            Text('低碳徽章')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.TEXT)
            Blank()
            Text(Rewards.unlockedCount(CarbonStore.get()).toString() + '/' +
              Rewards.BADGES.length.toString())
              .fontSize(13)
              .fontColor(AppColor.TEXT_SUB)
          }
          .width('100%')
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
            ForEach(Rewards.BADGES, (badge: BadgeDef) => {
              Column() {
                Text(badge.icon)
                  .fontSize(30)
                  .opacity(Rewards.isUnlocked(badge, CarbonStore.get()) ? 1 : 0.25)
                Text(badge.name)
                  .fontSize(12)
                  .fontColor(Rewards.isUnlocked(badge, CarbonStore.get()) ? AppColor.TEXT : AppColor.TEXT_SUB)
                  .margin({ top: 6 })
                Text(Rewards.isUnlocked(badge, CarbonStore.get()) ? '已解锁' : badge.desc)
                  .fontSize(9)
                  .fontColor(AppColor.TEXT_SUB)
                  .maxLines(2)
                  .textAlign(TextAlign.Center)
                  .margin({ top: 2 })
              }
              .width('30%')
              .padding({ top: 14, bottom: 14 })
              .margin({ bottom: 12 })
              .backgroundColor(Rewards.isUnlocked(badge, CarbonStore.get()) ? AppColor.BG : AppColor.CARD)
              .borderRadius(12)
              .borderWidth(1)
              .borderColor(AppColor.DIVIDER)
            }, (badge: BadgeDef) => badge.key)
          }
          .width('100%')
          .margin({ top: 12 })
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
    .id('rewards_' + this.version.toString())
  }
}
