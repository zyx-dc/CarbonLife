import { PromptAction, UIContext } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { MallService, redeemIcon, RedeemResult } from '../model/MallService';
import { AppColor } from '../common/Constants';
import { BadgeDef, DailyTask, RedeemItem, RedemptionRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { AppCard } from '../components/AppCard';
import { BadgeItem } from '../components/Badge';
import { AnimatedNumber } from '../components/AnimatedNumber';
import { TaskCard } from '../components/TaskCard';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppShadow, AppSpacing, AppTypography } from '../common/Theme';
import { mallNameRes, mallDescRes } from '../common/Localize';

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
    // 结算今日任务奖励（幂等），保证积分页与首页一致
    Rewards.syncTaskRewards(store);
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
    MallService.redeem(item).then((res: RedeemResult) => {
      if (res.ok) {
        this.refresh();
        this.promptAction.showToast({ message: $r('app.string.rewards_redeem_success', res.code) });
      } else {
        this.promptAction.showToast({ message: res.message });
      }
    });
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Column({ space: AppSpacing.XS }) {
          Text('REWARDS').fontSize(AppTypography.SMALL.size).letterSpacing(2.5).fontColor(AppColor.TEXT_SUB);
          Text($r('app.string.rewards_title')).fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        Column({ space: AppSpacing.SM }) {
          Text($r('app.string.rewards_balance')).fontSize(AppTypography.CAPTION.size).letterSpacing(1.5).fontColor(AppColor.TEXT_SUB);
          AnimatedNumber({ value: this.balance, textSize: AppTypography.DISPLAY_LG.size, textColor: AppColor.ACCENT });
          Row({ space: AppSpacing.LG }) {
            Text($r('app.string.rewards_total_earned', this.totalPoints.toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
            Text($r('app.string.rewards_spent', this.spentPoints.toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.margin({ top: AppSpacing.XS });
        }
        .width('100%')
        .padding(AppSpacing.LG)
        .borderRadius(AppRadius.LG)
        .backgroundColor(AppColor.GLASS_STRONG)
        .backdropBlur(24)
        .borderWidth(1)
        .borderColor(AppColor.GLASS_BORDER)
        .shadow(AppShadow.soft())
        .alignItems(HorizontalAlign.Center)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation(AppMotion.enterOptions());

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 2 }) {
          Row() {
            Column() {
              Row({ space: AppSpacing.XS }) {
                Image($r('app.media.ic_tree')).width(22).height(22).fillColor(AppColor.TEXT_SUB);
                Text($r('app.string.rewards_tree_cert')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              }.width('100%');
              Text(this.treeCount > 0
                ? $r('app.string.rewards_tree_congrats', this.totalSaved, this.treeCount.toString())
                : $r('app.string.rewards_tree_hint'))
                .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.XS }).width('100%');
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            Text($r('app.string.rewards_tree_count', this.treeCount.toString())).fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.ACCENT);
          }.width('100%').alignItems(VerticalAlign.Top);
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 3 }) {
          Column({ space: AppSpacing.SM }) {
            Row() {
              Text($r('app.string.rewards_mall_title')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              Blank();
            }.width('100%');
            ForEach(MallService.ITEMS, (item: RedeemItem, index: number) => {
              Row({ space: AppSpacing.SM }) {
                Image(redeemIcon(item.id))
                  .width(28)
                  .height(28)
                  .fillColor(AppColor.TEXT_SUB);
                Column({ space: AppSpacing.XXS }) {
                  Text(mallNameRes(item.id, item.name)).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text(mallDescRes(item.id, item.desc)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Text(this.balance >= item.cost ? $r('app.string.rewards_redeem') : $r('app.string.rewards_redeem_gap', (item.cost - this.balance).toString()))
                  .height(44).fontSize(AppTypography.CAPTION.size).fontWeight(FontWeight.Medium)
                  .textAlign(TextAlign.Center)
                  .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
                  .backgroundColor(this.balance >= item.cost ? AppColor.SIGNAL : AppColor.ELEVATED)
                  .borderWidth(this.balance >= item.cost ? 0 : 1)
                  .borderColor(AppColor.BORDER)
                  .fontColor(this.balance >= item.cost ? AppColor.ON_SIGNAL : AppColor.TEXT_SUB)
                  .borderRadius(AppRadius.SM)
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
              Text($r('app.string.rewards_redemptions')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
              ForEach(this.redemptions, (r: RedemptionRecord) => {
                Row() {
                  Text(mallNameRes(r.itemId, r.itemName)).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT).layoutWeight(1);
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
              Text($r('app.string.rewards_tasks')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
              Blank();
            }.width('100%');
            ForEach(Rewards.TASKS, (task: DailyTask, index: number) => {
              TaskCard({ task: task, done: this.taskStates[index] ?? false, index: index });
            }, (task: DailyTask) => task.key);
          }
        }

        AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 6, marginBottom: AppSpacing.LG }) {
          Column({ space: AppSpacing.SM }) {
            Row() {
              Text($r('app.string.rewards_badges')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT);
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
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 120 })
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);
  }
}
