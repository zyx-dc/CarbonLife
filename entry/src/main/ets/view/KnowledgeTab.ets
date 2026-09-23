import { AppColor } from '../common/Constants';
import { KnowledgeData, knowledgeCover, QuizData } from '../model/Rewards';
import { KnowledgeItem, QuizQuestion, QuizOption } from '../model/CarbonTypes';
import { AppCard } from '../components/AppCard';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct KnowledgeTab {
  @State expandedId: string = '';
  @State answers: number[] = [-1, -1, -1, -1, -1];
  @State ready: boolean = false;

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
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
          .height(6)
          .borderRadius(3)
          .backgroundColor(this.answers[i] >= 0 ? AppColor.SIGNAL : AppColor.BORDER);
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
          Text('碳足迹自测').fontSize(AppTypography.H4.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT);
          Text('5 道题，测测你的低碳指数').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Text('已答 ' + this.answeredCount().toString() + ' / ' + QuizData.QUESTIONS.length.toString())
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

      ForEach(QuizData.QUESTIONS, (q: QuizQuestion, qi: number) => {
        Column({ space: AppSpacing.SM }) {
          Row({ space: AppSpacing.SM }) {
            this.qIndex(qi + 1);
            Text(q.q)
              .fontSize(AppTypography.BODY_MEDIUM.size)
              .fontColor(AppColor.TEXT)
              .layoutWeight(1);
          }
          .width('100%')
          .alignItems(VerticalAlign.Center);
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(q.options, (opt: QuizOption, oi: number) => {
              Text(opt.label)
                .fontSize(AppTypography.SMALL.size)
                .fontWeight(this.answers[qi] === oi ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(this.answers[qi] === oi ? AppColor.ON_SIGNAL : AppColor.TEXT)
                .backgroundColor(this.answers[qi] === oi ? AppColor.SIGNAL : AppColor.GLASS_STRONG)
                .borderWidth(1)
                .borderColor(this.answers[qi] === oi ? AppColor.SIGNAL : AppColor.BORDER)
                .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
                .height(44)
                .textAlign(TextAlign.Center)
                .borderRadius(AppRadius.FULL)
                .margin({ right: AppSpacing.SM, bottom: AppSpacing.SM })
                .onClick(() => this.pick(qi, oi));
            }, (opt: QuizOption) => opt.label);
          }
          .width('100%');
        }
        .width('100%');
      }, (q: QuizQuestion) => q.id);

      if (this.answeredCount() === QuizData.QUESTIONS.length) {
        Row() {
          Column()
            .width(3)
            .height(38)
            .borderRadius(2)
            .backgroundColor(AppColor.SIGNAL);
          Column({ space: AppSpacing.XXS }) {
            Row({ space: AppSpacing.SM }) {
              Text('你的低碳指数').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
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

        Text('重新测一次')
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
          Text('双碳科普专栏').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
          Text('碳达峰 · 碳中和 · 低碳生活').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).width('100%');
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
                    ForEach(item.points, (p: string) => {
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
                    }, (p: string) => p);
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
                .animation({ duration: AppMotion.reduceMotion() ? 0 : 250, curve: AppMotion.EASE });
              } else {
                Text(item.summary)
                  .fontSize(AppTypography.CAPTION.size)
                  .fontColor(AppColor.TEXT_SUB)
                  .maxLines(2)
                  .width('100%');
              }
            }
            .width('100%')
            .onClick(() => { this.expandedId = this.expandedId === item.id ? '' : item.id; });
          }
                  }, (item: KnowledgeItem) => item.id);

        AppCard({ cardPadding: AppSpacing.MD, showBorder: true, enter: this.ready, enterDelayIndex: KnowledgeData.LIST.length + 2, marginBottom: AppSpacing.LG }) {
          Column({ space: AppSpacing.XS }) {
            Text('温馨提示').fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(FontWeight.Bold).fontColor(AppColor.TEXT).width('100%');
            Text('科普资料，碳排放因子为常用参考值，实际因地区与统计口径略有差异。')
              .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).lineHeight(AppTypography.CAPTION.lineHeight).width('100%');
          }
        }
      }
      .width('100%').padding({ left: AppSpacing.MD, right: AppSpacing.MD, top: AppSpacing.MD, bottom: 120 })
    }
    .width('100%').height('100%').backgroundColor(Color.Transparent).scrollBar(BarState.Off)
  }
}
