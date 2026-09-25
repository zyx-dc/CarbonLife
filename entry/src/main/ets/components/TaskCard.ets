import { AppColor } from '../common/Constants';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { DailyTask } from '../model/CarbonTypes';
import { taskNameRes, taskDescRes } from '../common/Localize';

@Component
export struct TaskCard {
  @Prop task: DailyTask = { key: '', name: '', desc: '', points: 0 };
  @Prop done: boolean = false;
  @Prop index: number = 0;
  @State pressed: boolean = false;
  @State visible: boolean = false;
  private timerId: number = -1;

  aboutToAppear(): void {
    const delay = AppMotion.staggerDelay(this.index);
    if (delay === 0) {
      this.visible = true;
    } else {
      this.timerId = setTimeout(() => {
        this.visible = true;
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
    Row({ space: AppSpacing.SM }) {
      Text(this.done ? '✓' : '')
        .width(22)
        .height(22)
        .fontSize(14)
        .fontColor(AppColor.TEXT_INVERSE)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.done ? AppColor.SUCCESS : 'transparent')
        .borderRadius(AppRadius.FULL)
        .borderWidth(this.done ? 0 : 1)
        .borderColor(AppColor.BORDER);

      Column({ space: 2 }) {
        Text(taskNameRes(this.task.key, this.task.name))
          .fontSize(AppTypography.BODY_MEDIUM.size)
          .fontWeight(AppTypography.BODY_MEDIUM.weight)
          .fontColor(this.done ? AppColor.TEXT_SUB : AppColor.TEXT);
        Text(taskDescRes(this.task.key, this.task.desc))
          .fontSize(AppTypography.CAPTION.size)
          .fontColor(AppColor.TEXT_SUB);
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);

      Text('+' + this.task.points.toString())
        .fontSize(AppTypography.BODY_MEDIUM.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.done ? AppColor.TEXT_SUB : AppColor.ACCENT);
    }
    .width('100%')
    .padding(AppSpacing.MD)
    .backgroundColor(this.done ? AppColor.BG : AppColor.CARD)
    .borderRadius(AppRadius.MD)
    .borderWidth(0.5)
    .borderColor(AppColor.BORDER)
    .opacity(this.visible ? 1 : 0)
    .translate({ y: this.visible ? 0 : 16 })
    .scale({ x: this.pressed ? 0.98 : 1, y: this.pressed ? 0.98 : 1 })
    .animation({ duration: AppMotion.reduceMotion() ? 0 : 400, curve: AppMotion.EASE })
    .onTouch((event: TouchEvent) => {
      if (this.done) {
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
