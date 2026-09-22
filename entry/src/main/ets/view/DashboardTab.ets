import { PromptAction, UIContext } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { CarbonStore } from '../model/CarbonStore';
import { CarbonFactors } from '../model/CarbonFactors';
import { AppColor } from '../common/Constants';
import { CategoryStat, CarbonRecord, TrendPoint } from '../model/CarbonTypes';
import { BarChartView, LineChartView, PieChartView } from '../components/Chart';
import { AppCard } from '../components/AppCard';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct DashboardTab {
  @StorageLink('recordsVersion') version: number = 0;
  @State @Watch('onPeriodChange') period: string = 'day';
  private onChange: () => void = () => { this.refreshData(); };
  @State trendValues: number[] = [];
  @State trendLabels: string[] = [];
  @State categoryValues: number[] = [];
  @State categoryColors: string[] = [];
  @State legendData: CategoryStat[] = [];
  @State summarySaved: string = '0.00';
  @State summaryPoints: string = '0';
  @State summaryCount: string = '0';
  @State recentList: CarbonRecord[] = [];
  @State ready: boolean = false;
  private uiContext: UIContext = this.getUIContext();
  private promptAction: PromptAction = this.uiContext.getPromptAction();

  aboutToAppear(): void {
    CarbonStore.get().addChangeListener(this.onChange);
    this.refreshData();
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
  }

  aboutToDisappear(): void {
    CarbonStore.get().removeChangeListener(this.onChange);
  }

  onPeriodChange(): void { this.refreshData(); }

  refreshData(): void {
    const store = CarbonStore.get();
    const trend: TrendPoint[] = store.trend(this.period);
    this.trendValues = trend.map((p: TrendPoint) => p.value);
    this.trendLabels = trend.map((p: TrendPoint) => p.label);
    const categoryStats: CategoryStat[] = store.savedByCategory();
    this.categoryValues = categoryStats.map((c: CategoryStat) => c.saved);
    this.categoryColors = categoryStats.map((c: CategoryStat) => c.color);
    this.legendData = categoryStats.filter((c: CategoryStat) => c.saved > 0);
    this.summarySaved = store.totalSaved().toFixed(2);
    this.summaryPoints = store.totalPoints().toString();
    this.summaryCount = store.totalCount().toString();
    this.recentList = store.recentRecords(10);
  }

  exportFile(kind: string): void {
    try {
      const ctx = this.uiContext.getHostContext() as common.UIAbilityContext;
      const ext = kind === 'csv' ? '.csv' : '.json';
      const path = ctx.filesDir + '/carbon_export_' + Date.now().toString() + ext;
      const content = kind === 'csv' ? CarbonStore.get().exportCsv() : CarbonStore.get().exportJson();
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      fs.closeSync(file);
      this.promptAction.showToast({ message: '已导出到：' + path });
    } catch (e) {
      this.promptAction.showToast({ message: '导出失败' });
    }
  }

  confirmClear(): void {
    this.uiContext.showAlertDialog({
      title: '清空数据',
      message: '确定要清空全部低碳记录与兑换记录吗？此操作不可恢复。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '确定清空', fontColor: AppColor.DANGER, action: () => {
        CarbonStore.get().clearAll();
        this.promptAction.showToast({ message: '已清空' });
      }}
    });
  }

  periodLabel(p: string): string {
    if (p === 'week') return '周';
    if (p === 'month') return '月';
    if (p === 'year') return '年';
    return '日';
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Text('数据看板').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%')
          .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        Row({ space: AppSpacing.XS }) {
          ForEach(['day', 'week', 'month', 'year'], (p: string) => {
            Text(this.periodLabel(p))
              .fontSize(AppTypography.BODY.size)
              .fontColor(this.period === p ? AppColor.TEXT_INVERSE : AppColor.TEXT)
              .backgroundColor(this.period === p ? AppColor.PRIMARY : AppColor.CARD)
              .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.XS, bottom: AppSpacing.XS })
              .borderRadius(AppRadius.MD)
              .onClick(() => this.period = p);
          }, (p: string) => p);
        }
        .width('100%')
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(1) });

        Row({ space: AppSpacing.SM }) {
          Column({ space: AppSpacing.XS }) {
            Text(this.summarySaved).fontSize(AppTypography.H3.size).fontWeight(FontWeight.Bold).fontColor(AppColor.PRIMARY);
            Text('kg 累计减排').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.BG).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            Text(this.summaryPoints).fontSize(AppTypography.H3.size).fontWeight(FontWeight.Bold).fontColor(AppColor.ACCENT);
            Text('分 累计积分').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.BG).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            Text(this.summaryCount).fontSize(AppTypography.H3.size).fontWeight(FontWeight.Bold).fontColor(AppColor.CHART_BLUE);
            Text('条 记录条数').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.BG).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
        }
        .width('100%')
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(2) });

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 3}) {
          Column({ space: AppSpacing.SM }) {
            Text('减排趋势（' + this.periodLabel(this.period) + '）').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            LineChartView({ data: this.trendValues, labels: this.trendLabels }).margin({ top: AppSpacing.SM });
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
          Column({ space: AppSpacing.SM }) {
            Text('减排对比（柱状图）').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            BarChartView({ data: this.trendValues, labels: this.trendLabels, barColor: AppColor.PRIMARY_LIGHT }).margin({ top: AppSpacing.SM });
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 5}) {
          Column({ space: AppSpacing.SM }) {
            Text('类别占比（饼图）').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            PieChartView({ data: this.categoryValues, colors: this.categoryColors }).margin({ top: AppSpacing.SM });
            Row({ space: AppSpacing.MD }) {
              ForEach(this.legendData, (c: CategoryStat) => {
                Row({ space: AppSpacing.XS }) {
                  Circle({ width: 8, height: 8 }).fill(c.color);
                  Text(c.category).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
                }
              }, (c: CategoryStat) => c.category);
            }
            .width('100%').justifyContent(FlexAlign.Center).margin({ top: AppSpacing.SM });
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 6}) {
          Column({ space: AppSpacing.SM }) {
            Text('最近记录').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.recentList.length === 0) {
              Text('暂无记录').fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.SM });
            } else {
              ForEach(this.recentList, (r: CarbonRecord) => {
                Row() {
                  Text(r.category).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_INVERSE)
                    .backgroundColor(CarbonFactors.categoryColor(r.category)).padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS }).borderRadius(AppRadius.SM);
                  Text(r.name + ' ' + r.amount.toString() + r.unit).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT).layoutWeight(1).margin({ left: AppSpacing.SM });
                  Text(r.saved.toFixed(2) + ' kg').fontSize(AppTypography.BODY.size).fontColor(AppColor.PRIMARY);
                }.width('100%').padding({ top: AppSpacing.SM, bottom: AppSpacing.SM });
              }, (r: CarbonRecord) => r.id);
            }
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 7, marginBottom: AppSpacing.LG}) {
          Column({ space: AppSpacing.SM }) {
            Text('本地数据管理').fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            Row({ space: AppSpacing.SM }) {
              AppButton({ text: '导出 CSV', type: 'primary' }).layoutWeight(1).onClick(() => this.exportFile('csv'));
              AppButton({ text: '导出 JSON', type: 'secondary' }).layoutWeight(1).onClick(() => this.exportFile('json'));
            }.width('100%').margin({ top: AppSpacing.SM });
            AppButton({ text: '清空全部数据', type: 'ghost', fullWidth: true }).margin({ top: AppSpacing.SM }).onClick(() => this.confirmClear());
          }
        }
      }
      .width('100%').padding(AppSpacing.MD)
    }
    .width('100%').height('100%').backgroundColor(AppColor.BG).scrollBar(BarState.Off);
  }
}
