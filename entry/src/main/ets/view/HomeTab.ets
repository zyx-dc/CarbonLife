import { UIContext, componentSnapshot } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { image } from '@kit.ImageKit';
import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { CarbonStore } from '../model/CarbonStore';
import { Rewards } from '../model/Rewards';
import { AppColor } from '../common/Constants';
import { CategoryStat, DailyTask } from '../model/CarbonTypes';
import { FamilyService, MemberData } from '../model/FamilyService';
import { ReminderService } from '../model/ReminderService';
import { AppButton } from '../components/AppButton';
import { AppCard } from '../components/AppCard';
import { AnimatedNumber } from '../components/AnimatedNumber';
import { TaskCard } from '../components/TaskCard';
import { SaplingView } from '../components/SaplingView';
import { Sapling, SaplingState } from '../model/Sapling';
import { AppMotion, AppRadius, AppShadow, AppSpacing, AppTypography, ToastHelper } from '../common/Theme';
import { categoryRes, resolveStr } from '../common/Localize';

@Component
export struct HomeTab {
  controller: TabsController = new TabsController();
  @StorageLink('recordsVersion') version: number = 0;
  @StorageLink('familyVersion') familyVersion: number = 0;
  private uiContext: UIContext = this.getUIContext();
  private onChange: () => void = () => { this.refresh(); };
  private onStoreChange: () => void = () => { FamilyService.get().pushLocal(); this.refresh(); };
  @State showShare: boolean = false;
  @State reminderOn: boolean = false;
  @State reminderHour: number = 20;
  @State reminderMinute: number = 0;
  @State familyExpanded: boolean = false;
  @State familyName: string = '';
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
  @State suggestionsList: ResourceStr[] = [];
  // 「不和谐的秩序」：品红活点，一屏仅此一处
  @State live: boolean = false;
  // 碳小树：成长值由记录派生，见 model/Sapling.ets
  @State sapling: SaplingState = Sapling.of(CarbonStore.get());
  @State categories: CategoryStat[] = [];
  private lastStage: number = -1;

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onStoreChange);
    FamilyService.get().addChangeListener(this.onChange);
    FamilyService.get().pushLocal();
    const nick = FamilyService.get().getNickname();
    this.familyName = (nick === '' || nick === '我') ? resolveStr($r('app.string.common_me')) : nick;
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
    const s: SaplingState = Sapling.of(store);
    this.sapling = s;
    this.categories = store.savedByCategory();
    if (this.lastStage >= 0 && s.stage > this.lastStage) {
      hilog.info(0x0000, 'CarbonLife', 'sapling level up %{public}d -> %{public}d', this.lastStage, s.stage);
      // 与「记录成功」的系统 Toast 错开，否则升级提示会被立刻覆盖
      const stageName: string = resolveStr(Sapling.stageNameRes(s.stage));
      setTimeout(() => {
        ToastHelper.show(this.uiContext, $r('app.string.home_sapling_levelup', stageName));
      }, 2000);
    }
    this.lastStage = s.stage;
  }

  onGenCode(): void {
    FamilyService.get().genSession().then((code: string) => {
      this.familyCode = code;
      this.refresh();
      ToastHelper.show(this.uiContext, $r('app.string.family_code_toast', code));
    });
  }

  onJoin(): void {
    if (this.familyCode === '') {
      ToastHelper.show(this.uiContext, $r('app.string.family_need_code'));
      return;
    }
    FamilyService.get().joinSession(this.familyCode).then(() => {
      this.refresh();
      ToastHelper.show(this.uiContext, $r('app.string.family_joined'));
    });
  }

  onLeave(): void {
    FamilyService.get().leaveSession().then(() => {
      this.refresh();
      ToastHelper.show(this.uiContext, $r('app.string.family_left'));
    });
  }

  // #5 文本展开：家庭组展开/收起用动画过渡，避免直接显隐的跳动
  private toggleFamily(open: boolean): void {
    this.uiContext.animateTo({ duration: AppMotion.reduceMotion() ? 0 : 280, curve: Curve.EaseInOut }, () => {
      this.familyExpanded = open;
    });
  }

  confirmLeave(): void {
    this.uiContext.showAlertDialog({
      title: $r('app.string.family_leave_confirm_title'),
      message: $r('app.string.family_leave_confirm_message'),
      primaryButton: { value: $r('app.string.common_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.family_leave'), fontColor: AppColor.DANGER, action: () => { this.onLeave(); } }
    });
  }

  onSync(): void {
    FamilyService.get().pushLocal();
    this.refresh();
    ToastHelper.show(this.uiContext, $r('app.string.family_synced'));
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
              ToastHelper.show(this.uiContext, $r('app.string.reminder_time_updated', this.timeText()));
            });
          } else {
            ToastHelper.show(this.uiContext, $r('app.string.reminder_time_set', this.timeText()));
          }
        });
      }
    });
  }

  onReminderChange(isOn: boolean): void {
    this.reminderOn = isOn;
    if (isOn) {
      ReminderService.enable().then(() => {
        ToastHelper.show(this.uiContext, $r('app.string.reminder_on', this.timeText()));
      }).catch(() => {
        this.reminderOn = false;
        ToastHelper.show(this.uiContext, $r('app.string.reminder_enable_failed'));
      });
    } else {
      ReminderService.disable().then(() => {
        ToastHelper.show(this.uiContext, $r('app.string.reminder_off'));
      });
    }
  }

  shareText(): string {
    return resolveStr($r('app.string.report_share_text',
      this.totalSaved,
      this.treeCount,
      resolveStr(Sapling.stageNameRes(this.sapling.stage)),
      this.sapling.streak.toString()));
  }

  private progressWidth(): string {
    return Math.round(this.sapling.progress * 100) + '%';
  }

  /** 把碳账单卡片截成 PNG，交给系统文件选择器保存（无需额外权限）。 */
  private async saveReportImage(): Promise<void> {
    try {
      const pixel: image.PixelMap = await componentSnapshot.get('reportCard');
      const packer: image.ImagePacker = image.createImagePacker();
      const data: ArrayBuffer = await packer.packing(pixel, { format: 'image/png', quality: 100 });
      await packer.release();
      const ctx = this.uiContext.getHostContext();
      if (ctx === undefined) {
        return;
      }
      const documentPicker = new picker.DocumentViewPicker(ctx);
      const fileName: string = 'carbonlife-report-' + Date.now().toString() + '.png';
      const uris: string[] = await documentPicker.save({ newFileNames: [fileName] });
      if (uris.length === 0) {
        return;
      }
      const file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      const stat = fs.statSync(uris[0]);
      hilog.info(0x0000, 'CarbonLife', 'report image saved, size=%{public}d', stat.size);
      ToastHelper.show(this.uiContext, $r('app.string.report_saved'));
    } catch (e) {
      hilog.error(0x0000, 'CarbonLife', 'save report image failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.uiContext, $r('app.string.report_save_failed'));
    }
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
      Text(m.nickname === '' || m.nickname === '我' ? $r('app.string.common_me') : m.nickname).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT).layoutWeight(1);
      if (FamilyService.get().isLocal(m.deviceId)) {
        Text($r('app.string.common_me')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.PRIMARY)
          .backgroundColor(AppColor.PRIMARY_SOFT)
          .padding({ left: AppSpacing.XS + 2, right: AppSpacing.XS + 2, top: 1, bottom: 1 })
          .borderRadius(AppRadius.SM);
      }
      Text(m.saved.toFixed(2) + ' kg').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.PRIMARY);
      Text($r('app.string.home_family_points_suffix', m.points.toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.ACCENT).margin({ left: AppSpacing.SM });
    }
    .width('100%').padding({ top: AppSpacing.XS, bottom: AppSpacing.XS });
  }

  @Builder reportStat(label: ResourceStr, value: string, color: string) {
    Column({ space: AppSpacing.XXS }) {
      Text(value)
        .fontSize(AppTypography.H3.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(color);
      Text(label)
        .fontSize(AppTypography.SMALL.size)
        .fontColor(AppColor.TEXT_SUB);
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder categoryBar(c: CategoryStat) {
    Row({ space: AppSpacing.SM }) {
      Text(categoryRes(c.category))
        .fontSize(AppTypography.SMALL.size)
        .fontColor(AppColor.TEXT_SUB)
        .width(44);
      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(6)
          .borderRadius(3)
          .backgroundColor(AppColor.PRIMARY_SOFT);
        Column()
          .width(this.categoryWidth(c.saved))
          .height(6)
          .borderRadius(3)
          .backgroundColor(c.color);
      }
      .layoutWeight(1)
      .height(6);
      Text(c.saved.toFixed(2))
        .fontSize(AppTypography.SMALL.size)
        .fontColor(AppColor.TEXT_SUB)
        .width(54)
        .textAlign(TextAlign.End);
    }
    .width('100%');
  }

  private maxCategorySaved(): number {
    let max: number = 0;
    this.categories.forEach((c: CategoryStat) => {
      if (c.saved > max) {
        max = c.saved;
      }
    });
    return max <= 0 ? 1 : max;
  }

  private categoryWidth(saved: number): string {
    if (saved <= 0) {
      return '0%';
    }
    return Math.max(2, Math.round(saved / this.maxCategorySaved() * 100)) + '%';
  }

  @Builder shareSheet() {
    Column({ space: AppSpacing.SM }) {
      Scroll() {
      Column({ space: AppSpacing.SM }) {
        Row() {
          Text($r('app.string.report_title'))
            .fontSize(AppTypography.H3.size)
            .fontWeight(AppTypography.H3.weight)
            .fontColor(AppColor.TEXT);
          Blank();
          Text($r('app.string.share_brand'))
            .fontSize(AppTypography.SMALL.size)
            .fontColor(AppColor.TEXT_SUB);
        }
        .width('100%');

        Column({ space: AppSpacing.XXS }) {
          SaplingView({ stage: this.sapling.stage, treeSize: 84, variant: this.sapling.variant });
          Text(Sapling.stageNameRes(this.sapling.stage))
            .fontSize(AppTypography.H4.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT);
          Text(Sapling.variantNameRes(this.sapling.variant))
            .fontSize(AppTypography.CAPTION.size)
            .fontColor(AppColor.TEXT_SUB);
        }
        .width('100%');

        Column({ space: AppSpacing.XXS }) {
          Text(this.totalSaved + ' kg')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.PRIMARY);
          Text($r('app.string.share_total_saved'))
            .fontSize(AppTypography.CAPTION.size)
            .fontColor(AppColor.TEXT_SUB);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);

        Row() {
          this.reportStat($r('app.string.share_points'), this.totalPoints, AppColor.ACCENT);
          this.reportStat($r('app.string.share_trees'), this.treeCount, AppColor.PRIMARY_LIGHT);
          this.reportStat($r('app.string.report_active_days'), this.sapling.activeDays.toString(), AppColor.CHART_BLUE);
          this.reportStat($r('app.string.report_best_streak'), this.sapling.bestStreak.toString(), AppColor.CHART_TEAL);
        }
        .width('100%');

        Divider().color(AppColor.DIVIDER);

        Column({ space: AppSpacing.XS }) {
          Text($r('app.string.report_categories'))
            .fontSize(AppTypography.CAPTION.size)
            .fontColor(AppColor.TEXT_SUB);
          ForEach(this.categories, (c: CategoryStat) => {
            this.categoryBar(c);
          }, (c: CategoryStat) => c.category);
        }
        .width('100%');

        Text($r('app.string.report_equivalent', this.treeCount))
          .fontSize(AppTypography.SMALL.size)
          .fontColor(AppColor.TEXT_SUB)
          .width('100%');

      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, top: AppSpacing.LG, bottom: AppSpacing.SM })
      .alignItems(HorizontalAlign.Start)
      .id('reportCard');
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off);

      Column({ space: AppSpacing.XS }) {
        Row({ space: AppSpacing.SM }) {
          AppButton({ text: $r('app.string.share_copy'), type: 'primary' }).layoutWeight(1).onClick(() => {
            const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareText());
            pasteboard.getSystemPasteboard().setData(data).then(() => {
              ToastHelper.show(this.uiContext, $r('app.string.share_copied'));
              this.showShare = false;
            });
          });
          AppButton({ text: $r('app.string.report_save_image'), type: 'secondary' }).layoutWeight(1).onClick(() => {
            this.saveReportImage();
          });
        }
        .width('100%');
        AppButton({ text: $r('app.string.common_close'), type: 'ghost', fullWidth: true }).onClick(() => { this.showShare = false; });
      }
      .width('100%')
      .padding({ left: AppSpacing.LG, right: AppSpacing.LG, bottom: AppSpacing.LG });
    }
    .width('100%')
    .height('100%');
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: AppSpacing.MD }) {
          Column({ space: AppSpacing.LG }) {
            Row() {
              Column({ space: AppSpacing.XXS }) {
                Row({ space: AppSpacing.SM }) {
                  // 「不和谐的秩序」：品红活点 = 柔和光晕 + 实心圆点（全站仅此一处）
                  // 注：不要用 .shadow() 做辉光 —— 在 7vp 这种极小尺寸下会被渲染成方块
                  Stack() {
                    Column()
                      .width(14)
                      .height(14)
                      .borderRadius(7)
                      .backgroundColor(AppColor.MAGENTA)
                      .opacity(this.live ? 0.22 : 0.10)
                      .scale({ x: this.live ? 1 : 0.7, y: this.live ? 1 : 0.7 })
                      .animation(AppMotion.loopOptions(1400, true));
                    Column()
                      .width(7)
                      .height(7)
                      .borderRadius(4)
                      .backgroundColor(AppColor.MAGENTA);
                  }
                  .width(14)
                  .height(14);
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

          Column() {
            AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 2 }) {
            Row({ space: AppSpacing.MD }) {
              SaplingView({ stage: this.sapling.stage, treeSize: 108, variant: this.sapling.variant })
              Column({ space: AppSpacing.XS }) {
                Row() {
                  Text($r('app.string.home_sapling_title'))
                    .fontSize(AppTypography.H4.size)
                    .fontWeight(AppTypography.H4.weight)
                    .fontColor(AppColor.TEXT);
                  Blank();
                  Text(Sapling.stageNameRes(this.sapling.stage))
                    .fontSize(AppTypography.SMALL.size)
                    .fontColor(AppColor.PRIMARY)
                    .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                    .borderRadius(AppRadius.FULL)
                    .backgroundColor(AppColor.PRIMARY_SOFT);
                  Text('›')
                    .fontSize(AppTypography.BODY.size)
                    .fontColor(AppColor.TEXT_SUB)
                    .margin({ left: AppSpacing.XS });
                }
                .width('100%')
                .alignItems(VerticalAlign.Center);

                Text(Sapling.variantNameRes(this.sapling.variant))
                  .fontSize(AppTypography.SMALL.size)
                  .fontColor(AppColor.TEXT_SUB);

                Stack({ alignContent: Alignment.Start }) {
                  Column()
                    .width('100%')
                    .height(6)
                    .borderRadius(3)
                    .backgroundColor(AppColor.PRIMARY_SOFT);
                  Column()
                    .width(this.progressWidth())
                    .height(6)
                    .borderRadius(3)
                    .backgroundColor(AppColor.PRIMARY)
                    .animation({ duration: AppMotion.reduceMotion() ? 0 : 480, curve: Curve.EaseOut });
                }
                .width('100%')
                .height(6)
                .margin({ top: AppSpacing.XXS, bottom: AppSpacing.XXS });

                Row() {
                  Text($r('app.string.home_sapling_growth', this.sapling.growth))
                    .fontSize(AppTypography.CAPTION.size)
                    .fontColor(AppColor.TEXT_SUB);
                  Blank();
                  Text(this.sapling.maxed
                    ? $r('app.string.home_sapling_max')
                    : $r('app.string.home_sapling_next', this.sapling.stageEnd - this.sapling.growth))
                    .fontSize(AppTypography.CAPTION.size)
                    .fontColor(AppColor.TEXT_SUB);
                }
                .width('100%');

                Row() {
                  Text(this.sapling.activeDays === 0
                    ? $r('app.string.home_sapling_empty')
                    : $r('app.string.home_sapling_streak', this.sapling.streak))
                    .fontSize(AppTypography.SMALL.size)
                    .fontColor(AppColor.ACCENT);
                  Blank();
                  Text(this.sapling.capped
                    ? $r('app.string.home_sapling_today_capped', this.sapling.todayGrowth)
                    : $r('app.string.home_sapling_today', this.sapling.todayGrowth))
                    .fontSize(AppTypography.SMALL.size)
                    .fontColor(this.sapling.capped ? AppColor.ACCENT : AppColor.TEXT_SUB);
                }
                .width('100%');
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start);
            }
            .width('100%')
            .alignItems(VerticalAlign.Center);
          }
          }
          .width('100%')
          .onClick(() => { this.showShare = true; })

          Row({ space: AppSpacing.SM }) {
            AppButton({ text: $r('app.string.home_go_record'), type: 'primary' }).layoutWeight(1).onClick(() => this.controller.changeIndex(1));
            AppButton({ text: $r('app.string.home_share_card'), type: 'secondary' }).layoutWeight(1).onClick(() => this.showShare = true);
          }
          .width('100%')
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(2) });

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 3 }) {
            Column({ space: AppSpacing.SM }) {
              this.sectionTitle($r('app.string.home_tasks'));
              ForEach(Rewards.TASKS, (task: DailyTask, index: number) => {
                TaskCard({ task: task, done: this.taskStates[index] ?? false, index: index })
                  .onClick(() => { if (!this.taskStates[index]) { this.controller.changeIndex(1); } });
              }, (task: DailyTask) => task.key);
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 4 }) {
            Column({ space: AppSpacing.SM }) {
              Row() {
                this.sectionTitle($r('app.string.home_family_title'), $r('app.string.home_family_subtitle'));
                Blank();
                Text(this.familyStatusRes)
                  .fontSize(AppTypography.CAPTION.size)
                  .fontColor(AppColor.TEXT_SUB);
              }.width('100%');
              // 未加入家庭时不再重复展示本机数据（与「今日/累计」口径避免混淆）
              if (this.familyJoined) {
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
                if (this.members.length >= 2) {
                  Column({ space: AppSpacing.XS }) {
                    this.sectionTitle($r('app.string.home_family_members'), $r('app.string.home_family_people', this.members.length.toString()));
                    ForEach(this.members, (m: MemberData) => {
                      this.memberRow(m);
                    }, (m: MemberData) => m.deviceId + '-' + m.updatedAt.toString());
                  }.width('100%').margin({ top: AppSpacing.SM });
                }
              }
              if (this.familyExpanded) {
                Column() {
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
                      .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.DANGER)
                      .layoutWeight(1).textAlign(TextAlign.Center).padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
                      .onClick(() => this.confirmLeave());
                  }.width('100%').margin({ top: AppSpacing.XS });
                  Text($r('app.string.family_tip'))
                    .fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB).width('100%').margin({ top: AppSpacing.XS });
                  Text($r('app.string.family_collapse'))
                    .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB)
                    .width('100%').textAlign(TextAlign.Center).padding({ top: AppSpacing.SM })
                    .onClick(() => this.toggleFamily(false));
                }
                .width('100%')
                .transition(TransitionEffect.OPACITY.animation({ duration: AppMotion.reduceMotion() ? 0 : 240, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ y: -12 })));
              } else {
                AppButton({ text: $r('app.string.family_manage'), type: 'secondary', btnHeight: 44, fullWidth: true })
                  .margin({ top: AppSpacing.SM })
                  .onClick(() => this.toggleFamily(true));
              }
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 5 }) {
            Column({ space: AppSpacing.SM }) {
              Row() {
                Column() {
                  Text($r('app.string.reminder_title')).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text($r('app.string.reminder_subtitle', this.timeText())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB)
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Toggle({ type: ToggleType.Switch, isOn: this.reminderOn })
                  .accessibilityText(resolveStr($r('app.string.reminder_title')))
                  .onChange((isOn: boolean) => this.onReminderChange(isOn));
              }
              .width('100%')
              .onClick(() => this.onPickTime())
              .clickEffect({ level: ClickEffectLevel.LIGHT });
            }
          }

          AppCard({ cardPadding: AppSpacing.MD, enter: this.ready, enterDelayIndex: 6, marginBottom: AppSpacing.LG }) {
            Column({ space: AppSpacing.SM }) {
              this.sectionTitle($r('app.string.home_suggestions'));
              ForEach(this.suggestionsList, (tip: ResourceStr, index: number) => {
                Row({ space: AppSpacing.SM }) {
                  Image($r('app.media.ic_power'))
                    .width(18)
                    .height(18)
                    .fillColor(AppColor.PRIMARY);
                  Text(tip).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).layoutWeight(1);
                }.width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM });
              }, (tip: ResourceStr, index: number) => index.toString());
            }
          }
        }
        .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
      }
      .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);

      if (this.showShare) {
        Column() {
          Column() {
            this.shareSheet();
          }
          .width('88%').height('82%').backgroundColor(AppColor.CARD).borderRadius(AppRadius.LG)
          .onClick(() => {});
        }
        .width('100%').height('100%').backgroundColor(AppColor.OVERLAY).justifyContent(FlexAlign.Center)
        .onClick(() => this.showShare = false);
      }
    }
    .width('100%').height('100%');
  }
}
