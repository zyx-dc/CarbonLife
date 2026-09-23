import { AppMotion } from '../common/Theme';
import { AppColor } from '../common/Constants';

/**
 * 数字滚动：数值变化时以 easeOutCubic 从当前值滚到目标值。
 * - 受 AppMotion.reduceMotion() 控制：减弱动效时直接落终值。
 * - 与旧实现（静态字符串）相比，让「今日减排 / 积分余额」等关键读数有生命感。
 */
@Component
export struct AnimatedNumber {
  @Prop @Watch('onValueChange') value: number = 0;
  @Prop decimals: number = 0;
  @Prop prefix: string = '';
  @Prop suffix: string = '';
  @Prop textSize: number = 24;
  @Prop textWeight: FontWeight = FontWeight.Bold;
  @Prop textColor: string = AppColor.TEXT;
  @State shown: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.animateTo(this.value);
  }

  aboutToDisappear(): void {
    this.clearTimer();
  }

  onValueChange(): void {
    this.animateTo(this.value);
  }

  private clearTimer(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  private animateTo(target: number): void {
    this.clearTimer();
    if (AppMotion.reduceMotion() || Math.abs(target - this.shown) < 0.0001) {
      this.shown = target;
      return;
    }
    const from = this.shown;
    const delta = target - from;
    const start = Date.now();
    const duration = 700;
    const tick = () => {
      const t = Math.min(1, (Date.now() - start) / duration);
      const eased = 1 - Math.pow(1 - t, 3);
      this.shown = from + delta * eased;
      if (t < 1) {
        this.timerId = setTimeout(tick, 16);
      } else {
        this.shown = target;
        this.timerId = -1;
      }
    };
    tick();
  }

  build() {
    Text(this.prefix + this.shown.toFixed(this.decimals) + this.suffix)
      .fontSize(this.textSize)
      .fontWeight(this.textWeight)
      .fontColor(this.textColor);
  }
}
