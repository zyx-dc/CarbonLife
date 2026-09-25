import { PromptAction, UIContext } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { AppColor } from '../common/Constants';
import { DailyTask } from '../model/CarbonTypes';
import { FamilyService, MemberData } from '../model/FamilyService';
import { ReminderService } from '../model/ReminderService';
import { AppButton } from '../components/AppButton';
import { AppCard } from '../components/AppCard';
import { AnimatedNumber } from '../components/AnimatedNumber';
import { TaskCard } from '../components/TaskCard';
import { AppMotion, AppRadius, AppShadow, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct HomeTab {
  controller: TabsController = new TabsController();
  @StorageLink('recordsVersion') version: number = 0;
  @StorageLink('familyVersion') familyVersion: number = 0;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  private onChange: () => void = () => { this.refresh(); };
  private onStoreChange: () => void = () => { FamilyService.get().pushLocal(); this.refresh(); };
  @State showShare: boolean = false;
  @State reminderOn: boolean = false;
  @State reminderHour: number = 20;
  @State reminderMinute: number = 0;
  @StorageLink('reduceMotion') reduceMotion: boolean = false;
  @State familyExpanded: boolean = false;
  @State familyName: string = '我';
  @State familyCode: string = '';
  @State ready: boolean = false;

  @State todaySaved: string = '0.00';
  @State todayPoints: string = '0';
  @State totalSaved: string = '0.00';
  @State totalPoints: string = '0';
  @State totalCount: string = '0';
  @State treeCount: string = '0';
  @State familySaved: string = '0.00';
  @State familyPoints: string = '0';
  @State familyStatusRes: Resource = $r('app.string.family_status_none');
  @State familyJoined: boolean = false;
  @State members: MemberData[] = [];
  @State taskStates: boolean[] = [];
  @State suggestionsList: string[] = [];
  // 「不和谐的秩序」：品红活点，一屏仅此一处
  @State live: boolean = false;

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onStoreChange);
    FamilyService.get().addChangeListener(this.onChange);
    FamilyService.get().pushLocal();
    this.familyName = FamilyService.get().getNickname();
    ReminderService.isEnabled().then((v: boolean) => { this.reminderOn = v; });
    ReminderService.getHour().then((h: number) => { this.reminderHour = h; });
    ReminderService.getMinute().then((m: number) => { this.reminderMinute = m; });
    this.refresh();
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
    setTimeout(() => this.live = true, AppMotion.reduceMotion() ? 0 : 200);
  }

  aboutToDisappear(): void {
    CarbonStore.get().removeChangeListener(this.onStoreChange);
    FamilyService.get().removeChangeListener(this.onChange);
  }

  refresh(): void {
    const store = CarbonStore.get();
    const family = FamilyService.get();
    // 结算今日任务奖励（幂等），让任务积分实时计入今日/累计积分
    Rewards.syncTaskRewards(store);
    this.todaySaved = store.todaySaved().toFixed(2);
    this.todayPoints = store.todayPoints().toString();
    this.totalSaved = store.totalSaved().toFixed(2);
    this.totalPoints = store.totalPoints().toString();
    this.totalCount = store.totalCount().toString();
    this.treeCount = Rewards.treeCount(store).toString();
    this.familySaved = family.getSaved().toFixed(2);
    this.familyPoints = family.getPoints().toString();
    this.familyJoined = family.getSessionId() !== '';
    this.familyStatusRes = this.familyJoined
      ? (family.isPeerOnline() ? $r('app.string.family_status_online') : $r('app.string.family_status_waiting'))
      : $r('app.string.family_status_none');
    this.members = family.getMembers();
    this.suggestionsList = Rewards.suggestions(store);
    this.taskStates = Rewards.TASKS.map((t: DailyTask) => Rewards.taskDone(t.key, store));
  }

  onGenCode(): void {
    FamilyService.get().genSession().then((code: string) => {
      this.familyCode = code;
      this.refresh();
      this.promptAction.showToast({ message: $r('app.string.family_code_toast', code) });
    });
  }

  onJoin(): void {
    if (this.familyCode === '') {
      this.promptAction.showToast({ message: $r('app.string.family_need_code') });
      return;
    }
    FamilyService.get().joinSession(this.familyCode).then(() => {
      this.refresh();
      this.promptAction.showToast({ message: $r('app.string.family_joined') });
    });
  }

  onLeave(): void {
    FamilyService.get().leaveSession().then(() => {
      this.refresh();
      this.promptAction.showToast({ message: $r('app.string.family_left') });
    });
  }

  onSync(): void {
    FamilyService.get().pushLocal();
    this.refresh();
    this.promptAction.showToast({ message: $r('app.string.family_synced') });
  }

  timeText(): string {
    const h = this.reminderHour < 10 ? '0' + this.reminderHour.toString() : this.reminderHour.toString();
    const m = this.reminderMinute < 10 ? '0' + this.reminderMinute.toString() : this.reminderMinute.toString();
    return h + ':' + m;
  }

  reminderDate(): Date {
    const d = new Date();
    d.setHours(this.reminderHour, this.reminderMinute, 0, 0);
    return d;
  }

  onPickTime(): void {
    this.uiContext.showTimePickerDialog({
      selected: this.reminderDate(),
      onAccept: (value: TimePickerResult) => {
        this.reminderHour = value.hour;
        this.reminderMinute = value.minute;
        ReminderService.setTime(value.hour, value.minute).then(() => {
          if (this.reminderOn) {
            ReminderService.enable().then(() => {
              this.promptAction.showToast({ message: $r('app.string.reminder_time_updated', this.timeText()) });
            });
          } else {
            this.promptAction.showToast({ message: $r('app.string.reminder_time_set', this.timeText()) });
          }
        });
      }
    });
  }

  onReminderChange(isOn: boolean): void {
    this.reminderOn = isOn;
    if (isOn) {
      ReminderService.enable().then(() => {
        this.promptAction.showToast({ message: $r('app.string.reminder_on', this.timeText()) });
      }).catch(() => {
        this.reminderOn = false;
        this.promptAction.showToast({ message: $r('app.string.reminder_enable_failed') });
      });
    } else {
      ReminderService.disable().then(() => {
        this.promptAction.showToast({ message: $r('app.string.reminder_off') });
      });
    }
  }

  shareText(): string {
    return '我在「CarbonLife」App 已累计减排 ' + this.totalSaved +
      ' kg CO₂e，获得 ' + this.totalPoints + ' 积分，种下 ' +
      this.treeCount + ' 棵树。一起加入低碳生活吧！';
  }

  @Builder shareStat(label: ResourceStr, value: string, color: string) {
    Column() {
      Text(value).fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(color);
      Text(label).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
    }.layoutWeight(1).alignItems(HorizontalAlign.Center);
  }

  @Builder sectionTitle(title: ResourceStr, subtitle?: ResourceStr) {
    Row({ space: AppSpacing.SM }) {
      Column()
        .width(3)
        .height(16)
        .borderRadius(2)
        .backgroundColor(AppColor.TEXT_SUB);
      Column({ space: AppSpacing.XXS }) {
        Text(title).fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT).letterSpacing(0.3);
        if (subtitle !== undefined) {
          Text(subtitle).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
        }
      }.alignItems(HorizontalAlign.Start);
    }.alignItems(VerticalAlign.Center);
  }

  @Builder memberRow(m: MemberData) {
    Row({ space: AppSpacing.SM }) {
      Text(m.nickname).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT).layoutWeight(1);
      if (FamilyService.get().isLocal(m.deviceId)) {
        Text($r('app.string.common_me')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.PRIMARY)
          .backgroundColor(AppColor.PRIMARY_SOFT)
          .padding({ left: AppSpacing.XS + 2, right: AppSpacing.XS + 2, top: 1, bottom: 1 })
          .borderRadius(AppRadius.SM);
      }
      Text(m.saved.toFixed(2) + ' kg').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.PRIMARY);
      Text(m.points.toString() + ' 分').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.ACCENT).margin({ left: AppSpacing.SM });
    }
    .width('100%').padding({ top: AppSpacing.XS, bottom: AppSpacing.XS });
  }

  @Builder shareSheet() {
    Column({ space: AppSpacing.MD }) {
      Text($r('app.string.share_title')).fontSize(AppTypography.H3.size).fontWeight(AppTypography.H3.weight).fontColor(AppColor.TEXT);
      AppCard({ cardPadding: AppSpacing.LG, showShadow: false, showBorder: true, enter: this.ready, enterDelayIndex: 0 }) {
        Column({ space: AppSpacing.SM }) {
          Row({ space: AppSpacing.XS }) {
            Image($r('app.media.ic_leaf'))
              .width(18)
              .height(18)
              .fillColor(AppColor.PRIMARY);
            Text($r('app.string.share_brand')).fontSize(AppTypography.BODY.size).fontColor(AppColor.PRIMARY);
          }
          Text(this.totalSaved + ' kg').fontSize(34).fontWeight(FontWeight.Bold).fontColor(AppColor.PRIMARY);
          Text($r('app.string.share_total_saved')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          Divider().color(AppColor.DIVIDER).margin({ top: AppSpacing.SM, bottom: AppSpacing.SM });
          Row() {
            this.shareStat($r('app.string.share_points'), this.totalPoints, AppColor.ACCENT);
            this.shareStat($r('app.string.share_trees'), this.treeCount, AppColor.PRIMARY_LIGHT);
            this.shareStat($r('app.string.share_records'), this.totalCount, AppColor.CHART_BLUE);
          }.width('100%');
        }.width('100%').alignItems(HorizontalAlign.Center);
      }
      AppButton({ text: $r('app.string.share_copy'), type: 'primary', fullWidth: true }).onClick(() => {
        const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareText());
        pasteboard.getSystemPasteboard().setData(data).then(() => {
          this.promptAction.showToast({ message: $r('app.string.share_copied') });
          this.showShare = false;
        });
      });
      AppButton({ text: $r('app.string.common_close'), type: 'ghost', fullWidth: true }).onClick(() => { this.showShare = false; });
    }.width('100%').padding(AppSpacing.LG);
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: AppSpacing.MD }) {
          Column({ space: AppSpacing.LG }) {
            Row() {
              Column({ space: AppSpacing.XXS }) {
                Row({ space: AppSpacing.SM }) {
                  Column()
                    .width(7)
                    .height(7)
                    .borderRadius(4)
                    .backgroundColor(AppColor.MAGENTA)
                    .shadow({ radius: this.live ? 10 : 2, color: AppColor.MAGENTA, offsetX: 0, offsetY: 0 })
                    .scale({ x: this.live ? 1.15 : 0.8, y: this.live ? 1.15 : 0.8 })
                    .animation(AppMotion.loopOptions(1400, true));
                  Text('CARBONLIFE').fontSize(AppTypography.SMALL.size).letterSpacing(2.5).fontColor(AppColor.TEXT_SUB);
                }.alignItems(VerticalAlign.Center);
                Text($r('app.string.home_slogan')).fontSize(AppTypography.H2.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Image($r('app.media.ic_leaf')).width(38).height(38).fillColor(AppColor.TEXT_SUB);
            }.width('100%');

            Column({ space: AppSpacing.XXS }) {
              AnimatedNumber({ value: parseFloat(this.todaySaved), decimals: 2, textSize: AppTypography.DISPLAY.size, textColor: AppColor.READING });
              Text($r('app.string.home_today_unit')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
            }.width('100%').alignItems(HorizontalAlign.Start);

            Row() {
              Column({ space: AppSpacing.XXS }) {
                AnimatedNumber({ value: parseFloat(this.todayPoints), textSize: AppTypography.H3.size, textColor: AppColor.ACCENT });
                Text($r('app.string.home_today_points')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Column({ space: AppSpacing.XXS }) {
                AnimatedNumber({ value: parseFloat(this.totalSaved), decimals: 2, textSize: AppTypography.H3.size, textColor: AppColor.TEXT });
                Text($r('app.string.home_total_saved')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Column({ space: AppSpacing.XXS }) {
                AnimatedNumber({ value: parseFloat(this.treeCount), textSize: AppTypography.H3.size, textColor: AppColor.TEXT });
                Text($r('app.string.home_total_trees')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            }.width('100%');
          }
          .width('100%')
          .padding(AppSpacing.LG)
          .borderRadius(AppRadius.LG)
          .backgroundColor(AppColor.GLASS_STRONG)
          .backdropBlur(24)
          .borderWidth(1)
          .borderColor(AppColor.GLASS_BORDER)
          .shadow(AppShadow.soft())
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

          Row({ space: AppSpacing.SM }) {
            AppButton({ text: $r('app.string.home_go_record'), type: 'primary' }).layoutWeight(1).onClick(() => this.controller.changeIndex(1));
            AppButton({ text: $r('app.string.home_share_card'), type: 'secondary' }).layoutWeight(1).onClick(() => this.showShare = true);
          }
          .width('100%')
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(2) });

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 3 }) {
            Column({ space: AppSpacing.SM }) {
              Row() {
                this.sectionTitle($r('app.string.home_family_title'), $r('app.string.home_family_subtitle'));
                Blank();
                Text(this.familyStatusRes)
                  .fontSize(AppTypography.CAPTION.size)
                  .fontColor(AppColor.TEXT_SUB);
              }.width('100%');
              Row() {
                Column() {
                  AnimatedNumber({ value: parseFloat(this.familySaved), decimals: 2, textSize: AppTypography.H4.size, textColor: AppColor.TEXT });
                  Text($r('app.string.home_family_saved')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1);
                Column() {
                  AnimatedNumber({ value: parseFloat(this.familyPoints), textSize: AppTypography.H4.size, textColor: AppColor.ACCENT });
                  Text($r('app.string.home_family_points')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1);
              }.width('100%').margin({ top: AppSpacing.SM });
              if (this.familyJoined && this.members.length > 0) {
                Column({ space: AppSpacing.XS }) {
                  this.sectionTitle($r('app.string.home_family_members'), this.members.length.toString() + ' 人');
                  ForEach(this.members, (m: MemberData) => {
                    this.memberRow(m);
                  }, (m: MemberData) => m.deviceId + '-' + m.updatedAt.toString());
                }.width('100%').margin({ top: AppSpacing.SM });
              }
              if (this.familyExpanded) {
                TextInput({ text: this.familyName, placeholder: $r('app.string.family_nickname_hint') }).height(42)
                  .fontColor(AppColor.TEXT).placeholderColor(AppColor.TEXT_SUB)
                  .backgroundColor(AppColor.ELEVATED).borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM).margin({ top: AppSpacing.SM })
                  .onChange((v: string) => { this.familyName = v; FamilyService.get().setNickname(v); });
                TextInput({ text: $$this.familyCode, placeholder: $r('app.string.family_code_hint') }).height(42)
                  .fontColor(AppColor.TEXT).placeholderColor(AppColor.TEXT_SUB)
                  .backgroundColor(AppColor.ELEVATED).borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM).margin({ top: AppSpacing.XS });
                Row({ space: AppSpacing.XS }) {
                  AppButton({ text: $r('app.string.family_gen_code'), type: 'secondary', btnHeight: 44 }).layoutWeight(1).onClick(() => this.onGenCode());
                  AppButton({ text: $r('app.string.family_join'), type: 'secondary', btnHeight: 44 }).layoutWeight(1).onClick(() => this.onJoin());
                }.width('100%').margin({ top: AppSpacing.XS });
                Row({ space: AppSpacing.XS }) {
                  Text($r('app.string.family_sync'))
                    .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB)
                    .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
                    .onClick(() => this.onSync());
                  Text($r('app.string.family_leave'))
                    .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB)
                    .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
                    .onClick(() => this.onLeave());
                }.width('100%').margin({ top: AppSpacing.XS });
                Text($r('app.string.family_tip'))
                  .fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB).width('100%').margin({ top: AppSpacing.XS });
                Text($r('app.string.family_collapse'))
                  .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB)
                  .width('100%').textAlign(TextAlign.Center).padding({ top: AppSpacing.SM })
                  .onClick(() => this.familyExpanded = false);
              } else {
                AppButton({ text: $r('app.string.family_manage'), type: 'secondary', btnHeight: 44, fullWidth: true })
                  .margin({ top: AppSpacing.SM })
                  .onClick(() => this.familyExpanded = true);
              }
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 4 }) {
            Column({ space: AppSpacing.SM }) {
              Row() {
                Column() {
                  Text($r('app.string.reminder_title')).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text($r('app.string.reminder_subtitle', this.timeText())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                .onClick(() => this.onPickTime());
                Toggle({ type: ToggleType.Switch, isOn: this.reminderOn }).onChange((isOn: boolean) => this.onReminderChange(isOn));
              }.width('100%');
              Divider().color(AppColor.DIVIDER);
              Row() {
                Column() {
                  Text($r('app.string.a11y_reduce_motion')).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text($r('app.string.a11y_reduce_motion_desc')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Toggle({ type: ToggleType.Switch, isOn: this.reduceMotion })
                  .onChange((isOn: boolean) => { this.reduceMotion = isOn; });
              }.width('100%');
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 5 }) {
            Column({ space: AppSpacing.SM }) {
              this.sectionTitle($r('app.string.home_tasks'));
              ForEach(Rewards.TASKS, (task: DailyTask, index: number) => {
                TaskCard({ task: task, done: this.taskStates[index] ?? false, index: index })
                  .onClick(() => { if (!this.taskStates[index]) { this.controller.changeIndex(1); } });
              }, (task: DailyTask) => task.key);
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 6, marginBottom: AppSpacing.LG }) {
            Column({ space: AppSpacing.SM }) {
              this.sectionTitle($r('app.string.home_suggestions'));
              ForEach(this.suggestionsList, (tip: string, index: number) => {
                Row({ space: AppSpacing.SM }) {
                  Image($r('app.media.ic_power'))
                    .width(18)
                    .height(18)
                    .fillColor(AppColor.PRIMARY);
                  Text(tip).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).layoutWeight(1);
                }.width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM });
              }, (tip: string, index: number) => index.toString());
            }
          }
        }
        .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 120 })
      }
      .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);

      if (this.showShare) {
        Column() {
          Column() {
            this.shareSheet();
          }
          .width('88%').backgroundColor(AppColor.CARD).borderRadius(AppRadius.LG)
          .onClick(() => {});
        }
        .width('100%').height('100%').backgroundColor(AppColor.OVERLAY).justifyContent(FlexAlign.Center)
        .onClick(() => this.showShare = false);
      }
    }
    .width('100%').height('100%');
  }
}
