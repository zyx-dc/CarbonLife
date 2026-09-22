import { PromptAction, UIContext } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { behaviorIcon, CarbonFactors } from '../model/CarbonFactors';
import { AppColor, AppConst } from '../common/Constants';
import { BehaviorDef, CarbonRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { VisionService, VisionResult } from '../model/VisionService';
import { AppCard } from '../components/AppCard';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct RecordTab {
  @StorageLink('recordsVersion') version: number = 0;
  private onChange: () => void = () => { this.todayList = this.todayRecords(); };
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();
  @State category: string = '出行';
  @State selectedKey: string = 'walk';
  @State amountText: string = '1';
  @State note: string = '';
  @State ready: boolean = false;
  @State todayList: CarbonRecord[] = [];

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
      this.promptAction.showToast({ message: '请输入大于 0 的数量' });
      return;
    }
    CarbonStore.get().addRecord(this.currentBehavior(), this.amountValue(), this.note);
    this.promptAction.showToast({ message: '记录成功，减排 ' + this.savedValue().toFixed(2) + ' kg CO₂e' });
    this.amountText = '1';
    this.note = '';
  }

  confirmDelete(id: string, name: string): void {
    this.uiContext.showAlertDialog({
      title: '删除记录',
      message: '确定删除「' + name + '」吗？',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', fontColor: AppColor.DANGER, action: () => {
        CarbonStore.get().deleteRecord(id);
        this.promptAction.showToast({ message: '已删除' });
      }}
    });
  }

  onAiDetect(): void {
    VisionService.pickAndDetect().then((res: VisionResult) => {
      if (res.ok) {
        const b: BehaviorDef = CarbonFactors.find(res.behaviorKey);
        this.category = b.category;
        this.selectedKey = b.key;
      }
      this.promptAction.showToast({ message: res.message });
    });
  }

  todayRecords(): CarbonRecord[] {
    const start = DateUtil.startOfDay(Date.now());
    return CarbonStore.get().recordsInRange(start, Date.now() + 1)
      .sort((a: CarbonRecord, b: CarbonRecord) => b.timestamp - a.timestamp);
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('记录低碳行为').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%')
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 1}) {
          Row({ space: AppSpacing.SM }) {
            Image($r('app.media.ic_ai_scan'))
              .width(40)
              .height(40)
              .fillColor(AppColor.PRIMARY);
            Column() {
              Text('AI 识图识别低碳行为').fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
              Text('选择一张照片，端侧 AI 自动识别场景并推荐低碳行为').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.XS }).width('100%');
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
            AppButton({ text: '拍照/选图', type: 'primary', btnHeight: 34 }).onClick(() => this.onAiDetect());
          }.width('100%');
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 2}) {
          Column({ space: AppSpacing.SM }) {
            Text('选择类别').fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            Row({ space: AppSpacing.XS }) {
              ForEach(CarbonFactors.CATEGORIES, (cat: string) => {
                Text(cat)
                  .fontSize(AppTypography.BODY.size)
                  .fontColor(this.category === cat ? AppColor.TEXT_INVERSE : AppColor.TEXT)
                  .backgroundColor(this.category === cat ? AppColor.PRIMARY : AppColor.BG)
                  .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.XS })
                  .borderRadius(AppRadius.MD)
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
            Text('选择行为').fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            ForEach(CarbonFactors.getByCategory(this.category), (b: BehaviorDef, index: number) => {
              Row({ space: AppSpacing.SM }) {
                Image(behaviorIcon(b.key))
                  .width(24)
                  .height(24)
                  .fillColor(AppColor.PRIMARY);
                Column({ space: 2 }) {
                  Text(b.name).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT);
                  Text('单位：' + b.unit + ' · 因子 ' + b.factor.toString() + ' kg/' + b.unit).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                Radio({ value: b.key, group: 'behavior' }).checked(this.selectedKey === b.key)
                  .onChange((checked: boolean) => { if (checked) this.selectedKey = b.key; });
              }
              .width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .onClick(() => this.selectedKey = b.key);
            }, (b: BehaviorDef) => b.key);
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
          Column({ space: AppSpacing.SM }) {
            Text('数量（' + this.currentBehavior().unit + '）').fontSize(AppTypography.CAPTION_MEDIUM.size).fontColor(AppColor.TEXT_SUB).width('100%');
            Row({ space: AppSpacing.SM }) {
              Button('−').width(44).height(44).backgroundColor(AppColor.BG).fontColor(AppColor.PRIMARY).fontSize(AppTypography.H3.size)
                .onClick(() => this.stepAmount(-1));
              TextInput({ text: $$this.amountText }).type(InputType.Number).layoutWeight(1).height(44).textAlign(TextAlign.Center).backgroundColor(AppColor.BG);
              Button('+').width(44).height(44).backgroundColor(AppColor.BG).fontColor(AppColor.PRIMARY).fontSize(AppTypography.H3.size)
                .onClick(() => this.stepAmount(1));
            }.width('100%').margin({ top: AppSpacing.XS });
            TextInput({ text: $$this.note, placeholder: '备注（可选）' }).height(44).backgroundColor(AppColor.BG).margin({ top: AppSpacing.SM });
            Row() {
              Text('预计减排 ' + this.savedValue().toFixed(2) + ' kg CO₂e').fontSize(AppTypography.BODY.size).fontColor(AppColor.PRIMARY);
              Blank();
              Text('+' + this.pointsValue().toString() + ' 积分').fontSize(AppTypography.BODY.size).fontColor(AppColor.ACCENT);
            }.width('100%').margin({ top: AppSpacing.SM });
            AppButton({ text: '保存记录', type: 'primary', fullWidth: true }).margin({ top: AppSpacing.SM }).onClick(() => this.onSave());
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 5, marginBottom: AppSpacing.LG}) {
          Column({ space: AppSpacing.SM }) {
            Text('今日记录').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.todayList.length === 0) {
              Text('今天还没有记录').fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.SM });
            } else {
              ForEach(this.todayList, (r: CarbonRecord) => {
                Row() {
                  Column({ space: 2 }) {
                    Text(r.name + '  ' + r.amount.toString() + r.unit).fontSize(AppTypography.BODY_MEDIUM.size).fontColor(AppColor.TEXT);
                    Text(DateUtil.formatTime(r.timestamp) + (r.note === '' ? '' : ' · ' + r.note)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start);
                  Text(r.saved.toFixed(2) + ' kg').fontSize(AppTypography.BODY.size).fontColor(AppColor.PRIMARY);
                  Text('删除').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.DANGER).margin({ left: AppSpacing.MD }).onClick(() => this.confirmDelete(r.id, r.name));
                }.width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM });
              }, (r: CarbonRecord) => r.id);
            }
          }
        }
      }
      .width('100%').padding(AppSpacing.MD)
    }
    .width('100%').height('100%').backgroundColor(AppColor.BG).scrollBar(BarState.Off);
  }
}
