import { AppMotion, AppTypography } from '../../common/Theme';

/**
 * 图表公共能力：字体、数学工具、入场动画器。
 * 三个图表组件（柱 / 折线 / 饼）共用，避免各自重复实现定时器与缓动。
 */

// Canvas 文本统一走排版 token；单位用 vp（px 在本设备是物理像素，会渲染得极小）
export const FONT_AXIS: string = AppTypography.CAPTION.size.toString() + 'vp sans-serif'; // 轴数值
export const FONT_TICK: string = AppTypography.SMALL.size.toString() + 'vp sans-serif';   // 横轴刻度
export const FONT_SUB: string = AppTypography.CAPTION.size.toString() + 'vp sans-serif';
export const FONT_CENTER: string = 'bold ' + AppTypography.H2.size.toString() + 'vp sans-serif';

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

// easeOutCubic：让动画收尾更「有弹性」，比线性更耐看
export function easeOut(t: number): number {
  return 1 - Math.pow(1 - t, 3);
}

// 数据序列最大值（三处图表共用）
export function maxOf(data: number[]): number {
  let max: number = 0;
  data.forEach((v: number) => {
    if (v > max) {
      max = v;
    }
  });
  return max;
}

// 把数据最大值「向上取整」到一个好看的刻度上限（1/1.5/2/2.5/3/4/5/6/8/10 × 10^n）
export function niceCeil(v: number): number {
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
export function withAlpha(color: string, alpha: number): string {
  if (color.charAt(0) === '#') {
    const r = parseInt(color.substring(1, 3), 16);
    const g = parseInt(color.substring(3, 5), 16);
    const b = parseInt(color.substring(5, 7), 16);
    return 'rgba(' + r.toString() + ',' + g.toString() + ',' + b.toString() + ',' + alpha.toString() + ')';
  }
  return color;
}

/**
 * 图表入场动画器。
 * 统一负责：定时器生命周期、easeOut 缓动、以及「减弱动效」时直接落到终值。
 * 组件侧只需在回调里更新 @State 并重绘。
 */
export class ChartAnimator {
  private timerId: number = -1;

  /**
   * 在 duration(ms) 内以 0→1 调用 onFrame(eased)；重复调用会先停掉上一轮。
   * 开启「减弱动效」时只调用一次 onFrame(1)。
   */
  start(duration: number, onFrame: (eased: number) => void): void {
    this.stop();
    if (AppMotion.reduceMotion()) {
      onFrame(1);
      return;
    }
    const startTs: number = Date.now();
    const tick = () => {
      const t: number = Math.min(1, (Date.now() - startTs) / duration);
      onFrame(easeOut(t));
      if (t < 1) {
        this.timerId = setTimeout(tick, 16);
      } else {
        this.timerId = -1;
      }
    };
    tick();
  }

  stop(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }
}
