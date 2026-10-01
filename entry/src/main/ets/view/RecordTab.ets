import { UIContext } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { behaviorIcon, CarbonFactors } from '../model/CarbonFactors';
import { AppColor, AppConst } from '../common/Constants';
import { BehaviorDef, CarbonRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { VisionService, VisionResult } from '../model/VisionService';
import { AppCard } from '../components/AppCard';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppSpacing, AppTypography, ToastHelper } from '../common/Theme';
import { behaviorNameRes, categoryRes, unitRes, resolveStr } from '../common/Localize';

@Component
export struct RecordTab {
  @StorageLink('recordsVersion') version: number = 0;
  private onChange: () => void = () => { this.todayList = this.todayRecords(); };
  private uiContext: UIContext = this.getUIContext();
  @State category: string = '出行';
  @State selectedKey: string = 'walk';
  @State amountText: string = '1';
  @State note: string = '';
  @State ready: boolean = false;
  @State todayList: CarbonRecord[] = [];
  @State removingId: string = '';

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onChange);
    this.todayList = this.todayRecords();
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
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

  pointsValue(): number { return Math.max(1, Math.round(this.savedValue() * AppConst.POINTS_PER_KG)); }

  stepAmount(delta: number): void {
    const step = this.currentBehavior().step;
    let v = this.amountValue() + delta * step;
    if (v < 0) v = 0;
    this.amountText = v.toString();
  }

  onSave(): void {
    if (this.amountValue() <= 0) {
      ToastHelper.show(this.uiContext, $r('app.string.record_err_amount'));
      return;
    }
    CarbonStore.get().addRecord(this.currentBehavior(), this.amountValue(), this.note);
    ToastHelper.show(this.uiContext, $r('app.string.record_saved_toast', this.savedValue().toFixed(2)));
    this.amountText = '1';
    this.note = '';
  }

  confirmDelete(id: string, name: string): void {
    this.uiContext.showAlertDialog({
      title: $r('app.string.record_delete_title'),
      message: $r('app.string.record_delete_message', name),
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
    VisionService.pickAndDetect().then((res: VisionResult) => {
      if (res.ok) {
        const b: BehaviorDef = CarbonFactors.find(res.behaviorKey);
        this.category = b.category;
        this.selectedKey = b.key;
      }
      ToastHelper.show(this.uiContext, res.message);
    });
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
            AppButton({ text: $r('app.string.record_ai_button'), type: 'secondary', btnHeight: 44, fullWidth: true }).onClick(() => this.onAiDetect());
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
                    if (list.length > 0) this.selectedKey = list[0].key;
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
              .onClick(() => this.selectedKey = b.key);
            }, (b: BehaviorDef) => b.key);
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.record_amount_title', resolveStr(unitRes(this.currentBehavior().unit)))).fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            Row({ space: AppSpacing.SM }) {
              Button('−').width(48).height(48).backgroundColor(AppColor.ELEVATED).fontColor(AppColor.TEXT).fontSize(AppTypography.H3.size).fontWeight(FontWeight.Medium)
                .borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM)
                .onClick(() => this.stepAmount(-1));
              TextInput({ text: $$this.amountText }).type(InputType.Number).layoutWeight(1).height(48).textAlign(TextAlign.Center)
                .fontColor(AppColor.TEXT).placeholderColor(AppColor.TEXT_SUB)
                .backgroundColor(AppColor.ELEVATED).borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM);
              Button('+').width(48).height(48).backgroundColor(AppColor.ELEVATED).fontColor(AppColor.TEXT).fontSize(AppTypography.H3.size).fontWeight(FontWeight.Medium)
                .borderWidth(1).borderColor(AppColor.BORDER).borderRadius(AppRadius.SM)
                .onClick(() => this.stepAmount(1));
            }.width('100%').margin({ top: AppSpacing.XS });
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
                .translate({ x: this.removingId === r.id ? 52 : 0, y: this.removingId === r.id ? 30 : 0 })
                .scale({ x: this.removingId === r.id ? 0.9 : 1, y: this.removingId === r.id ? 0.9 : 1 })
                .rotate({ angle: this.removingId === r.id ? 4 : 0 })
                .opacity(this.removingId === r.id ? 0 : 1);
              }, (r: CarbonRecord) => r.id);
            }
          }
        }
      }
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 170 })
      }
      .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);

      // 吸底操作条：保存与预计减排始终在拇指区
      Column({ space: AppSpacing.XS }) {
        Row() {
          Text($r('app.string.record_estimated', this.savedValue().toFixed(2))).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          Blank();
          Text(this.pointsValue() === 1 ? $r('app.string.record_points_one', this.pointsValue().toString()) : $r('app.string.record_points', this.pointsValue().toString())).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.ACCENT);
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
