import { PromptAction, UIContext } from '@kit.ArkUI';
import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
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

  async exportFile(kind: string): Promise<void> {
    let file: fs.File | null = null;
    try {
      const ctx = this.uiContext.getHostContext() as common.UIAbilityContext;
      const ext = kind === 'csv' ? '.csv' : '.json';
      const content = kind === 'csv' ? CarbonStore.get().exportCsv() : CarbonStore.get().exportJson();
      // 用系统文档选择器保存到用户可访问的位置（而非沙箱 filesDir）
      const docPicker = new picker.DocumentViewPicker(ctx);
      const opt = new picker.DocumentSaveOptions();
      opt.newFileNames = ['carbon_export_' + Date.now().toString() + ext];
      const uris = await docPicker.save(opt);
      if (uris.length === 0) {
        return;
      }
      file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE);
      fs.writeSync(file.fd, content);
      this.promptAction.showToast({ message: $r('app.string.dashboard_exported') });
    } catch (e) {
      this.promptAction.showToast({ message: $r('app.string.dashboard_export_failed') });
    } finally {
      if (file !== null) {
        try { fs.closeSync(file); } catch (err) { }
      }
    }
  }

  async importFile(): Promise<void> {
    let file: fs.File | null = null;
    try {
      const ctx = this.uiContext.getHostContext() as common.UIAbilityContext;
      const docPicker = new picker.DocumentViewPicker(ctx);
      const opt = new picker.DocumentSelectOptions();
      opt.maxSelectNumber = 1;
      const uris = await docPicker.select(opt);
      if (uris.length === 0) {
        return;
      }
      file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      const readLen = fs.readSync(file.fd, buf);
      const bytes = new Uint8Array(buf.slice(0, readLen));
      const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
      const trimmed = text.trim();
      const isJson = trimmed.startsWith('[') || trimmed.startsWith('{');
      const added = isJson ? CarbonStore.get().importJson(text) : CarbonStore.get().importCsv(text);
      if (added < 0) {
        this.promptAction.showToast({ message: $r('app.string.dashboard_import_bad_format') });
      } else if (added === 0) {
        this.promptAction.showToast({ message: $r('app.string.dashboard_import_none') });
      } else {
        this.promptAction.showToast({ message: $r('app.string.dashboard_imported', added.toString()) });
        this.refreshData();
      }
    } catch (e) {
      this.promptAction.showToast({ message: $r('app.string.dashboard_import_failed') });
    } finally {
      if (file !== null) {
        try { fs.closeSync(file); } catch (err) { }
      }
    }
  }

  confirmClear(): void {
    this.uiContext.showAlertDialog({
      title: $r('app.string.dashboard_clear_title'),
      message: $r('app.string.dashboard_clear_message'),
      primaryButton: { value: $r('app.string.common_cancel'), action: () => {} },
      secondaryButton: { value: $r('app.string.dashboard_clear_confirm'), fontColor: AppColor.DANGER, action: () => {
        CarbonStore.get().clearAll();
        this.promptAction.showToast({ message: $r('app.string.dashboard_cleared') });
      }}
    });
  }

  periodLabel(p: string): Resource {
    if (p === 'week') return $r('app.string.dashboard_period_week');
    if (p === 'month') return $r('app.string.dashboard_period_month');
    if (p === 'year') return $r('app.string.dashboard_period_year');
    return $r('app.string.dashboard_period_day');
  }

  savedLabel(p: string): Resource {
    if (p === 'week') return $r('app.string.dashboard_saved_week');
    if (p === 'month') return $r('app.string.dashboard_saved_month');
    if (p === 'year') return $r('app.string.dashboard_saved_year');
    return $r('app.string.dashboard_saved_day');
  }

  pointsLabel(p: string): Resource {
    if (p === 'week') return $r('app.string.dashboard_points_week');
    if (p === 'month') return $r('app.string.dashboard_points_month');
    if (p === 'year') return $r('app.string.dashboard_points_year');
    return $r('app.string.dashboard_points_day');
  }

  countLabel(p: string): Resource {
    if (p === 'week') return $r('app.string.dashboard_count_week');
    if (p === 'month') return $r('app.string.dashboard_count_month');
    if (p === 'year') return $r('app.string.dashboard_count_year');
    return $r('app.string.dashboard_count_day');
  }

  trendTitle(p: string): Resource {
    if (p === 'week') return $r('app.string.dashboard_trend_week');
    if (p === 'month') return $r('app.string.dashboard_trend_month');
    if (p === 'year') return $r('app.string.dashboard_trend_year');
    return $r('app.string.dashboard_trend_day');
  }

  periodStart(p: string): number {
    const now = Date.now();
    if (p === 'week') return DateUtil.startOfWeek(now);
    if (p === 'month') return DateUtil.startOfMonth(now);
    if (p === 'year') return DateUtil.startOfYear(now);
    return DateUtil.startOfDay(now);
  }

  @Builder
  emptyState(hint: Resource) {
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
          Text($r('app.string.dashboard_title')).fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
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
            Text(this.savedLabel(this.period)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            AnimatedNumber({ value: parseFloat(this.summaryPoints), textSize: AppTypography.H3.size, textColor: AppColor.ACCENT });
            Text(this.pointsLabel(this.period)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
          Column({ space: AppSpacing.XS }) {
            AnimatedNumber({ value: parseFloat(this.summaryCount), textSize: AppTypography.H3.size, textColor: AppColor.TEXT });
            Text(this.countLabel(this.period)).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
          }.layoutWeight(1).padding({ top: AppSpacing.MD, bottom: AppSpacing.MD }).backgroundColor(AppColor.GLASS).borderWidth(1).borderColor(AppColor.GLASS_BORDER).borderRadius(AppRadius.MD).alignItems(HorizontalAlign.Center);
        }
        .width('100%')
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 })
        .animation({ duration: AppMotion.reduceMotion() ? 0 : 500, curve: AppMotion.EASE, delay: AppMotion.staggerDelay(2) });

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 3}) {
          Column({ space: AppSpacing.SM }) {
            Text(this.trendTitle(this.period)).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.summaryCount === '0') {
              this.emptyState($r('app.string.dashboard_empty'));
            } else if (this.trendNonZero < 2) {
              // 稀疏数据用柱状更诚实（折线连接零点会制造「长期无排放」错觉）
              BarChartView({ data: this.trendValues, labels: this.trendLabels, barColor: AppColor.CHART_LINE }).margin({ top: AppSpacing.SM });
              Text($r('app.string.dashboard_sparse')).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB).width('100%');
            } else {
              LineChartView({ data: this.trendValues, labels: this.trendLabels }).margin({ top: AppSpacing.SM });
            }
          }
        }

                  AppCard({ cardPadding: AppSpacing.MD , enter: this.ready, enterDelayIndex: 4}) {
          Column({ space: AppSpacing.SM }) {
            Text($r('app.string.dashboard_category_pie')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
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
            Text($r('app.string.dashboard_recent')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            if (this.recentList.length === 0) {
              Text($r('app.string.dashboard_no_records')).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).margin({ top: AppSpacing.SM });
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
            Text($r('app.string.dashboard_data_mgmt')).fontSize(AppTypography.H4.size).fontWeight(AppTypography.H4.weight).fontColor(AppColor.TEXT).width('100%');
            Row({ space: AppSpacing.SM }) {
              AppButton({ text: $r('app.string.dashboard_export_csv'), type: 'primary' }).layoutWeight(1).onClick(() => this.exportFile('csv'));
              AppButton({ text: $r('app.string.dashboard_export_json'), type: 'secondary' }).layoutWeight(1).onClick(() => this.exportFile('json'));
            }.width('100%').margin({ top: AppSpacing.SM });
            AppButton({ text: $r('app.string.dashboard_import'), type: 'secondary', fullWidth: true }).margin({ top: AppSpacing.SM }).onClick(() => this.importFile());
            AppButton({ text: $r('app.string.dashboard_clear_all'), type: 'ghost', fullWidth: true }).margin({ top: AppSpacing.SM }).onClick(() => this.confirmClear());
          }
        }
      }
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 120 })
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off);
  }
}
