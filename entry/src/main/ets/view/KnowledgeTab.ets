import { UIContext } from '@kit.ArkUI';
import { AppColor } from '../common/Constants';
import { KnowledgeData, knowledgeCover, QuizData } from '../model/Rewards';
import { KnowledgeItem, QuizQuestion, QuizOption } from '../model/CarbonTypes';
import { AppCard } from '../components/AppCard';
import { AppButton } from '../components/AppButton';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct KnowledgeTab {
  @State expandedId: string = '';
  @State answers: number[] = [-1, -1, -1, -1, -1];
  @State step: number = 0;
  @State ready: boolean = false;
  private uiContext: UIContext = this.getUIContext();

  // #5 文本展开：文章展开/收起用动画过渡
  private toggleArticle(id: string): void {
    this.uiContext.animateTo({ duration: AppMotion.reduceMotion() ? 0 : 260, curve: Curve.EaseInOut }, () => {
      this.expandedId = this.expandedId === id ? '' : id;
    });
  }

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
  }

  private total(): number {
    return QuizData.QUESTIONS.length;
  }

  private isDone(): boolean {
    return this.step >= this.total();
  }

  private next(): void {
    if (this.step < this.total()) {
      this.step += 1;
    }
  }

  private back(): void {
    if (this.step > 0) {
      this.step -= 1;
    }
  }

  private canAdvance(): boolean {
    return !this.isDone() && this.answers[this.step] >= 0;
  }

  private quizScore(): number {
    let total = 0;
    QuizData.QUESTIONS.forEach((q: QuizQuestion, i: number) => {
      const picked = this.answers[i];
      if (picked >= 0) {
        total += q.options[picked].score;
      }
    });
    return total;
  }

  private answeredCount(): number {
    let n = 0;
    this.answers.forEach((a: number) => {
      if (a >= 0) {
        n += 1;
      }
    });
    return n;
  }

  private pick(qi: number, oi: number): void {
    const next: number[] = this.answers.slice();
    next[qi] = oi;
    this.answers = next;
  }

  private resetQuiz(): void {
    this.answers = [-1, -1, -1, -1, -1];
    this.step = 0;
  }

  // 封面压暗：仅保留底部渐变（去掉右下角水印标识），统一图片调性
  @Builder
  coverScrim() {
    Column()
      .width('100%')
      .height('100%')
      .linearGradient({ direction: GradientDirection.Bottom, colors: [[AppColor.SCRIM_FADE, 0.0], [AppColor.SCRIM, 1.0]] });
  }

  @Builder
  progressSegments() {
    Row({ space: 6 }) {
      ForEach([0, 1, 2, 3, 4], (i: number) => {
        Row()
          .layoutWeight(1)
          .height(!this.isDone() && i === this.step ? 8 : 6)
          .borderRadius(4)
          .backgroundColor(i < this.step || this.isDone() ? AppColor.PRIMARY : (i === this.step ? AppColor.PRIMARY : AppColor.BORDER))
          .opacity(i === this.step && !this.isDone() ? 1 : (i < this.step ? 0.55 : 1))
          .animation({ duration: AppMotion.reduceMotion() ? 0 : 300, curve: Curve.Friction });
      }, (i: number) => i.toString());
    }
    .width('100%');
  }

  @Builder
  qIndex(n: number) {
    Text(n.toString())
      .width(22)
      .height(22)
      .lineHeight(22)
      .textAlign(TextAlign.Center)
      .fontSize(AppTypography.SMALL.size)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColor.TEXT)
      .backgroundColor(AppColor.ELEVATED)
      .borderWidth(1)
      .borderColor(AppColor.BORDER)
      .borderRadius(AppRadius.FULL);
  }

  @Builder
  quizCard() {
    Column({ space: AppSpacing.MD }) {
      Row() {
        Column({ space: AppSpacing.XXS }) {
          Text($r('app.string.knowledge_quiz_title')).fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT);
          Text($r('app.string.knowledge_quiz_subtitle')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Text($r('app.string.knowledge_quiz_progress', this.answeredCount().toString(), this.total().toString()))
          .fontSize(AppTypography.CAPTION_MEDIUM.size)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColor.TEXT_SUB)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
          .backgroundColor(AppColor.ELEVATED)
          .borderWidth(1)
          .borderColor(AppColor.BORDER)
          .borderRadius(AppRadius.FULL);
      }.width('100%').alignItems(VerticalAlign.Center);

      this.progressSegments();

      if (!this.isDone()) {
        // 一题一屏：减少同时可见选项，降低认知负荷
        Column({ space: AppSpacing.SM }) {
          Row({ space: AppSpacing.SM }) {
            Text((this.step + 1).toString())
              .width(22)
              .height(22)
              .lineHeight(22)
              .textAlign(TextAlign.Center)
              .fontSize(AppTypography.SMALL.size)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColor.TEXT)
              .backgroundColor(AppColor.ELEVATED)
              .borderWidth(1)
              .borderColor(AppColor.BORDER)
              .borderRadius(AppRadius.FULL);
            Text(QuizData.QUESTIONS[this.step].q)
              .fontSize(AppTypography.BODY_MEDIUM.size)
              .fontColor(AppColor.TEXT)
              .layoutWeight(1);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(QuizData.QUESTIONS[this.step].options, (opt: QuizOption, oi: number) => {
              Text(opt.label)
                .fontSize(AppTypography.SMALL.size)
                .fontWeight(this.answers[this.step] === oi ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(this.answers[this.step] === oi ? AppColor.TEXT_INVERSE : AppColor.TEXT)
                .backgroundColor(this.answers[this.step] === oi ? AppColor.PRIMARY : AppColor.GLASS_STRONG)
                .borderWidth(1)
                .borderColor(this.answers[this.step] === oi ? AppColor.PRIMARY : AppColor.BORDER)
                .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
                .height(44)
                .textAlign(TextAlign.Center)
                .borderRadius(AppRadius.FULL)
                .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
                .onClick(() => this.pick(this.step, oi));
            }, (opt: QuizOption, oi: number) => this.step.toString() + '-' + oi.toString());
          }
          .width('100%');
        }
        .width('100%')
        .id('quiz-q-' + this.step);

        Row({ space: AppSpacing.SM }) {
          if (this.step > 0) {
            AppButton({ text: $r('app.string.knowledge_quiz_prev'), type: 'secondary', btnHeight: 44 })
              .layoutWeight(1)
              .onClick(() => this.back());
          }
          AppButton({
            text: this.step === this.total() - 1 ? $r('app.string.knowledge_quiz_see_result') : $r('app.string.knowledge_quiz_next'),
            type: 'primary',
            btnHeight: 44,
            disabled: !this.canAdvance()
          })
            .layoutWeight(1)
            .onClick(() => this.next());
        }
        .width('100%');
      } else {
        Row() {
          Column()
            .width(3)
            .height(38)
            .borderRadius(2)
            .backgroundColor(AppColor.PRIMARY);
          Column({ space: AppSpacing.XXS }) {
            Row({ space: AppSpacing.SM }) {
              Text($r('app.string.knowledge_quiz_result')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
              Text(QuizData.level(this.quizScore()))
                .fontSize(AppTypography.H4.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColor.PRIMARY);
            }.alignItems(VerticalAlign.Center);
            Text(QuizData.tip(this.quizScore()))
              .fontSize(AppTypography.CAPTION.size)
              .fontColor(AppColor.TEXT_SUB)
              .lineHeight(AppTypography.CAPTION.lineHeight)
              .width('100%');
          }
          .layoutWeight(1)
          .margin({ left: AppSpacing.SM })
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .padding(AppSpacing.MD)
        .backgroundColor(AppColor.PRIMARY_SOFT)
        .borderRadius(AppRadius.MD);

        Text($r('app.string.knowledge_quiz_retry'))
          .fontSize(AppTypography.SMALL.size)
          .fontColor(AppColor.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.SM, bottom: AppSpacing.SM })
          .borderWidth(1)
          .borderColor(AppColor.PRIMARY)
          .borderRadius(AppRadius.FULL)
          .onClick(() => this.resetQuiz());
      }
    }
    .width('100%');
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Column({ space: AppSpacing.XS }) {
          Text('KNOWLEDGE')
            .fontSize(AppTypography.SMALL.size)
            .letterSpacing(2.5)
            .fontColor(AppColor.TEXT_SUB);
          Text($r('app.string.knowledge_title')).fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
          Text($r('app.string.knowledge_subtitle')).fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).width('100%');
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        AppCard({ cardPadding: AppSpacing.LG, enter: this.ready, enterDelayIndex: 1 }) {
          this.quizCard();
        }

        ForEach(KnowledgeData.LIST, (item: KnowledgeItem, index: number) => {
          AppCard({ cardPadding: AppSpacing.MD, showBorder: true, enter: this.ready, enterDelayIndex: index + 2 }) {
            Column({ space: AppSpacing.MD }) {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(knowledgeCover(item.id))
                  .width('100%')
                  .aspectRatio(1.78)
                  .borderRadius({ topLeft: AppRadius.XXL, topRight: AppRadius.XXL })
                  .objectFit(ImageFit.Cover)
                  .overlay(this.coverScrim, { align: Alignment.Bottom });
                Text(item.tag)
                  .fontSize(AppTypography.SMALL.size)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColor.ON_OVERLAY)
                  .backgroundColor(AppColor.OVERLAY)
                  .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
                  .borderRadius(AppRadius.FULL)
                  .margin(AppSpacing.MD);
              }
              .width('100%')
              .margin({ left: -AppSpacing.MD, right: -AppSpacing.MD, top: -AppSpacing.MD });

              Row({ space: AppSpacing.SM }) {
                Text(item.title)
                  .fontSize(AppTypography.H3.size)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColor.TEXT)
                  .layoutWeight(1);
                Image($r('app.media.ic_chevron_down'))
                  .width(16)
                  .height(16)
                  .fillColor(AppColor.TEXT_SUB)
                  .rotate({ angle: this.expandedId === item.id ? 180 : 0 })
                  .animation(AppMotion.pressOptions());
              }
              .width('100%')
              .alignItems(VerticalAlign.Center);

              if (this.expandedId === item.id) {
                Column({ space: AppSpacing.MD }) {
                  Text(item.content)
                    .fontSize(AppTypography.BODY.size)
                    .fontColor(AppColor.TEXT_SUB)
                    .lineHeight(AppTypography.BODY.lineHeight)
                    .width('100%');
                  Column({ space: AppSpacing.SM }) {
                    ForEach(item.points, (p: ResourceStr) => {
                      Row({ space: AppSpacing.SM }) {
                        Column()
                          .width(6)
                          .height(6)
                          .borderRadius(2)
                          .backgroundColor(AppColor.PRIMARY)
                          .margin({ top: 7 });
                        Text(p)
                          .fontSize(AppTypography.BODY.size)
                          .fontColor(AppColor.TEXT)
                          .lineHeight(AppTypography.BODY.lineHeight)
                          .layoutWeight(1);
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Top);
                    }, (p: ResourceStr, pi: number) => pi.toString());
                  }
                  .width('100%');

                  Row() {
                    Column()
                      .width(3)
                      .height(36)
                      .borderRadius(2)
                      .backgroundColor(AppColor.SIGNAL);
                    Column({ space: AppSpacing.XXS }) {
                      Text(item.factLabel).fontSize(AppTypography.SMALL.size).fontColor(AppColor.TEXT_SUB);
                      Text(item.fact).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(FontWeight.Bold).fontColor(AppColor.PRIMARY);
                    }.layoutWeight(1).margin({ left: AppSpacing.SM }).alignItems(HorizontalAlign.Start);
                  }
                  .width('100%')
                  .padding(AppSpacing.MD)
                  .backgroundColor(AppColor.PRIMARY_SOFT)
                  .borderRadius(AppRadius.MD);
                }
                .width('100%')
                .transition(TransitionEffect.OPACITY.animation({ duration: AppMotion.reduceMotion() ? 0 : 240, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ y: -8 })));
              } else {
                Text(item.summary)
                  .fontSize(AppTypography.CAPTION.size)
                  .fontColor(AppColor.TEXT_SUB)
                  .maxLines(2)
                  .width('100%');
              }
            }
            .width('100%')
            .onClick(() => { this.toggleArticle(item.id); });
          }
                  }, (item: KnowledgeItem) => item.id);

        AppCard({ cardPadding: AppSpacing.MD, showBorder: true, enter: this.ready, enterDelayIndex: KnowledgeData.LIST.length + 2, marginBottom: AppSpacing.LG }) {
          Column({ space: AppSpacing.XS }) {
            Text($r('app.string.knowledge_disclaimer_title')).fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT).width('100%');
            Text($r('app.string.knowledge_disclaimer'))
              .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).lineHeight(AppTypography.CAPTION.lineHeight).width('100%');
          }
        }
      }
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: AppSpacing.XL })
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off)
  }
}
