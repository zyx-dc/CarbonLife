import { AppColor } from '../../common/Constants';
import { ChartAnimator, FONT_AXIS, FONT_TICK, lerp, maxOf, niceCeil } from './ChartCommon';

@Component
export struct BarChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop labels: string[] = [];
  @Prop barColor: string = AppColor.CHART_LINE;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private anim: ChartAnimator = new ChartAnimator();
  private ready: boolean = false;
  @State displayData: number[] = [];

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.displayData = this.data.map(() => 0);
    this.animateData();
  }

  aboutToDisappear(): void {
    this.anim.stop();
  }

  animateData(): void {
    const target: number[] = this.data.slice();
    this.anim.start(600, (e: number) => {
      this.displayData = target.map((v: number) => lerp(0, v, e));
      this.draw();
    });
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(180)
      .onReady(() => {
        this.ready = true;
        this.draw();
      })
  }

  draw(): void {
    if (!this.ready) {
      return;
    }
    const w: number = this.ctx.width;
    const h: number = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const left: number = 36;
    const right: number = 12;
    const top: number = 12;
    const bottom: number = 24;
    const plotW: number = w - left - right;
    const plotH: number = h - top - bottom;
    const max: number = niceCeil(maxOf(this.data));
    // 3 条水平网格线 + 刻度
    this.ctx.strokeStyle = AppColor.DIVIDER;
    this.ctx.lineWidth = 1;
    this.ctx.textAlign = 'right';
    this.ctx.font = FONT_AXIS;
    this.ctx.fillStyle = AppColor.TEXT_SUB;
    for (let g = 0; g <= 2; g++) {
      const gy: number = top + (plotH / 2) * g;
      this.ctx.beginPath();
      this.ctx.moveTo(left, gy);
      this.ctx.lineTo(left + plotW, gy);
      this.ctx.stroke();
      this.ctx.fillText((max * (1 - g / 2)).toFixed(1), left - 4, gy + 4);
    }
    const n: number = this.displayData.length;
    const slot: number = n > 0 ? plotW / n : plotW;
    const barW: number = slot * 0.5;
    this.ctx.textAlign = 'center';
    this.ctx.font = FONT_TICK;
    for (let i = 0; i < n; i++) {
      const v: number = this.displayData[i];
      const barH: number = max > 0 ? (v / max) * plotH : 0;
      const x: number = left + slot * i + (slot - barW) / 2;
      const y: number = top + plotH - barH;
      this.ctx.fillStyle = this.barColor;
      this.ctx.fillRect(x, y, barW, barH);
      this.ctx.fillStyle = AppColor.TEXT_SUB;
      if (i < this.labels.length) {
        this.ctx.fillText(this.labels[i], left + slot * i + slot / 2, top + plotH + 14);
      }
    }
  }
}
