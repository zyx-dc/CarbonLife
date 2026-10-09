import { AppColor } from '../../common/Constants';
import { ChartAnimator, FONT_CENTER, FONT_SUB, FONT_TICK } from './ChartCommon';

@Component
export struct PieChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop colors: string[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private anim: ChartAnimator = new ChartAnimator();
  private ready: boolean = false;
  @State sweep: number = 0;

  onDataChange(): void {
    this.animateSweep();
  }

  aboutToAppear(): void {
    this.animateSweep();
  }

  aboutToDisappear(): void {
    this.anim.stop();
  }

  animateSweep(): void {
    this.anim.start(800, (e: number) => {
      this.sweep = e;
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
    const cx: number = w / 2;
    const cy: number = h / 2;
    const r: number = Math.min(w, h) / 2 - 16;
    let sum: number = 0;
    this.data.forEach((v: number) => {
      sum += v;
    });
    if (sum <= 0) {
      this.ctx.beginPath();
      this.ctx.arc(cx, cy, r, 0, Math.PI * 2);
      this.ctx.fillStyle = AppColor.DIVIDER;
      this.ctx.fill();
      this.ctx.fillStyle = AppColor.TEXT_SUB;
      this.ctx.font = FONT_SUB;
      this.ctx.textAlign = 'center';
      const host = this.getUIContext().getHostContext();
      const noData: string = host !== undefined ? host.resourceManager.getStringSync($r('app.string.chart_no_data').id) : '';
      this.ctx.fillText(noData, cx, cy + 4);
      return;
    }
    const gap: number = 0.03;
    let start: number = -Math.PI / 2;
    const totalAngle: number = Math.PI * 2 * this.sweep;
    let consumed: number = 0;
    for (let i = 0; i < this.data.length; i++) {
      const v: number = this.data[i];
      if (v <= 0) {
        continue;
      }
      const ratio = v / sum;
      const full: number = ratio * Math.PI * 2;
      const remaining: number = totalAngle - consumed;
      if (remaining <= 0) {
        break;
      }
      const seg: number = Math.min(full, remaining);
      const drawSeg: number = seg > gap ? seg - gap : seg;
      // 用三角函数手工描点成扇形：规避部分 Canvas 对接近 2π 单段弧的渲染异常
      const steps: number = Math.max(2, Math.ceil(drawSeg / 0.15));
      this.ctx.beginPath();
      this.ctx.moveTo(cx, cy);
      for (let s = 0; s <= steps; s++) {
        const a: number = start + drawSeg * (s / steps);
        this.ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
      }
      this.ctx.closePath();
      this.ctx.fillStyle = i < this.colors.length ? this.colors[i] : AppColor.PRIMARY;
      this.ctx.fill();
      start += full;
      consumed += seg;
    }
    // 中心挖空 + 合计
    this.ctx.beginPath();
    this.ctx.arc(cx, cy, r * 0.58, 0, Math.PI * 2);
    this.ctx.fillStyle = AppColor.CARD;
    this.ctx.fill();
    this.ctx.fillStyle = AppColor.TEXT;
    this.ctx.font = FONT_CENTER;
    this.ctx.textAlign = 'center';
    this.ctx.fillText(sum.toFixed(1), cx, cy + 2);
    this.ctx.fillStyle = AppColor.TEXT_SUB;
    this.ctx.font = FONT_TICK;
    const hostTotal = this.getUIContext().getHostContext();
    const kgTotal: string = hostTotal !== undefined ? hostTotal.resourceManager.getStringSync($r('app.string.chart_kg_total').id) : '';
    this.ctx.fillText(kgTotal, cx, cy + 18);
  }
}
