import { AppColor } from '../common/Constants';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { BadgeDef } from '../model/CarbonTypes';
import { badgeNameRes, badgeDescRes } from '../common/Localize';

function badgeIcon(key: string): Resource {
  switch (key) {
    case 'b1': return $r('app.media.ic_badge_seed');
    case 'b2': return $r('app.media.ic_badge_travel');
    case 'b3': return $r('app.media.ic_badge_energy');
    case 'b4': return $r('app.media.ic_badge_recycle');
    case 'b5': return $r('app.media.ic_badge_meal');
    case 'b6': return $r('app.media.ic_badge_master');
    case 'b7': return $r('app.media.ic_badge_neutral');
    default: return $r('app.media.ic_badge_seed');
  }
}

@Component
export struct BadgeItem {
  @Prop badge: BadgeDef = { key: '', name: '', desc: '', icon: '', target: 0 };
  @Prop unlocked: boolean = false;
  @Prop index: number = 0;
  @State scaleVal: number = 0.8;
  @State opacityVal: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    const delay = AppMotion.staggerDelay(this.index);
    if (delay === 0) {
      this.scaleVal = 1;
      this.opacityVal = 1;
    } else {
      this.timerId = setTimeout(() => {
        this.scaleVal = 1;
        this.opacityVal = 1;
      }, delay);
    }
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Column({ space: AppSpacing.XS }) {
      Image(badgeIcon(this.badge.key))
        .width(32)
        .height(32)
        .fillColor(this.unlocked ? AppColor.PRIMARY : AppColor.TEXT_SUB)
        .opacity(this.unlocked ? 1 : 0.45);
      Text(badgeNameRes(this.badge.key, this.badge.name))
        .fontSize(AppTypography.CAPTION_MEDIUM.size)
        .fontWeight(AppTypography.CAPTION_MEDIUM.weight)
        .fontColor(this.unlocked ? AppColor.TEXT : AppColor.TEXT_SUB)
        .maxLines(1);
      Text(this.unlocked ? $r('app.string.badge_unlocked') : badgeDescRes(this.badge.key, this.badge.desc))
        .fontSize(AppTypography.SMALL.size)
        .fontColor(AppColor.TEXT_SUB)
        .maxLines(2)
        .textAlign(TextAlign.Center);
    }
    .width('30%')
    .padding(AppSpacing.MD)
    .backgroundColor(this.unlocked ? AppColor.PRIMARY_SOFT : AppColor.CARD)
    .borderRadius(AppRadius.MD)
    .borderWidth(0.5)
    .borderColor(AppColor.BORDER)
    .opacity(this.opacityVal)
    .scale({ x: this.scaleVal, y: this.scaleVal })
    .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE });
  }
}
