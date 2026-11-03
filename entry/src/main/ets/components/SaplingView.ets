import { AppMotion } from '../common/Theme';

/**
 * 碳小树可视化：阶段（长多大）× 形态（长成什么样）。
 *
 * - 阶段：0 种子 / 1 幼苗 / 2 小树 / 3 开花 / 4 结果 / 5 常青
 * - 形态：mixed / travel / recycle / food / energy，由行为结构决定（见 Sapling.variantOf）
 * - 形态或阶段变化时做一次交叉淡入，避免"啪"地换图
 * - 素材：tree_<variant>_<stage>.svg，由 OpenDesign 生成（见 docs/tasks/tree-concept/）
 *
 * 设计约束：108px 下靠"主色 + 大轮廓"识别，细节不参与识别。
 */
@Component
export struct SaplingView {
  @Prop @Watch('onTreeChanged') stage: number;
  @Prop @Watch('onTreeChanged') variant: string;
  @Prop treeSize: number = 92;

  @State curStage: number = 0;
  @State curVariant: string = 'mixed';
  @State prevStage: number = 0;
  @State prevVariant: string = 'mixed';
  @State fade: number = 1;
  @State zoom: number = 1;

  aboutToAppear(): void {
    this.curStage = this.stage;
    this.curVariant = this.variant;
    this.prevStage = this.stage;
    this.prevVariant = this.variant;
  }

  private onTreeChanged(): void {
    if (this.stage === this.curStage && this.variant === this.curVariant) {
      return;
    }
    const stageChanged: boolean = this.stage !== this.curStage;
    this.prevStage = this.curStage;
    this.prevVariant = this.curVariant;
    this.curStage = this.stage;
    this.curVariant = this.variant;

    if (AppMotion.reduceMotion()) {
      this.fade = 1;
      return;
    }

    // 形态切换：交叉淡入；阶段提升：额外做一次轻微"抽长"
    this.fade = 0;
    this.getUIContext().animateTo({ duration: 360, curve: Curve.EaseOut }, () => {
      this.fade = 1;
    });
    if (stageChanged) {
      this.zoom = 0.88;
      this.getUIContext().animateTo({ duration: 520, curve: Curve.EaseOut }, () => {
        this.zoom = 1;
      });
    }
  }

  private mediaFor(stage: number, variant: string): Resource {
    if (variant === 'travel') {
      switch (stage) {
        case 0: return $r('app.media.tree_travel_0');
        case 1: return $r('app.media.tree_travel_1');
        case 2: return $r('app.media.tree_travel_2');
        case 3: return $r('app.media.tree_travel_3');
        case 4: return $r('app.media.tree_travel_4');
        default: return $r('app.media.tree_travel_5');
      }
    }
    if (variant === 'recycle') {
      switch (stage) {
        case 0: return $r('app.media.tree_recycle_0');
        case 1: return $r('app.media.tree_recycle_1');
        case 2: return $r('app.media.tree_recycle_2');
        case 3: return $r('app.media.tree_recycle_3');
        case 4: return $r('app.media.tree_recycle_4');
        default: return $r('app.media.tree_recycle_5');
      }
    }
    if (variant === 'food') {
      switch (stage) {
        case 0: return $r('app.media.tree_food_0');
        case 1: return $r('app.media.tree_food_1');
        case 2: return $r('app.media.tree_food_2');
        case 3: return $r('app.media.tree_food_3');
        case 4: return $r('app.media.tree_food_4');
        default: return $r('app.media.tree_food_5');
      }
    }
    if (variant === 'energy') {
      switch (stage) {
        case 0: return $r('app.media.tree_energy_0');
        case 1: return $r('app.media.tree_energy_1');
        case 2: return $r('app.media.tree_energy_2');
        case 3: return $r('app.media.tree_energy_3');
        case 4: return $r('app.media.tree_energy_4');
        default: return $r('app.media.tree_energy_5');
      }
    }
    switch (stage) {
      case 0: return $r('app.media.tree_mixed_0');
      case 1: return $r('app.media.tree_mixed_1');
      case 2: return $r('app.media.tree_mixed_2');
      case 3: return $r('app.media.tree_mixed_3');
      case 4: return $r('app.media.tree_mixed_4');
      default: return $r('app.media.tree_mixed_5');
    }
  }

  build() {
    Stack() {
      Image(this.mediaFor(this.prevStage, this.prevVariant))
        .width(this.treeSize)
        .height(this.treeSize)
        .objectFit(ImageFit.Contain)
        .opacity(1 - this.fade);
      Image(this.mediaFor(this.curStage, this.curVariant))
        .width(this.treeSize)
        .height(this.treeSize)
        .objectFit(ImageFit.Contain)
        .opacity(this.fade);
    }
    .width(this.treeSize)
    .height(this.treeSize)
    .alignContent(Alignment.Center)
    .scale({ x: this.zoom, y: this.zoom });
  }
}
