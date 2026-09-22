import { PromptAction, UIContext } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { MallService, redeemIcon, RedeemResult } from '../model/MallService';
import { AppColor } from '../common/Constants';
import { BadgeDef, DailyTask, RedeemItem, RedemptionRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { AppCard } from '../components/AppCard';
import { BadgeItem } from '../components/Badge';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct RewardsTab {
  @StorageLink('recordsVersion') version: number = 0;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private onChange: () => void = () => { this.refresh(); };
  @State ready: boolean = false;

  @State balance: number = 0;
  @State totalPoints: number = 0;
  @State spentPoints: number = 0;
  @State totalSaved: string = '0.00';
  @State treeCount: number = 0;
  @State redemptions: RedemptionRecord[] = [];
  @State taskStates: boolean[] = [];
  @State badgeUnlocked: boolean[] = [];
  @State unlockedCount: number = 0;

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onChange);
    this.refresh();
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
  }

  aboutToDisappear(): void {
    CarbonStore.get().removeChangeListener(this.onChange);
  }

  refresh(): void {
    const store = CarbonStore.get();
    this.balance = store.pointsBalance();
    this.totalPoints = store.totalPoints();
    this.spentPoints = store.spentPoints();
    this.totalSaved = store.totalSaved().toFixed(2);
    this.treeCount = Rewards.treeCount(store);
    this.redemptions = store.getRedemptions();
    this.taskStates = Rewards.TASKS.map((t: DailyTask) => Rewards.taskDone(t.key, store));
    this.badgeUnlocked = Rewards.BADGES.map((b: BadgeDef) => Rewards.isUnlocked(b, store));
    this.unlockedCount = this.badgeUnlocked.filter((v: boolean) => v).length;
  }

  onRedeem(item: RedeemItem): void {
    const res: RedeemResult = MallService.redeem(item);
    if (res.ok) {
      this.refresh();
      this.promptAction.showToast({ message: '兑换成功，兑换码 ' + res.code });
    } else {
      this.promptAction.showToast({ message: res.message });
    }
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('积分与荣誉').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%')
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        AppCard({ cardPadding: AppSpacing.LG, enter: this.ready, enterDelayIndex: 1 }) {
          Column({ space: AppSpacing.XS }) {
            Text('可用碳积分').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
            Text(this.balance.toString()).fontSize(48).fontWeight(FontWeight.Bold).fontColor(AppColor.ACCENT);
            Row() {
              Text('累计获得 ' + this.totalPoints.toString()).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
              Text('已兑换 ' + this.spentPoints.toString()).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).margin({ left: AppSpacing.MD });
            }.margin({ top: AppSpacing.XS });
          }.width('100%').alignItems(HorizontalAlign.Center);
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 2 }) {
          Row() {
            Column() {
              Row({ space: AppSpacing.XS }) {
                Image($r('app.media.ic_tree')).width(22).height(22).fillColor(AppColor.PRIMARY);
                Text('我的植树证书').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              }.width('100%');
              Text(this.treeCount > 0
                ? '恭喜！你已累计减排 ' + this.totalSaved + ' kg CO₂e，相当于种下 ' + this.treeCount.toString() + ' 棵树。'
                : '每减排 10 kg CO₂e 即可种下 1 棵树，继续加油！')
                .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.XS }).width('100%');
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            Blank();
            Text(this.treeCount.toString() + ' 棵').fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.PRIMARY);
          }.width('100%');
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 3 }) {
          Column({ space: AppSpacing.SM }) {
            Row() {
              Text('碳普惠权益商城').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              Blank();
              Text('模拟城市碳普惠接口').fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
            }.width('100%');
            ForEach(MallService.ITEMS, (item: RedeemItem, index: number) => {
              Row({ space: AppSpacing.SM }) {
                Image(redeemIcon(item.id))
                  .width(28)
                  .height(28)
                  .fillColor(AppColor.PRIMARY);
                Column({ space: AppSpacing.XXS }) {
                  Text(item.name).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text(item.desc).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Button(this.balance >= item.cost ? '兑换' : item.cost.toString() + '分')
                  .height(32).fontSize(AppTypography.CAPTION.size)
                  .backgroundColor(this.balance >= item.cost ? AppColor.PRIMARY : AppColor.DIVIDER)
                  .fontColor(AppColor.TEXT_INVERSE)
                  .onClick(() => this.onRedeem(item));
              }
              .width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 16 })
              .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(index) });
            }, (item: RedeemItem) => item.id);
          }
        }

        if (this.redemptions.length > 0) {
          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 4 }) {
            Column({ space: AppSpacing.SM }) {
              Text('兑换记录').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
              ForEach(this.redemptions, (r: RedemptionRecord) => {
                Row() {
                  Text(r.itemName).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT).layoutWeight(1);
                  Text('-' + r.cost.toString()).fontSize(AppTypography.BODY.size).fontColor(AppColor.DANGER);
                  Text(DateUtil.formatTime(r.timestamp)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).margin({ left: AppSpacing.SM });
                }.width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM });
              }, (r: RedemptionRecord) => r.id);
            }
          }
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 5 }) {
          Column({ space: AppSpacing.SM }) {
            Row() {
              Text('今日任务').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              Blank();
            }.width('100%');
            ForEach(Rewards.TASKS, (task: DailyTask, index: number) => {
              Row({ space: AppSpacing.SM }) {
                Text(this.taskStates[index] ?? false ? '✓' : '').width(22).height(22).fontSize(14).fontColor(AppColor.TEXT_INVERSE)
                  .textAlign(TextAlign.Center).backgroundColor((this.taskStates[index] ?? false) ? AppColor.SUCCESS : 'transparent')
                  .borderRadius(AppRadius.FULL).borderWidth((this.taskStates[index] ?? false) ? 0 : 1).borderColor(AppColor.BORDER);
                Column({ space: AppSpacing.XXS }) {
                  Text(task.name).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor((this.taskStates[index] ?? false) ? AppColor.TEXT_SUB : AppColor.TEXT);
                  Text(task.desc).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Text('+' + task.points.toString()).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(FontWeight.Bold).fontColor((this.taskStates[index] ?? false) ? AppColor.TEXT_SUB : AppColor.ACCENT);
              }
              .width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 16 })
              .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(index) });
            }, (task: DailyTask) => task.key);
          }
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 6, marginBottom: AppSpacing.LG }) {
          Column({ space: AppSpacing.SM }) {
            Row() {
              Text('低碳徽章').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              Blank();
              Text(this.unlockedCount.toString() + '/' + Rewards.BADGES.length.toString()).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
            }.width('100%');
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(Rewards.BADGES, (badge: BadgeDef, index: number) => {
                BadgeItem({ badge: badge, unlocked: this.badgeUnlocked[index] ?? false, index: index });
              }, (badge: BadgeDef) => badge.key);
            }.width('100%').margin({ top: AppSpacing.SM });
          }
        }
      }
      .width('100%').padding(AppSpacing.MD)
    }
    .width('100%').height('100%').backgroundColor(AppColor.BG).scrollBar(BarState.Off);
  }
}
