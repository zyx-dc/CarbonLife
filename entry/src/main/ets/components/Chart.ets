import { AppColor } from '../common/Constants';
import { AppMotion, AppTypography } from '../common/Theme';

// Canvas 文本统一走排版 token；单位用 vp（px 在本设备是物理像素，会渲染得极小）
const FONT_AXIS: string = AppTypography.CAPTION.size.toString() + 'vp sans-serif'; // 轴数值
const FONT_TICK: string = AppTypography.SMALL.size.toString() + 'vp sans-serif';   // 横轴刻度
const FONT_SUB: string = AppTypography.CAPTION.size.toString() + 'vp sans-serif';
const FONT_CENTER: string = 'bold ' + AppTypography.H2.size.toString() + 'vp sans-serif';

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

// easeOutCubic：让动画收尾更「有弹性」，比线性更耐看
function easeOut(t: number): number {
  return 1 - Math.pow(1 - t, 3);
}

// 把数据最大值「向上取整」到一个好看的刻度上限（1/1.5/2/2.5/3/4/5/6/8/10 × 10^n）
function niceCeil(v: number): number {
  if (v <= 0) {
    return 1;
  }
  const exp: number = Math.floor(Math.log10(v));
  const base: number = Math.pow(10, exp);
  const n: number = v / base;
  const steps: number[] = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10];
  for (let i = 0; i < steps.length; i++) {
    if (n <= steps[i]) {
      return steps[i] * base;
    }
  }
  return 10 * base;
}

// 给十六进制色追加透明度，用于渐变/辉光；非 hex 原样返回
function withAlpha(color: string, alpha: number): string {
  if (color.charAt(0) === '#') {
    const r = parseInt(color.substring(1, 3), 16);
    const g = parseInt(color.substring(3, 5), 16);
    const b = parseInt(color.substring(5, 7), 16);
    return 'rgba(' + r.toString() + ',' + g.toString() + ',' + b.toString() + ',' + alpha.toString() + ')';
  }
  return color;
}

@Component
export struct BarChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop labels: string[] = [];
  @Prop barColor: string = AppColor.CHART_LINE;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private timerId: number = -1;
  @State displayData: number[] = [];

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.displayData = this.data.map(() => 0);
    this.animateData();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  animateData(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (AppMotion.reduceMotion()) {
      this.displayData = this.data.slice();
      this.draw();
      return;
    }
    const target: number[] = this.data.slice();
    const start = Date.now();
    const duration = 600;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      const e = easeOut(t);
      this.displayData = target.map((v: number) => lerp(0, v, e));
      this.draw();
      if (t < 1) {
        this.timerId = setTimeout(tick, 16);
      } else {
        this.timerId = -1;
      }
    };
    tick();
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
    let dataMax: number = 0;
    this.data.forEach((v: number) => {
      if (v > dataMax) {
        dataMax = v;
      }
    });
    const max: number = niceCeil(dataMax);
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

@Component
export struct LineChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop labels: string[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private timerId: number = -1;
  @State progress: number = 0;

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.animateData();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  animateData(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (AppMotion.reduceMotion()) {
      this.progress = 1;
      this.draw();
      return;
    }
    this.progress = 0;
    const start = Date.now();
    const duration = 900;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      this.progress = easeOut(t);
      this.draw();
      if (t < 1) {
        this.timerId = setTimeout(tick, 16);
      } else {
        this.timerId = -1;
      }
    };
    tick();
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
    let dataMax: number = 0;
    this.data.forEach((v: number) => {
      if (v > dataMax) {
        dataMax = v;
      }
    });
    const max: number = niceCeil(dataMax);
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

@Component
export struct PieChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop colors: string[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private timerId: number = -1;
  @State sweep: number = 0;

  onDataChange(): void {
    this.animateSweep();
  }

  aboutToAppear(): void {
    this.animateSweep();
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  animateSweep(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (AppMotion.reduceMotion()) {
      this.sweep = 1;
      this.draw();
      return;
    }
    this.sweep = 0;
    const start = Date.now();
    const duration = 800;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      this.sweep = easeOut(t);
      this.draw();
      if (t < 1) {
        this.timerId = setTimeout(tick, 16);
      } else {
        this.timerId = -1;
      }
    };
    tick();
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
      this.ctx.fillText(getContext(this).resourceManager.getStringSync($r('app.string.chart_no_data')), cx, cy + 4);
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
    this.ctx.fillText(getContext(this).resourceManager.getStringSync($r('app.string.chart_kg_total')), cx, cy + 18);
  }
}
