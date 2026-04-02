import { musicList } from '../pages/musicResp'

@ComponentV2
export struct MusicListItem {
  @Param @Require item: musicList
  @Param index: number = 0
  @Event onMusicClick?: (item: musicList) => void
  @Event onDownloadClick?: (item: musicList) => void
  @Event onCollectClick?: (item: musicList) => void
  @Local isCollected: boolean = false

  build() {
    Row() {
      // 序号
      Text(`${this.index + 1}`)
        .fontSize(14)
        .fontColor('#999999')
        .width(40)
        .textAlign(TextAlign.Center)

      // 歌曲信息
      Column() {
        Text(this.item.name)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.item.artist)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 10 })

      // 操作按钮
      Row({ space: 15 }) {
        // 下载按钮
        Image($r('app.media.download'))
          .width(18)
          .height(18)
          .fillColor('#666666')
          .padding({ bottom: 2 })
          .onClick(() => {
            this.onDownloadClick?.(this.item)
          })

        // 收藏按钮
        Image(this.isCollected ? $r('app.media.collectioned') : $r('app.media.collection'))
          .width(20)
          .height(20)
          .fillColor(this.isCollected ? '#ff6b6b' : '#666666')
          .onClick(() => {
            this.isCollected = !this.isCollected
            this.onCollectClick?.(this.item)
          })
      }
      .padding({ right: 20 })
    }
    .width('100%')
    .height(70)
    .padding({ left: 10, right: 10 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.onMusicClick?.(this.item)
    })
  }
}
