import { AppColor } from '../common/Constants';
import { AppMotion, AppRadius, AppShadow, AppSpacing, AppTypography, Theme } from '../common/Theme';

export type ButtonType = 'primary' | 'secondary' | 'ghost';

@Component
export struct AppButton {
  @Prop text: ResourceStr = '';
  @Prop type: ButtonType = 'primary';
  @Prop icon: string = '';
  @Prop disabled: boolean = false;
  @Prop fullWidth: boolean = true;
  @Prop btnHeight: number = 48;
  @State pressed: boolean = false;

  private primaryFill(): string {
    return Theme.isDark() ? AppColor.SIGNAL : AppColor.PRIMARY;
  }

  private primaryFillDeep(): string {
    return Theme.isDark() ? AppColor.SIGNAL_DEEP : AppColor.PRIMARY_LIGHT;
  }

  private primaryText(): string {
    return Theme.isDark() ? AppColor.ON_SIGNAL : AppColor.TEXT_INVERSE;
  }

  private bgColor(): string {
    if (this.disabled) {
      return AppColor.DIVIDER;
    }
    if (this.type === 'primary') {
      return this.primaryFill();
    }
    if (this.type === 'ghost') {
      return 'transparent';
    }
    return AppColor.GLASS;
  }

  private textColor(): string {
    if (this.disabled) {
      return AppColor.TEXT_SUB;
    }
    if (this.type === 'primary') {
      return this.primaryText();
    }
    if (this.type === 'ghost') {
      return AppColor.PRIMARY;
    }
    return AppColor.TEXT;
  }

  private borderWidthValue(): number {
    return this.type === 'primary' || this.disabled ? 0 : 1;
  }

  private borderColorValue(): string {
    return this.type === 'ghost' ? AppColor.PRIMARY : AppColor.BORDER;
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
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor());
    }
    .width(this.fullWidth ? '100%' : 'auto')
    .height(this.btnHeight)
    .padding({ left: AppSpacing.LG, right: AppSpacing.LG })
    .backgroundColor(this.bgColor())
    .linearGradient({
      angle: 135,
      colors: (this.type === 'primary' && !this.disabled)
        ? [[this.primaryFill(), 0.0], [this.primaryFillDeep(), 1.0]]
        : [[this.bgColor(), 0.0], [this.bgColor(), 1.0]]
    })
    .borderRadius(AppRadius.MD)
    .borderWidth(this.borderWidthValue())
    .borderColor(this.borderColorValue())
    .shadow((this.type === 'primary' && !this.disabled) ? AppShadow.glow() : { radius: 0, color: '#00000000' })
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
