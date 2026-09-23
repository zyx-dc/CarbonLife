import { PromptAction, UIContext } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { CarbonStore } from '../model/CarbonStore';
import { CarbonFactors } from '../model/CarbonFactors';
import { AppColor } from '../common/Constants';
import { CategoryStat, CarbonRecord, TrendPoint } from '../model/CarbonTypes';
import { DateUtil } from '../common/DateUtil';
import { BarChartView, LineChartView, PieChartView } from '../components/Chart';
import { AppCard } from '../components/AppCard';
import { AnimatedNumber } from '../components/AnimatedNumber';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppShadow, AppSpacing, AppTypography } from '../common/Theme';

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
  // 本周期内有值的桶数：< 2 时折线会失真，改用柱状
  @State trendNonZero: number = 0;
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
    let nonZero = 0;
    this.trendValues.forEach((v: number) => {
      if (v > 0) {
        nonZero += 1;
      }
    });
    this.trendNonZero = nonZero;
    const categoryStats: CategoryStat[] = store.savedByCategory();
    this.categoryValues = categoryStats.map((c: CategoryStat) => c.saved);
    this.categoryColors = categoryStats.map((c: CategoryStat) => c.color);
    this.legendData = categoryStats.filter((c: CategoryStat) => c.saved > 0);
    // 汇总卡片随所选周期聚合（本日/本周/本月/本年），与图表口径一致
    const recs: CarbonRecord[] = store.recordsInRange(this.periodStart(this.period), Date.now() + 1);
    let saved = 0;
    let points = 0;
    recs.forEach((r: CarbonRecord) => {
      saved += r.saved;
      points += r.points;
    });
    this.summarySaved = saved.toFixed(2);
    this.summaryPoints = points.toString();
    this.summaryCount = recs.length.toString();
    this.recentList = store.recentRecords(10);
  }

  exportFile(kind: string): void {
    let file: fs.File | null = null;
    try {
      const ctx = this.uiContext.getHostContext() as common.UIAbilityContext;
      const ext = kind === 'csv' ? '.csv' : '.json';
      const path = ctx.filesDir + '/carbon_export_' + Date.now().toString() + ext;
      const content = kind === 'csv' ? CarbonStore.get().exportCsv() : CarbonStore.get().exportJson();
      file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.writeSync(file.fd, content);
      this.promptAction.showToast({ message: '已导出到：' + path });
    } catch (e) {
      this.promptAction.showToast({ message: '导出失败' });
    } finally {
      if (file !== null) {
        try { fs.closeSync(file); } catch (err) { }
      }
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

  periodScopeLabel(p: string): string {
    if (p === 'week') return '本周';
    if (p === 'month') return '本月';
    if (p === 'year') return '本年';
    return '今日';
  }

  trendTitle(p: string): string {
    if (p === 'week') return '减排趋势 · 近 6 周';
    if (p === 'month') return '减排趋势 · 近 6 月';
    if (p === 'year') return '减排趋势 · 近 5 年';
    return '减排趋势 · 近 7 日';
  }

  periodStart(p: string): number {
    const now = Date.now();
    if (p === 'week') return DateUtil.startOfWeek(now);
    if (p === 'month') return DateUtil.startOfMonth(now);
    if (p === 'year') return DateUtil.startOfYear(now);
    return DateUtil.startOfDay(now);
  }

  @Builder
  emptyState(hint: string) {
    Column({ space: AppSpacing.SM }) {
      Image($r('app.media.ic_nav_dashboard'))
        .width(40)
        .height(40)
        .fillColor(AppColor.BORDER);
      Text(hint).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
    }
    .width('100%')
    .height(150)
    .justifyContent(FlexAlign.Center);
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Column({ space: AppSpacing.XS }) {
          Text('DASHBOARD').fontSize(AppTypography.SMALL.size).letterSpacing(2.5).fontColor(AppColor.TEXT_SUB);
          Text('数据看板').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        Row() {
          ForEach(['day', 'week', 'month', 'year'], (p: string) => {
            Text(this.periodLabel(p))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .fontSize(AppTypography.BODY.size)
              .fontWeight(this.period === p ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.period === p ? AppColor.ON_SIGNAL : AppColor.TEXT_SUB)
              .backgroundColor(this.period === p ? AppColor.SIGNAL : Color.Transparent)
              .borderRadius(AppRadius.SM)
              .padding({ top: AppSpacing.SM, bottom: AppSpacing.SM })
              .constraintSize({ minHeight: 44 })
              .shadow(this.period === p ? AppShadow.glow() : { radius: 0, color: '#00000000' })
              .onClick(() => this.period = p);
          }, (p: string) => p);
        }
        .width('100%')
        .padding(AppSpacing.XS)
        .backgroundColor(AppColor.GLASS)
        .backdropBlur(24)
        .borderRadius(AppRadius.MD)
        .borderWidth(1)
        .borderColor(AppColor.GLASS_BORDER)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(1) });

        Row({ space: AppSpacing.SM }) {
          Column({ space: AppSpacing.XS }) {
            AnimatedNumber({ value: parseFloat(this.summarySaved), decimals: 2, textSize: AppTypography.H3.size, textColor: AppColor.PRIMARY });
            Text('kg ' + this.periodScopeLabel(this.period) + '减排').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            AnimatedNumber({ value: parseFloat(this.summaryPoints), textSize: AppTypography.H3.size, textColor: AppColor.ACCENT });
            Text('分 ' + this.periodScopeLabel(this.period) + '积分').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            AnimatedNumber({ value: parseFloat(this.summaryCount), textSize: AppTypography.H3.size, textColor: AppColor.TEXT });
            Text('条 ' + this.periodScopeLabel(this.period) + '记录').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
        }
        .width('100%')
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(2) });

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 3}) {
          Column({ space: AppSpacing.SM }) {
            Text(this.trendTitle(this.period)).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.summaryCount === '0') {
              this.emptyState('该周期暂无记录');
            } else if (this.trendNonZero < 2) {
              // 稀疏数据用柱状更诚实（折线连接零点会制造「长期无排放」错觉）
              BarChartView({ data: this.trendValues, labels: this.trendLabels, barColor: AppColor.CHART_LINE }).margin({ top: AppSpacing.SM });
              Text('数据点较少，改用柱状展示').fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB).width('100%');
            } else {
              LineChartView({ data: this.trendValues, labels: this.trendLabels }).margin({ top: AppSpacing.SM });
            }
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
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
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 120 })
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);
  }
}
