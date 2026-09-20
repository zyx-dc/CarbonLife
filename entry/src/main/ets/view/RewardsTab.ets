import { promptAction } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { MallService, RedeemResult } from '../model/MallService';
import { AppColor } from '../common/Constants';
import { BadgeDef, DailyTask, RedeemItem, RedemptionRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';

@Component
export struct RewardsTab {
  @StorageLink('recordsVersion') version: number = 0;

  onRedeem(item: RedeemItem): void {
    const res: RedeemResult = MallService.redeem(item);
    if (res.ok) {
      promptAction.showToast({ message: '兑换成功，兑换码 ' + res.code });
    } else {
      promptAction.showToast({ message: res.message });
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('积分与荣誉')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.TEXT)
          .width('100%')

        Column() {
          Text('可用碳积分')
            .fontSize(13)
            .fontColor(AppColor.TEXT_SUB)
          Text(CarbonStore.get().pointsBalance().toString())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.ACCENT)
            .margin({ top: 4 })
          Row() {
            Text('累计获得 ' + CarbonStore.get().totalPoints().toString())
              .fontSize(12)
              .fontColor(AppColor.TEXT_SUB)
            Text('已兑换 ' + CarbonStore.get().spentPoints().toString())
              .fontSize(12)
              .fontColor(AppColor.TEXT_SUB)
              .margin({ left: 16 })
          }
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
          Row() {
            Text('碳普惠权益商城')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.TEXT)
            Blank()
            Text('模拟城市碳普惠接口')
              .fontSize(10)
              .fontColor(AppColor.TEXT_SUB)
          }
          .width('100%')
          ForEach(MallService.ITEMS, (item: RedeemItem) => {
            Row() {
              Text(item.icon)
                .fontSize(26)
              Column() {
                Text(item.name)
                  .fontSize(14)
                  .fontColor(AppColor.TEXT)
                Text(item.desc)
                  .fontSize(11)
                  .fontColor(AppColor.TEXT_SUB)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              Button(CarbonStore.get().pointsBalance() >= item.cost ? '兑换' : item.cost.toString() + '分')
                .height(32)
                .fontSize(12)
                .backgroundColor(CarbonStore.get().pointsBalance() >= item.cost ? AppColor.PRIMARY : AppColor.DIVIDER)
                .fontColor(Color.White)
                .onClick(() => {
                  this.onRedeem(item);
                })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (item: RedeemItem) => item.id)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        if (CarbonStore.get().getRedemptions().length > 0) {
          Column() {
            Text('兑换记录')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColor.TEXT)
              .width('100%')
            ForEach(CarbonStore.get().getRedemptions(), (r: RedemptionRecord) => {
              Row() {
                Text(r.itemName)
                  .fontSize(13)
                  .fontColor(AppColor.TEXT)
                  .layoutWeight(1)
                Text('-' + r.cost.toString())
                  .fontSize(13)
                  .fontColor(AppColor.DANGER)
                Text(DateUtil.formatTime(r.timestamp))
                  .fontSize(11)
                  .fontColor(AppColor.TEXT_SUB)
                  .margin({ left: 10 })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }, (r: RedemptionRecord) => r.id)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppColor.CARD)
          .borderRadius(16)
        }

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
