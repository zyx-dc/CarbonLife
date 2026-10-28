import { UIContext } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CarbonStore } from '../model/CarbonStore';
import { behaviorIcon, CarbonFactors } from '../model/CarbonFactors';
import { AppColor, AppConst } from '../common/Constants';
import { BehaviorDef, CarbonRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { VisionService, VisionResult } from '../model/VisionService';
import { AppCard } from '../components/AppCard';
import { AppButton } from '../components/AppButton';
import { RangeSlider } from '../components/RangeSlider';
import { AppMotion, AppRadius, AppSpacing, AppTypography, ToastHelper } from '../common/Theme';
import { behaviorNameRes, categoryRes, unitRes, resolveStr } from '../common/Localize';

@Component
export struct RecordTab {
  @StorageLink('recordsVersion') version: number = 0;
  private onChange: () => void = () => { this.todayList = this.todayRecords(); this.todayRecordPoints = CarbonStore.get().recordPointsToday(); };
  private uiContext: UIContext = this.getUIContext();
  controller: TabsController = new TabsController();
  @State category: string = '出行';
  @State selectedKey: string = 'walk';
  @State amountText: string = '1';
  @State note: string = '';
  @State ready: boolean = false;
  @State todayList: CarbonRecord[] = [];
  @State todayRecordPoints: number = 0;
  @State removingId: string = '';
  @State amountPulse: boolean = false;
  // 首页每日任务点击时写入，格式 "t1|<时间戳>"；时间戳保证重复点击也会触发
  @StorageLink('recordPreset') @Watch('applyPreset') preset: string = '';

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onChange);
    this.todayList = this.todayRecords();
    this.todayRecordPoints = CarbonStore.get().recordPointsToday();
    this.applyPreset();
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
  }

  /** 把「今日任务」的预选落到记录页：t1 出行 / t2 餐饮 / t4 节能；t3 不改变选择 */
  private applyPreset(): void {
    if (this.preset === '') {
      return;
    }
    const taskKey: string = this.preset.split('|')[0];
    let behaviorKey: string = '';
    switch (taskKey) {
      case 't1': behaviorKey = 'walk'; break;
      case 't2': behaviorKey = 'clean_plate'; break;
      case 't4': behaviorKey = 'save_power'; break;
      default: return;
    }
    const b: BehaviorDef = CarbonFactors.find(behaviorKey);
    this.category = b.category;
    this.selectedKey = b.key;
    this.amountText = b.step.toString();
  }

  /** #4 数量步进：滑杆之外再给 +/−，让「精确设定」和「能调」都变得明确 */
  private stepAmount(dir: number): void {
    const b: BehaviorDef = this.currentBehavior();
    const st: number = b.step > 0 ? b.step : 1;
    const next: number = Math.max(b.step, Math.min(this.amountMax(), this.amountValue() + dir * st));
    const snapped: number = Math.round(next / st) * st;
    this.amountText = snapped.toString();
    if (!AppMotion.reduceMotion()) {
      this.amountPulse = true;
      setTimeout(() => { this.amountPulse = false; }, 130);
    }
  }

  aboutToDisappear(): void {
    CarbonStore.get().removeChangeListener(this.onChange);
  }

  currentBehavior(): BehaviorDef { return CarbonFactors.find(this.selectedKey); }

  amountValue(): number {
    const v = parseFloat(this.amountText);
    return isNaN(v) || v <= 0 ? 0 : v;
  }

  savedValue(): number { return this.currentBehavior().factor * this.amountValue(); }

  pointsValue(): number {
    // 与 CarbonStore.addRecord 口径一致：最低 MIN_RECORD_POINTS，并受当日记录积分上限约束
    const saved = this.savedValue();
    const base = saved > 0 ? Math.max(AppConst.MIN_RECORD_POINTS, Math.round(saved * AppConst.POINTS_PER_KG)) : 0;
    const remaining = AppConst.DAILY_RECORD_POINTS_CAP - this.todayRecordPoints;
    return remaining <= 0 ? 0 : Math.min(base, remaining);
  }

  private amountMax(): number {
    const b: BehaviorDef = this.currentBehavior();
    let slots = 20;
    if (b.unit === '餐' || b.unit === '次') {
      slots = 5;
    }
    return b.step * slots;
  }

  onSave(): void {
    if (this.amountValue() <= 0) {
      ToastHelper.show(this.uiContext, $r('app.string.record_err_amount'));
      return;
    }
    CarbonStore.get().addRecord(this.currentBehavior(), this.amountValue(), this.note);
    ToastHelper.show(this.uiContext, $r('app.string.record_saved_toast', this.savedValue().toFixed(2)));
    this.amountText = this.currentBehavior().step.toString();
    this.note = '';
    // #5 页面转场：保存后回到首页，由「切 Tab 重播入场」承接过渡
    if (!AppMotion.reduceMotion()) {
      setTimeout(() => this.controller.changeIndex(0), 240);
    }
  }

  confirmDelete(id: string, name: string): void {
    const store = CarbonStore.get();
    const rec = store.findRecord(id);
    const afterTotal = rec !== null ? store.totalPoints() - rec.points : store.totalPoints();
    const over = afterTotal < store.spentPoints();
    this.uiContext.showAlertDialog({
      title: $r('app.string.record_delete_title'),
      message: over ? $r('app.string.record_delete_message_over') : $r('app.string.record_delete_message', name),
      primaryButton: { value: $r('app.string.common_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.common_delete'), fontColor: AppColor.DANGER, action: () => {
        this.animateDelete(id);
      }}
    });
  }

  // #8 卡片曲线删除：沿弧线（右下 + 微旋转）缩放淡出，动画结束后再真正删除
  private animateDelete(id: string): void {
    const reduce = AppMotion.reduceMotion();
    this.uiContext.animateTo({ duration: reduce ? 0 : 380, curve: Curve.EaseIn }, () => {
      this.removingId = id;
    });
    setTimeout(() => {
      CarbonStore.get().deleteRecord(id);
      this.removingId = '';
      ToastHelper.show(this.uiContext, $r('app.string.record_deleted'));
    }, reduce ? 0 : 380);
  }

  onAiDetect(): void {
    // 相册入口
    VisionService.pickAndDetect()
      .then((res: VisionResult) => this.applyVisionResult(res))
      .catch((e: Error) => {
        hilog.error(0x0C05, 'RecordTab', 'album rejected: %{public}s', e.message);
      });
  }

  onAiCapture(): void {
    // 拍照入口：交给系统相机代拍，不需要 CAMERA 权限。
    // 部分设备/模拟器可能不支持相机选择器，失败时退回相册，避免按钮点不出反应。
    const ctx = this.getUIContext().getHostContext() as common.Context;
    VisionService.captureAndDetect(ctx)
      .then((res: VisionResult) => {
        if (res.ok || res.detail === '' || res.detail.indexOf('camera:') !== 0) {
          this.applyVisionResult(res);
          return;
        }
        hilog.warn(0x0C05, 'RecordTab', 'camera unavailable (%{public}s), fallback to album',
          res.detail);
        this.onAiDetect();
      })
      .catch((e: Error) => {
        hilog.error(0x0C05, 'RecordTab', 'camera rejected: %{public}s', e.message);
        this.onAiDetect();
      });
  }

  private applyVisionResult(res: VisionResult): void {
    if (res.ok) {
      const b: BehaviorDef = CarbonFactors.find(res.behaviorKey);
      this.category = b.category;
      this.selectedKey = b.key;
      this.amountText = b.step.toString();
    } else if (res.detail !== '') {
      hilog.info(0x0C05, 'RecordTab', 'vision failed: %{public}s', res.detail);
    }
    ToastHelper.show(this.uiContext, res.message);
  }

  todayRecords(): CarbonRecord[] {
    const start = DateUtil.startOfDay(Date.now());
    return CarbonStore.get().recordsInRange(start, Date.now() + 1)
      .sort((a: CarbonRecord, b: CarbonRecord) => b.timestamp - a.timestamp);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
      Column({ space: AppSpacing.MD }) {
        Column({ space: AppSpacing.XS }) {
          Text('RECORD').fontSize(AppTypography.SMALL.size).letterSpacing(2.5).fontColor(AppColor.TEXT_SUB);
          Text($r('app.string.record_title')).fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 1}) {
          Column({ space: AppSpacing.SM }) {
            Row({ space: AppSpacing.SM }) {
              Image($r('app.media.ic_ai_scan'))
                .width(40)
                .height(40)
                .fillColor(AppColor.PRIMARY);
              Column({ space: AppSpacing.XXS }) {
                Text($r('app.string.record_ai_title')).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT).maxLines(2);
                Text($r('app.string.record_ai_desc')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).width('100%').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis });
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            }.width('100%').alignItems(VerticalAlign.Center);
            Row({ space: AppSpacing.SM }) {
              AppButton({ text: $r('app.string.record_ai_button_camera'), type: 'primary', btnHeight: 44 })
                .layoutWeight(1)
                .onClick(() => this.onAiCapture());
              AppButton({ text: $r('app.string.record_ai_button_album'), type: 'secondary', btnHeight: 44 })
                .layoutWeight(1)
                .onClick(() => this.onAiDetect());
            }.width('100%');
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 2}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.record_category_title')).fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            Row({ space: AppSpacing.XS }) {
              ForEach(CarbonFactors.CATEGORIES, (cat: string) => {
                Text(categoryRes(cat))
                  .fontSize(AppTypography.SMALL.size)
                  .fontColor(this.category === cat ? AppColor.TEXT_INVERSE : AppColor.TEXT)
                  .backgroundColor(this.category === cat ? AppColor.PRIMARY : AppColor.GLASS_STRONG)
                  .borderWidth(1)
                  .borderColor(this.category === cat ? AppColor.PRIMARY : AppColor.GLASS_BORDER)
                  .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
                  .height(38)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .borderRadius(AppRadius.FULL)
                  .onClick(() => {
                    this.category = cat;
                    const list = CarbonFactors.getByCategory(cat);
                    if (list.length > 0) { this.selectedKey = list[0].key; this.amountText = list[0].step.toString(); }
                  });
              }, (cat: string) => cat);
            }.width('100%').margin({ top: AppSpacing.XS });
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 3}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.record_behavior_title')).fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            ForEach(CarbonFactors.getByCategory(this.category), (b: BehaviorDef, index: number) => {
              Row({ space: AppSpacing.SM }) {
                Image(behaviorIcon(b.key))
                  .width(24)
                  .height(24)
                  .fillColor(this.selectedKey === b.key ? AppColor.PRIMARY : AppColor.TEXT_SUB);
                Column({ space: 2 }) {
                  Text(behaviorNameRes(b.key, b.name)).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text($r('app.string.record_behavior_factor', resolveStr(unitRes(b.unit)), b.factor.toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Stack() {
                  Circle({ width: 22, height: 22 })
                    .fill(Color.Transparent)
                    .stroke(this.selectedKey === b.key ? AppColor.PRIMARY : AppColor.BORDER)
                    .strokeWidth(1.5);
                  if (this.selectedKey === b.key) {
                    Circle({ width: 11, height: 11 }).fill(AppColor.PRIMARY);
                  }
                }.width(22).height(22);
              }
              .width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .onClick(() => { this.selectedKey = b.key; this.amountText = b.step.toString(); });
            }, (b: BehaviorDef) => b.key);
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.record_amount_title', resolveStr(unitRes(this.currentBehavior().unit)))).fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            Row({ space: AppSpacing.SM }) {
              Text(this.amountText + ' ' + resolveStr(unitRes(this.currentBehavior().unit)))
                .fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.PRIMARY)
                .scale({ x: this.amountPulse ? 1.08 : 1, y: this.amountPulse ? 1.08 : 1 })
                .animation({ duration: AppMotion.reduceMotion() ? 0 : 160, curve: Curve.Friction });
              Blank();
              Text('−')
                .width(44).height(44).textAlign(TextAlign.Center)
                .fontSize(AppTypography.H3.size).fontColor(AppColor.TEXT)
                .backgroundColor(AppColor.ELEVATED)
                .borderWidth(1).borderColor(AppColor.BORDER)
                .borderRadius(AppRadius.SM)
                .onClick(() => this.stepAmount(-1));
              Text('+')
                .width(44).height(44).textAlign(TextAlign.Center)
                .fontSize(AppTypography.H3.size).fontColor(AppColor.TEXT)
                .backgroundColor(AppColor.ELEVATED)
                .borderWidth(1).borderColor(AppColor.BORDER)
                .borderRadius(AppRadius.SM)
                .onClick(() => this.stepAmount(1));
            }.width('100%').alignItems(VerticalAlign.Center);
            // #4 滑杆吸附：按行为步长（0.5 / 1 / 5）吸附，松手时读数轻微回弹
            // 自绘 RangeSlider：系统 Slider 在本设备上滑块会多出一层「灰方块 + 白圈」底衬
            RangeSlider({
              value: this.amountValue(),
              min: this.currentBehavior().step,
              max: this.amountMax(),
              step: this.currentBehavior().step,
              trackHeight: 10,
              blockSize: 24,
              onChange: (value: number) => {
                this.amountText = value.toString();
              },
              onChangeEnd: () => {
                if (!AppMotion.reduceMotion()) {
                  this.amountPulse = true;
                  setTimeout(() => { this.amountPulse = false; }, 130);
                }
              }
            })
              .width('100%');
            Text(this.todayRecordPoints >= AppConst.DAILY_RECORD_POINTS_CAP
              ? $r('app.string.record_cap_reached', AppConst.DAILY_RECORD_POINTS_CAP.toString())
              : $r('app.string.record_points_progress', this.todayRecordPoints.toString(), AppConst.DAILY_RECORD_POINTS_CAP.toString()))
              .fontSize(AppTypography.SMALL.size)
              .fontColor(this.todayRecordPoints >= AppConst.DAILY_RECORD_POINTS_CAP ? AppColor.DANGER : AppColor.TEXT_SUB)
              .width('100%')
              .margin({ top: AppSpacing.XS });
            TextInput({ text: $$this.note, placeholder: $r('app.string.record_note_placeholder') }).height(44)
              .fontColor(AppColor.TEXT).placeholderColor(AppColor.TEXT_SUB)
              .backgroundColor(AppColor.ELEVATED).borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM).margin({ top: AppSpacing.SM });
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 5, marginBottom: AppSpacing.LG}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.record_today_title')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.todayList.length === 0) {
              Text($r('app.string.record_empty')).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.SM });
            } else {
              ForEach(this.todayList, (r: CarbonRecord) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(resolveStr(behaviorNameRes(r.behaviorKey, r.name)) + '  ' + r.amount.toString() + resolveStr(unitRes(r.unit))).fontSize(AppTypography.BODY_MEDIUM.size).fontColor(AppColor.TEXT);
                    Text(DateUtil.formatTime(r.timestamp) + (r.note === '' ? '' : ' · ' + r.note)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                  Text(r.saved.toFixed(2) + ' kg').fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT);
                  Text($r('app.string.common_delete')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.DANGER).margin({ left: AppSpacing.MD }).onClick(() => this.confirmDelete(r.id, resolveStr(behaviorNameRes(r.behaviorKey, r.name))));
                }
                .width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
                .clip(true)
                .constraintSize({ maxHeight: this.removingId === r.id ? 0 : 1000 })
                .translate({ x: this.removingId === r.id ? 52 : 0, y: this.removingId === r.id ? 30 : 0 })
                .scale({ x: this.removingId === r.id ? 0.9 : 1, y: this.removingId === r.id ? 0.9 : 1 })
                .rotate({ angle: this.removingId === r.id ? 4 : 0 })
                .opacity(this.removingId === r.id ? 0 : 1);
              }, (r: CarbonRecord) => r.id);
            }
          }
        }
      }
      // 底部留白：让出吸底操作条（≈86vp）+ 呼吸间距；Tabs 已为导航栏占位，此处无需再让
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 110 })
      }
      .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);

      // 吸底操作条：保存与预计减排始终在拇指区
      Column({ space: AppSpacing.XS }) {
        Row() {
          Text($r('app.string.record_estimated', this.savedValue().toFixed(2))).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          Blank();
          Text($r('app.string.record_points', this.pointsValue().toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.ACCENT);
        }.width('100%');
        AppButton({ text: $r('app.string.record_save'), type: 'primary', fullWidth: true }).onClick(() => this.onSave());
      }
      .width('100%')
      .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
      .backgroundColor(AppColor.GLASS_STRONG)
      .backdropBlur(24)
      .borderWidth({ top: 1 })
      .borderColor(AppColor.DIVIDER);
    }
    .width('100%').height('100%');
  }
}
