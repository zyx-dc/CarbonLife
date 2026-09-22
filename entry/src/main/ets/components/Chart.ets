import { AppColor } from '../common/Constants';
import { AppMotion } from '../common/Theme';

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

@Component
export struct BarChartView {
  @Prop @Watch('onDataChange') data: number[] = [];
  @Prop labels: string[] = [];
  @Prop barColor: string = AppColor.PRIMARY;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  @State displayData: number[] = [];

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.displayData = this.data.map(() => 0);
    this.animateData();
  }

  animateData(): void {
    if (AppMotion.reduceMotion()) {
      this.displayData = this.data.slice();
      this.draw();
      return;
    }
    const target = this.data.slice();
    const start = Date.now();
    const duration = 600;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      this.displayData = target.map((v: number, i: number) => lerp(0, v, t));
      this.draw();
      if (t < 1) {
        setTimeout(tick, 16);
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
    let max: number = 1;
    this.data.forEach((v: number) => {
      if (v > max) {
        max = v;
      }
    });
    this.ctx.strokeStyle = AppColor.DIVIDER;
    this.ctx.lineWidth = 1;
    this.ctx.beginPath();
    this.ctx.moveTo(left, top);
    this.ctx.lineTo(left, top + plotH);
    this.ctx.lineTo(left + plotW, top + plotH);
    this.ctx.stroke();
    this.ctx.fillStyle = AppColor.TEXT_SUB;
    this.ctx.font = '10px sans-serif';
    this.ctx.textAlign = 'right';
    this.ctx.fillText(max.toFixed(1), left - 4, top + 8);
    this.ctx.fillText('0', left - 4, top + plotH);
    const n: number = this.displayData.length;
    const slot: number = n > 0 ? plotW / n : plotW;
    const barW: number = slot * 0.5;
    this.ctx.textAlign = 'center';
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
  @State displayData: number[] = [];

  onDataChange(): void {
    this.animateData();
  }

  aboutToAppear(): void {
    this.displayData = this.data.map(() => 0);
    this.animateData();
  }

  animateData(): void {
    if (AppMotion.reduceMotion()) {
      this.displayData = this.data.slice();
      this.draw();
      return;
    }
    const target = this.data.slice();
    const start = Date.now();
    const duration = 700;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      this.displayData = target.map((v: number) => lerp(0, v, t));
      this.draw();
      if (t < 1) {
        setTimeout(tick, 16);
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
    let max: number = 1;
    this.data.forEach((v: number) => {
      if (v > max) {
        max = v;
      }
    });
    this.ctx.strokeStyle = AppColor.DIVIDER;
    this.ctx.lineWidth = 1;
    this.ctx.beginPath();
    this.ctx.moveTo(left, top);
    this.ctx.lineTo(left, top + plotH);
    this.ctx.lineTo(left + plotW, top + plotH);
    this.ctx.stroke();
    this.ctx.fillStyle = AppColor.TEXT_SUB;
    this.ctx.font = '10px sans-serif';
    this.ctx.textAlign = 'right';
    this.ctx.fillText(max.toFixed(1), left - 4, top + 8);
    this.ctx.fillText('0', left - 4, top + plotH);
    const n: number = this.displayData.length;
    if (n === 0) {
      return;
    }
    const step: number = n > 1 ? plotW / (n - 1) : 0;
    this.ctx.strokeStyle = AppColor.PRIMARY;
    this.ctx.lineWidth = 2;
    this.ctx.beginPath();
    for (let i = 0; i < n; i++) {
      const x: number = left + step * i;
      const y: number = top + plotH - (this.displayData[i] / max) * plotH;
      if (i === 0) {
        this.ctx.moveTo(x, y);
      } else {
        this.ctx.lineTo(x, y);
      }
    }
    this.ctx.stroke();
    this.ctx.textAlign = 'center';
    for (let i = 0; i < n; i++) {
      const x: number = left + step * i;
      const y: number = top + plotH - (this.displayData[i] / max) * plotH;
      this.ctx.beginPath();
      this.ctx.arc(x, y, 3, 0, Math.PI * 2);
      this.ctx.fillStyle = AppColor.PRIMARY;
      this.ctx.fill();
      this.ctx.fillStyle = AppColor.TEXT_SUB;
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
  @State sweep: number = 0;

  onDataChange(): void {
    this.animateSweep();
  }

  aboutToAppear(): void {
    this.animateSweep();
  }

  animateSweep(): void {
    if (AppMotion.reduceMotion()) {
      this.sweep = 1;
      this.draw();
      return;
    }
    const start = Date.now();
    const duration = 700;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      this.sweep = t;
      this.draw();
      if (t < 1) {
        setTimeout(tick, 16);
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
      this.ctx.font = '12px sans-serif';
      this.ctx.textAlign = 'center';
      this.ctx.fillText('暂无数据', cx, cy + 4);
      return;
    }
    let start: number = -Math.PI / 2;
    const totalAngle: number = Math.PI * 2 * this.sweep;
    let consumed: number = 0;
    for (let i = 0; i < this.data.length; i++) {
      const v: number = this.data[i];
      if (v <= 0) {
        continue;
      }
      const ratio = v / sum;
      const angle: number = ratio * totalAngle;
      this.ctx.beginPath();
      this.ctx.moveTo(cx, cy);
      this.ctx.arc(cx, cy, r, start, start + angle);
      this.ctx.closePath();
      this.ctx.fillStyle = i < this.colors.length ? this.colors[i] : AppColor.PRIMARY;
      this.ctx.fill();
      start += angle;
      consumed += angle;
    }
    this.ctx.beginPath();
    this.ctx.arc(cx, cy, r * 0.55, 0, Math.PI * 2);
    this.ctx.fillStyle = AppColor.CARD;
    this.ctx.fill();
  }
}
