import { promptAction } from '@kit.ArkUI';
import { CarbonStore } from '../model/CarbonStore';
import { CarbonFactors } from '../model/CarbonFactors';
import { AppColor, AppConst } from '../common/Constants';
import { BehaviorDef, CarbonRecord } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';

@Component
export struct RecordTab {
  @StorageLink('recordsVersion') version: number = 0;
  @State category: string = '出行';
  @State selectedKey: string = 'walk';
  @State amountText: string = '1';
  @State note: string = '';

  currentBehavior(): BehaviorDef {
    return CarbonFactors.find(this.selectedKey);
  }

  amountValue(): number {
    const v = parseFloat(this.amountText);
    if (isNaN(v) || v <= 0) {
      return 0;
    }
    return v;
  }

  savedValue(): number {
    return this.currentBehavior().factor * this.amountValue();
  }

  pointsValue(): number {
    return Math.max(1, Math.round(this.savedValue() * AppConst.POINTS_PER_KG));
  }

  stepAmount(delta: number): void {
    const step = this.currentBehavior().step;
    let v = this.amountValue() + delta * step;
    if (v < 0) {
      v = 0;
    }
    this.amountText = v.toString();
  }

  onSave(): void {
    if (this.amountValue() <= 0) {
      promptAction.showToast({ message: '请输入大于 0 的数量' });
      return;
    }
    CarbonStore.get().addRecord(this.currentBehavior(), this.amountValue(), this.note);
    promptAction.showToast({ message: '记录成功，减排 ' + this.savedValue().toFixed(2) + ' kg CO₂e' });
    this.amountText = '1';
    this.note = '';
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('记录低碳行为')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.TEXT)
          .width('100%')

        Column() {
          Text('选择类别')
            .fontSize(13)
            .fontColor(AppColor.TEXT_SUB)
            .width('100%')
          Row({ space: 8 }) {
            ForEach(CarbonFactors.CATEGORIES, (cat: string) => {
              Text(cat)
                .fontSize(13)
                .fontColor(this.category === cat ? Color.White : AppColor.TEXT)
                .backgroundColor(this.category === cat ? AppColor.PRIMARY : AppColor.BG)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(20)
                .onClick(() => {
                  this.category = cat;
                  const list = CarbonFactors.getByCategory(cat);
                  if (list.length > 0) {
                    this.selectedKey = list[0].key;
                  }
                })
            }, (cat: string) => cat)
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('选择行为')
            .fontSize(13)
            .fontColor(AppColor.TEXT_SUB)
            .width('100%')
          ForEach(CarbonFactors.getByCategory(this.category), (b: BehaviorDef) => {
            Row() {
              Text(b.icon)
                .fontSize(22)
              Column() {
                Text(b.name)
                  .fontSize(14)
                  .fontColor(AppColor.TEXT)
                Text('单位：' + b.unit + ' · 因子 ' + b.factor.toString() + ' kg/' + b.unit)
                  .fontSize(11)
                  .fontColor(AppColor.TEXT_SUB)
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 10 })
              Radio({ value: b.key, group: 'behavior' })
                .checked(this.selectedKey === b.key)
                .onChange((checked: boolean) => {
                  if (checked) {
                    this.selectedKey = b.key;
                  }
                })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.selectedKey = b.key;
            })
          }, (b: BehaviorDef) => b.key)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('数量（' + this.currentBehavior().unit + '）')
            .fontSize(13)
            .fontColor(AppColor.TEXT_SUB)
            .width('100%')
          Row({ space: 12 }) {
            Button('−')
              .width(44)
              .height(44)
              .backgroundColor(AppColor.BG)
              .fontColor(AppColor.PRIMARY)
              .fontSize(20)
              .onClick(() => {
                this.stepAmount(-1);
              })
            TextInput({ text: $$this.amountText })
              .type(InputType.Number)
              .layoutWeight(1)
              .height(44)
              .textAlign(TextAlign.Center)
              .backgroundColor(AppColor.BG)
            Button('+')
              .width(44)
              .height(44)
              .backgroundColor(AppColor.BG)
              .fontColor(AppColor.PRIMARY)
              .fontSize(20)
              .onClick(() => {
                this.stepAmount(1);
              })
          }
          .width('100%')
          .margin({ top: 8 })

          TextInput({ text: $$this.note, placeholder: '备注（可选）' })
            .height(44)
            .backgroundColor(AppColor.BG)
            .margin({ top: 12 })

          Row() {
            Text('预计减排 ' + this.savedValue().toFixed(2) + ' kg CO₂e')
              .fontSize(13)
              .fontColor(AppColor.PRIMARY)
            Blank()
            Text('+' + this.pointsValue().toString() + ' 积分')
              .fontSize(13)
              .fontColor(AppColor.ACCENT)
          }
          .width('100%')
          .margin({ top: 12 })

          Button('保存记录')
            .width('100%')
            .height(46)
            .backgroundColor(AppColor.PRIMARY)
            .fontColor(Color.White)
            .margin({ top: 12 })
            .onClick(() => {
              this.onSave();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('今日记录')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          if (this.todayRecords().length === 0) {
            Text('今天还没有记录')
              .fontSize(13)
              .fontColor(AppColor.TEXT_SUB)
              .margin({ top: 12, bottom: 12 })
          } else {
            ForEach(this.todayRecords(), (r: CarbonRecord) => {
              Row() {
                Column() {
                  Text(r.name + '  ' + r.amount.toString() + r.unit)
                    .fontSize(14)
                    .fontColor(AppColor.TEXT)
                  Text(DateUtil.formatTime(r.timestamp) + (r.note === '' ? '' : ' · ' + r.note))
                    .fontSize(11)
                    .fontColor(AppColor.TEXT_SUB)
                    .margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                Text(r.saved.toFixed(2) + ' kg')
                  .fontSize(13)
                  .fontColor(AppColor.PRIMARY)
                Text('删除')
                  .fontSize(12)
                  .fontColor(AppColor.DANGER)
                  .margin({ left: 12 })
                  .onClick(() => {
                    CarbonStore.get().deleteRecord(r.id);
                  })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
            }, (r: CarbonRecord) => r.id)
          }
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
    .id('record_' + this.version.toString())
  }

  todayRecords(): CarbonRecord[] {
    const start = DateUtil.startOfDay(Date.now());
    return CarbonStore.get().recordsInRange(start, Date.now() + 1);
  }
}
