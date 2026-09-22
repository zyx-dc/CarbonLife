import { AppColor } from '../common/Constants';
import { AppMotion, AppRadius, AppSpacing, AppTypography, Theme } from '../common/Theme';

export type ButtonType = 'primary' | 'secondary' | 'ghost';

@Component
export struct AppButton {
  @Prop text: string = '';
  @Prop type: ButtonType = 'primary';
  @Prop icon: string = '';
  @Prop disabled: boolean = false;
  @Prop fullWidth: boolean = true;
  @Prop btnHeight: number = 48;
  @State pressed: boolean = false;

  private bgColor(): string {
    if (this.disabled) {
      return AppColor.DIVIDER;
    }
    if (this.type === 'primary') {
      return AppColor.PRIMARY;
    }
    if (this.type === 'ghost') {
      return 'transparent';
    }
    return AppColor.PRIMARY_SOFT;
  }

  private textColor(): string {
    if (this.disabled) {
      return AppColor.TEXT_SUB;
    }
    if (this.type === 'primary') {
      return Theme.current().textInverse;
    }
    return AppColor.PRIMARY;
  }

  private borderWidthValue(): number {
    return this.type === 'ghost' ? 1 : 0;
  }

  build() {
    Row({ space: 6 }) {
      if (this.icon !== '') {
        Text(this.icon)
          .fontSize(AppTypography.BODY_MEDIUM.size)
          .fontColor(this.textColor());
      }
      Text(this.text)
        .fontSize(AppTypography.BODY_MEDIUM.size)
        .fontWeight(AppTypography.BODY_MEDIUM.weight)
        .fontColor(this.textColor());
    }
    .width(this.fullWidth ? '100%' : 'auto')
    .height(this.btnHeight)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .backgroundColor(this.bgColor())
    .borderRadius(AppRadius.MD)
    .borderWidth(this.borderWidthValue())
    .borderColor(AppColor.PRIMARY)
    .justifyContent(FlexAlign.Center)
    .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
    .opacity(this.disabled ? 0.6 : 1)
    .animation(AppMotion.pressOptions())
    .onTouch((event: TouchEvent) => {
      if (this.disabled) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    });
  }
}
