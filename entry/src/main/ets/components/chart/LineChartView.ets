import { AppColor } from '../../common/Constants';
import { ChartAnimator, FONT_AXIS, FONT_TICK, lerp, maxOf, niceCeil, withAlpha } from './ChartCommon';

@Component
export struct LineChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop labels: string[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private anim: ChartAnimator = new ChartAnimator();
  private ready: boolean = false;
  @State progress: number = 0;

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.animateData();
  }

  aboutToDisappear(): void {
    this.anim.stop();
  }

  animateData(): void {
    this.anim.start(900, (e: number) => {
      this.progress = e;
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
    const right: number = 20;
    const top: number = 12;
    const bottom: number = 24;
    const plotW: number = w - left - right;
    const plotH: number = h - top - bottom;
    const max: number = niceCeil(maxOf(this.data));
    this.ctx.strokeStyle = AppColor.DIVIDER;
    this.ctx.lineWidth = 1;
    for (let g = 1; g <= 3; g++) {
      const gy: number = top + plotH - (plotH * g / 4);
      this.ctx.beginPath();
      this.ctx.moveTo(left, gy);
      this.ctx.lineTo(left + plotW, gy);
      this.ctx.stroke();
    }
    this.ctx.beginPath();
    this.ctx.moveTo(left, top);
    this.ctx.lineTo(left, top + plotH);
    this.ctx.lineTo(left + plotW, top + plotH);
    this.ctx.stroke();
    this.ctx.fillStyle = AppColor.TEXT_SUB;
    this.ctx.font = FONT_AXIS;
    this.ctx.textAlign = 'right';
    this.ctx.fillText(max.toFixed(1), left - 4, top + 8);
    this.ctx.fillText('0', left - 4, top + plotH);
    this.ctx.textAlign = 'left';
    this.ctx.fillText('kg', left + 6, top + 8);

    const n: number = this.data.length;
    if (n === 0) {
      return;
    }
    const step: number = n > 1 ? plotW / (n - 1) : 0;
    // 从左向右揭示：只在 revealX 之前绘制，右端做插值
    const revealX: number = left + plotW * this.progress;
    const rx: number[] = [];
    const ry: number[] = [];
    for (let i = 0; i < n; i++) {
      const x: number = left + step * i;
      const y: number = top + plotH - (this.data[i] / max) * plotH;
      if (x <= revealX) {
        rx.push(x);
        ry.push(y);
      } else {
        if (i > 0) {
          const x0: number = left + step * (i - 1);
          const y0: number = top + plotH - (this.data[i - 1] / max) * plotH;
          const f: number = (revealX - x0) / (x - x0);
          rx.push(revealX);
          ry.push(lerp(y0, y, f));
        }
        break;
      }
    }
    const m: number = rx.length;
    if (m === 0) {
      return;
    }
    // 面积渐变
    const area = this.ctx.createLinearGradient(0, top, 0, top + plotH);
    area.addColorStop(0, withAlpha(AppColor.CHART_LINE, 0.32));
    area.addColorStop(1, withAlpha(AppColor.CHART_LINE, 0.0));
    this.ctx.beginPath();
    this.ctx.moveTo(rx[0], top + plotH);
    for (let i = 0; i < m; i++) {
      this.ctx.lineTo(rx[i], ry[i]);
    }
    this.ctx.lineTo(rx[m - 1], top + plotH);
    this.ctx.closePath();
    this.ctx.fillStyle = area;
    this.ctx.fill();
    // 折线（品牌绿实线，与填充/点标记同色系）
    this.ctx.strokeStyle = AppColor.CHART_LINE;
    this.ctx.lineWidth = 2;
    this.ctx.lineJoin = 'round';
    this.ctx.beginPath();
    for (let i = 0; i < m; i++) {
      if (i === 0) {
        this.ctx.moveTo(rx[i], ry[i]);
      } else {
        this.ctx.lineTo(rx[i], ry[i]);
      }
    }
    this.ctx.stroke();
    // 数据点 + 末端辉光
    this.ctx.textAlign = 'center';
    for (let i = 0; i < m; i++) {
      const isTip: boolean = i === m - 1;
      if (isTip) {
        this.ctx.beginPath();
        this.ctx.arc(rx[i], ry[i], 7, 0, Math.PI * 2);
        this.ctx.fillStyle = withAlpha(AppColor.CHART_LINE, 0.22);
        this.ctx.fill();
      }
      this.ctx.beginPath();
      this.ctx.arc(rx[i], ry[i], isTip ? 4 : 3, 0, Math.PI * 2);
      this.ctx.fillStyle = AppColor.CHART_LINE;
      this.ctx.fill();
    }
    // 坐标标签：密集序列隔点显示；末端右对齐避免超出画布被裁切
    this.ctx.font = FONT_TICK;
    const lstep: number = n >= 7 ? 2 : 1;
    for (let i = 0; i < n; i++) {
      if (i % lstep !== 0 && i !== n - 1) {
        continue;
      }
      const x: number = left + step * i;
      this.ctx.fillStyle = AppColor.TEXT_SUB;
      this.ctx.textAlign = (i === n - 1) ? 'right' : 'center';
      if (i < this.labels.length) {
        this.ctx.fillText(this.labels[i], x, top + plotH + 14);
      }
    }
  }
}
