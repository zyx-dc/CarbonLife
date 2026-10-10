import { AppColor } from '../common/Constants';

/**
 * 轻量「吸附」滑杆（自绘）。
 *
 * 为什么不用系统 Slider：本设备（HarmonyOS NEXT 模拟器 / API 26）上，系统 Slider 的
 * 滑块会渲染出一层多余的「灰色方块 + 浅色圆环」底衬，且不受 blockColor / blockStyle /
 * trackThickness / hoverEffect(None) / focusable(false) / blockBorderWidth(0) 影响。
 * 因此改为自绘：轨道 + 已选段 + 圆形滑块，行为与 Slider 对齐（min / max / step 吸附）。
 */
@Component
export struct RangeSlider {
  @Prop value: number = 0;
  @Prop min: number = 0;
  @Prop max: number = 100;
  @Prop step: number = 1;
  @Prop trackHeight: number = 8;
  @Prop blockSize: number = 24;
  /** 拖动/点击过程中值变化时回调（已按 step 吸附） */
  onChange: (value: number) => void = () => {};
  /** 一次操作结束（抬手）时回调，用于做回弹等反馈 */
  onChangeEnd: () => void = () => {};

  @State private trackW: number = 0;

  /** 当前值在 [min, max] 中的比例 [0, 1] */
  private ratio(): number {
    const span: number = this.max - this.min;
    if (span <= 0) {
      return 0;
    }
    return Math.min(1, Math.max(0, (this.value - this.min) / span));
  }

  /** 滑块可移动的距离（容器宽度 - 滑块直径） */
  private usableW(): number {
    return Math.max(1, this.trackW - this.blockSize);
  }

  private blockOffset(): number {
    return this.ratio() * this.usableW();
  }

  /**
   * 已选段宽度：从轨道左端画到滑块**圆心**（滑块自身覆盖到圆心，视觉上「骑」在深色段末端）。
   * 恰好处于最小值时不画，避免滑块左侧冒出一小截深色。
   */
  private fillW(): number {
    const offset: number = this.blockOffset();
    if (offset <= 0.5) {
      return 0;
    }
    return Math.min(this.trackW, offset + this.blockSize / 2);
  }

  /** 把 x（相对组件左端，vp）换算为吸附后的值 */
  private snapFromX(x: number): number {
    const span: number = this.max - this.min;
    const st: number = this.step > 0 ? this.step : 1;
    const raw: number = this.min + (x - this.blockSize / 2) / this.usableW() * span;
    const snapped: number = Math.round((raw - this.min) / st) * st + this.min;
    const clamped: number = Math.max(this.min, Math.min(this.max, snapped));
    // 消除浮点误差（例如 step=0.5 时避免 1.4999999）
    return Math.round(clamped / st) * st;
  }

  private applyX(x: number): void {
    const next: number = this.snapFromX(x);
    if (next !== this.value) {
      this.onChange(next);
    }
  }

  build() {
    // 注意：ArkUI 的 Alignment.Start 是「左 + 垂直居中」，会把轨道与滑块错开 7vp；
    // 这里要用 TopStart（左上），下面的 offset(y) 才是相对顶部的偏移。
    Stack({ alignContent: Alignment.TopStart }) {
      // 轨道
      Row()
        .width('100%')
        .height(this.trackHeight)
        .borderRadius(this.trackHeight / 2)
        .backgroundColor(AppColor.DIVIDER)
        .offset({ y: (this.blockSize - this.trackHeight) / 2 });
      // 已选段：左端圆角、右端直角 —— 与圆形滑块贴合，避免交界处露出轨道底色
      Row()
        .width(this.fillW())
        .height(this.trackHeight)
        .borderRadius({
          topLeft: this.trackHeight / 2,
          bottomLeft: this.trackHeight / 2,
          topRight: 0,
          bottomRight: 0
        })
        .backgroundColor(AppColor.PRIMARY)
        .offset({ y: (this.blockSize - this.trackHeight) / 2 });
      // 滑块：底色描边让它从轨道上「浮」起来
      Column()
        .width(this.blockSize)
        .height(this.blockSize)
        .borderRadius(this.blockSize / 2)
        .backgroundColor(AppColor.PRIMARY)
        .borderWidth(2)
        .borderColor(AppColor.CARD)
        .offset({ x: this.blockOffset() })
        .id('rs_block');
    }
    .width('100%')
    .height(this.blockSize)
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      this.trackW = newValue.width as number;
    })
    .onClick((event: ClickEvent) => {
      this.applyX(event.x);
      this.onChangeEnd();
    })
    .gesture(
      PanGesture({ distance: 0 })
        .onActionStart((event: GestureEvent) => {
          this.applyX(event.fingerList[0].localX);
        })
        .onActionUpdate((event: GestureEvent) => {
          this.applyX(event.fingerList[0].localX);
        })
        .onActionEnd(() => {
          this.onChangeEnd();
        })
    );
  }
}
