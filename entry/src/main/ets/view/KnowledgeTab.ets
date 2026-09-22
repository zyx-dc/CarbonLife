import { AppColor } from '../common/Constants';
import { KnowledgeData } from '../model/Rewards';
import { KnowledgeItem } from '../model/CarbonTypes';
import { AppCard } from '../components/AppCard';
import { AppMotion, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Component
export struct KnowledgeTab {
  @State expandedId: string = '';
  @State ready: boolean = false;

  aboutToAppear(): void {
    setTimeout(() => this.ready = true, AppMotion.reduceMotion() ? 0 : 60);
  }

  build() {
    Scroll() {
      Column({ space: AppSpacing.MD }) {
        Column({ space: AppSpacing.XS }) {
          Text('双碳科普专栏').fontSize(AppTypography.H2.size).fontWeight(AppTypography.H2.weight).fontColor(AppColor.TEXT).width('100%');
          Text('了解碳达峰碳中和，掌握低碳生活小知识').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).width('100%');
        }
        .width('100%').alignItems(HorizontalAlign.Start)
        .opacity(this.ready ? 1 : 0).translate({ y: this.ready ? 0 : 20 }).animation(AppMotion.enterOptions());

        ForEach(KnowledgeData.LIST, (item: KnowledgeItem, index: number) => {
                      AppCard({ cardPadding: AppSpacing.MD, showShadow: false, showBorder: true , enter: this.ready, enterDelayIndex: index + 1}) {
            Column({ space: AppSpacing.SM }) {
              Row({ space: AppSpacing.SM }) {
                Text(item.tag)
                  .fontSize(AppTypography.SMALL.size)
                  .fontColor(AppColor.PRIMARY)
                  .backgroundColor(AppColor.PRIMARY_SOFT)
                  .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XXS, bottom: AppSpacing.XXS })
                  .borderRadius(AppRadius.SM);
                Text(item.title)
                  .fontSize(AppTypography.BODY_MEDIUM.size)
                  .fontWeight(AppTypography.BODY_MEDIUM.weight)
                  .fontColor(AppColor.TEXT)
                  .layoutWeight(1);
                Text(this.expandedId === item.id ? '▲' : '▼').fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB);
              }
              .width('100%')
              .onClick(() => { this.expandedId = this.expandedId === item.id ? '' : item.id; });

              if (this.expandedId === item.id) {
                Column({ space: AppSpacing.XS }) {
                  Text(item.summary).fontSize(AppTypography.BODY.size).fontColor(AppColor.PRIMARY).width('100%');
                  Text(item.content).fontSize(AppTypography.BODY.size).fontColor(AppColor.TEXT_SUB).lineHeight(AppTypography.BODY.lineHeight).width('100%');
                }
                .width('100%')
                .opacity(this.expandedId === item.id ? 1 : 0)
                .animation({ duration: AppMotion.reduceMotion() ? 0 : 250, curve: AppMotion.EASE });
              } else {
                Text(item.summary)
                  .fontSize(AppTypography.CAPTION.size)
                  .fontColor(AppColor.TEXT_SUB)
                  .maxLines(2)
                  .width('100%');
              }
            }
          }
        }, (item: KnowledgeItem) => item.id);

                  AppCard({ cardPadding: AppSpacing.MD, showShadow: false, showBorder: true , enter: this.ready, enterDelayIndex: KnowledgeData.LIST.length + 1, marginBottom: AppSpacing.LG}) {
          Column({ space: AppSpacing.XS }) {
            Text('温馨提示').fontSize(AppTypography.BODY_MEDIUM.size).fontWeight(AppTypography.BODY_MEDIUM.weight).fontColor(AppColor.TEXT).width('100%');
            Text('本专栏内容为科普性资料，碳排放因子为常用参考值，实际数值可能因地区与统计口径不同而略有差异。')
              .fontSize(AppTypography.CAPTION.size).fontColor(AppColor.TEXT_SUB).lineHeight(AppTypography.CAPTION.lineHeight).width('100%');
          }
        }
      }
      .width('100%').padding(AppSpacing.MD)
    }
    .width('100%').height('100%').backgroundColor(AppColor.BG).scrollBar(BarState.Off)
  }
}
