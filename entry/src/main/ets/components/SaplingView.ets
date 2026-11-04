import { AppMotion } from '../common/Theme';

/**
 * 碳小树可视化：按阶段切换 SVG，阶段变化时做一次轻微"生长"缩放。
 * 仅用 ArkUI 基础能力 + 本地 SVG，无外部依赖。
 *
 * 注意：属性不能叫 size / scale —— 与 CustomComponent 基类同名会编译失败。
 */
@Component
export struct SaplingView {
  @Prop @Watch('onStageChanged') stage: number;
  @Prop treeSize: number = 92;
  @Prop variant: string = 'mixed';
  @State zoom: number = 1;

  private onStageChanged(): void {
    if (AppMotion.reduceMotion()) {
      return;
    }
    this.zoom = 0.86;
    this.getUIContext().animateTo({ duration: 460, curve: Curve.EaseOut }, () => {
      this.zoom = 1;
    });
  }

  private mediaForStage(stage: number): Resource {
    switch (stage) {
      case 1: return $r('app.media.sapling_1');
      case 2: return $r('app.media.sapling_2');
      case 3: return $r('app.media.sapling_3');
      case 4: return $r('app.media.sapling_4');
      case 5: return $r('app.media.sapling_5');
      default: return $r('app.media.sapling_0');
    }
  }

  private mediaForVariant(): Resource {
    switch (this.variant) {
      case 'travel': return $r('app.media.accent_travel');
      case 'energy': return $r('app.media.accent_energy');
      case 'recycle': return $r('app.media.accent_recycle');
      case 'food': return $r('app.media.accent_food');
      default: return $r('app.media.accent_travel');
    }
  }

  build() {
    Stack() {
      Image(this.mediaForStage(this.stage))
        .width(this.treeSize)
        .height(this.treeSize)
        .objectFit(ImageFit.Contain);
      if (this.stage >= 2 && this.variant !== 'mixed') {
        Image(this.mediaForVariant())
          .width(this.treeSize)
          .height(this.treeSize)
          .objectFit(ImageFit.Contain)
          .opacity(0.96)
          .transition(TransitionEffect.OPACITY.animation({ duration: 320, curve: Curve.EaseOut }));
      }
    }
    .width(this.treeSize)
    .height(this.treeSize)
    .alignContent(Alignment.Center)
    .scale({ x: this.zoom, y: this.zoom })
    .animation({ duration: 460, curve: Curve.EaseOut });
  }
}
