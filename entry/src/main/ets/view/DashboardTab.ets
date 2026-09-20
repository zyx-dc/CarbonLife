import { promptAction } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { CarbonStore } from '../model/CarbonStore';
import { CarbonFactors } from '../model/CarbonFactors';
import { AppColor } from '../common/Constants';
import { CategoryStat, CarbonRecord, TrendPoint } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { BarChartView, LineChartView, PieChartView } from '../components/Chart';

@Component
export struct DashboardTab {
  @StorageLink('recordsVersion') version: number = 0;
  @State period: string = 'day';

  trendValues(): number[] {
    return CarbonStore.get().trend(this.period).map((p: TrendPoint) => p.value);
  }

  trendLabels(): string[] {
    return CarbonStore.get().trend(this.period).map((p: TrendPoint) => p.label);
  }

  categoryValues(): number[] {
    return CarbonStore.get().savedByCategory().map((c: CategoryStat) => c.saved);
  }

  categoryColors(): string[] {
    return CarbonStore.get().savedByCategory().map((c: CategoryStat) => c.color);
  }

  exportFile(kind: string): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const ext = kind === 'csv' ? '.csv' : '.json';
      const path = ctx.filesDir + '/carbon_export_' + Date.now().toString() + ext;
      const content = kind === 'csv' ? CarbonStore.get().exportCsv() : CarbonStore.get().exportJson();
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      promptAction.showToast({ message: '已导出到：' + path });
    } catch (e) {
      promptAction.showToast({ message: '导出失败' });
    }
  }

  confirmClear(): void {
    AlertDialog.show({
      title: '清空数据',
      message: '确定要清空全部低碳记录吗？此操作不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确定清空',
        fontColor: AppColor.DANGER,
        action: () => {
          CarbonStore.get().clearAll();
          promptAction.showToast({ message: '已清空' });
        }
      }
    });
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('数据看板')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.TEXT)
          .width('100%')

        Row({ space: 8 }) {
          ForEach(['day', 'week', 'month', 'year'], (p: string) => {
            Text(this.periodLabel(p))
              .fontSize(13)
              .fontColor(this.period === p ? Color.White : AppColor.TEXT)
              .backgroundColor(this.period === p ? AppColor.PRIMARY : AppColor.CARD)
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .borderRadius(20)
              .onClick(() => {
                this.period = p;
              })
          }, (p: string) => p)
        }
        .width('100%')

        Row({ space: 10 }) {
          this.summaryCard('累计减排', CarbonStore.get().totalSaved().toFixed(2), 'kg', AppColor.PRIMARY)
          this.summaryCard('累计积分', CarbonStore.get().totalPoints().toString(), '分', AppColor.ACCENT)
          this.summaryCard('记录条数', CarbonStore.get().totalCount().toString(), '条', AppColor.CHART_BLUE)
        }
        .width('100%')

        Column() {
          Text('减排趋势（' + this.periodLabel(this.period) + '）')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          LineChartView({ data: this.trendValues(), labels: this.trendLabels() })
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('减排对比（柱状图）')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          BarChartView({ data: this.trendValues(), labels: this.trendLabels(), barColor: AppColor.PRIMARY_LIGHT })
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('类别占比（饼图）')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          PieChartView({ data: this.categoryValues(), colors: this.categoryColors() })
            .margin({ top: 8 })
          Row({ space: 16 }) {
            ForEach(CarbonStore.get().savedByCategory(), (c: CategoryStat) => {
              Row({ space: 4 }) {
                Circle({ width: 10, height: 10 }).fill(c.color)
                Text(c.category)
                  .fontSize(12)
                  .fontColor(AppColor.TEXT_SUB)
              }
            }, (c: CategoryStat) => c.category)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('最近记录')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          if (CarbonStore.get().totalCount() === 0) {
            Text('暂无记录')
              .fontSize(13)
              .fontColor(AppColor.TEXT_SUB)
              .margin({ top: 10 })
          } else {
            ForEach(CarbonStore.get().recentRecords(10), (r: CarbonRecord) => {
              Row() {
                Text(r.category)
                  .fontSize(11)
                  .fontColor(Color.White)
                  .backgroundColor(CarbonFactors.categoryColor(r.category))
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(8)
                Text(r.name + ' ' + r.amount.toString() + r.unit)
                  .fontSize(13)
                  .fontColor(AppColor.TEXT)
                  .layoutWeight(1)
                  .margin({ left: 8 })
                Text(r.saved.toFixed(2) + ' kg')
                  .fontSize(13)
                  .fontColor(AppColor.PRIMARY)
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }, (r: CarbonRecord) => r.id)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.CARD)
        .borderRadius(16)

        Column() {
          Text('本地数据管理')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          Row({ space: 10 }) {
            Button('导出 CSV')
              .layoutWeight(1)
              .height(42)
              .backgroundColor(AppColor.PRIMARY)
              .fontColor(Color.White)
              .onClick(() => {
                this.exportFile('csv');
              })
            Button('导出 JSON')
              .layoutWeight(1)
              .height(42)
              .backgroundColor(AppColor.CHART_BLUE)
              .fontColor(Color.White)
              .onClick(() => {
                this.exportFile('json');
              })
          }
          .width('100%')
          .margin({ top: 10 })
          Button('清空全部数据')
            .width('100%')
            .height(42)
            .backgroundColor(AppColor.CARD)
            .fontColor(AppColor.DANGER)
            .borderWidth(1)
            .borderColor(AppColor.DANGER)
            .margin({ top: 10 })
            .onClick(() => {
              this.confirmClear();
            })
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
    .id('dashboard_' + this.version.toString())
  }

  @Builder
  summaryCard(title: string, value: string, unit: string, color: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(unit + ' ' + title)
        .fontSize(10)
        .fontColor(AppColor.TEXT_SUB)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(AppColor.CARD)
    .borderRadius(12)
  }

  periodLabel(p: string): string {
    if (p === 'week') {
      return '周';
    } else if (p === 'month') {
      return '月';
    } else if (p === 'year') {
      return '年';
    }
    return '日';
  }
}
