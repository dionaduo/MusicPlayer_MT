/**
 * @file MusicListItem.ets
 * @description 歌曲列表项组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 显示歌曲序号、名称、歌手
 * - 点击播放功能
 * - 下载按钮
 * - 收藏按钮(带状态切换)
 * - 简洁的卡片式布局
 */

import { musicList } from '../model/musicResp'

/**
 * MusicListItem 歌曲列表项组件
 * 用于在歌曲列表中显示单首歌曲的信息和操作按钮
 */
@ComponentV2
export struct MusicListItem {
  // ========== 参数 ==========

  /** 歌曲数据对象,必填参数 */
  @Param @Require item: musicList

  // ========== 可选参数 ==========

  /** 歌曲在列表中的索引 */
  @Param index: number = 0

  // ========== 事件回调 ==========

  /** 歌曲点击回调 */
  @Event onMusicClick?: (item: musicList) => void

  /** 下载按钮点击回调 */
  @Event onDownloadClick?: (item: musicList) => void

  /** 收藏按钮点击回调 */
  @Event onCollectClick?: (item: musicList) => void

  // ========== 可选参数 ==========

  /** 是否已收藏(从父组件传入) */
  @Param isCollected: boolean = false

  /**
   * 构建UI
   * 包含序号、歌曲信息、操作按钮
   */
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
