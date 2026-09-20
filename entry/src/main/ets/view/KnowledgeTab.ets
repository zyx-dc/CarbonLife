import { AppColor } from '../common/Constants';
import { KnowledgeData } from '../model/Rewards';
import { KnowledgeItem } from '../model/CarbonTypes';

@Component
export struct KnowledgeTab {
  @State expandedId: string = '';

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Text('双碳科普专栏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColor.TEXT)
          .width('100%')
        Text('了解碳达峰碳中和，掌握低碳生活小知识')
          .fontSize(12)
          .fontColor(AppColor.TEXT_SUB)
          .width('100%')

        ForEach(KnowledgeData.LIST, (item: KnowledgeItem) => {
          Column() {
            Row() {
              Text(item.tag)
                .fontSize(10)
                .fontColor(AppColor.PRIMARY)
                .backgroundColor(AppColor.BG)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(8)
              Text(item.title)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColor.TEXT)
                .layoutWeight(1)
                .margin({ left: 8 })
              Text(this.expandedId === item.id ? '▲' : '▼')
                .fontSize(12)
                .fontColor(AppColor.TEXT_SUB)
            }
            .width('100%')
            .onClick(() => {
              this.expandedId = this.expandedId === item.id ? '' : item.id;
            })

            if (this.expandedId === item.id) {
              Text(item.summary)
                .fontSize(13)
                .fontColor(AppColor.PRIMARY)
                .width('100%')
                .margin({ top: 10 })
              Text(item.content)
                .fontSize(13)
                .fontColor(AppColor.TEXT_SUB)
                .lineHeight(22)
                .width('100%')
                .margin({ top: 8 })
            } else {
              Text(item.summary)
                .fontSize(12)
                .fontColor(AppColor.TEXT_SUB)
                .maxLines(2)
                .width('100%')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(AppColor.CARD)
          .borderRadius(16)
        }, (item: KnowledgeItem) => item.id)

        Column() {
          Text('温馨提示')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColor.TEXT)
            .width('100%')
          Text('本专栏内容为科普性资料，碳排放因子为常用参考值，实际数值可能因地区与统计口径不同而略有差异。')
            .fontSize(11)
            .fontColor(AppColor.TEXT_SUB)
            .lineHeight(18)
            .margin({ top: 6 })
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(AppColor.BG)
        .borderRadius(16)
        .margin({ bottom: 16 })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColor.BG)
    .scrollBar(BarState.Off)
  }
}
