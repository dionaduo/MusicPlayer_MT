/**
 * @file MusicListContainer.ets
 * @description 歌曲列表容器组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 可滚动的歌曲列表
 * - 下拉刷新功能
 * - 集成MusicListItem组件
 * - 统一的事件回调处理
 * - 弹性滚动效果
 */

import { musicList } from '../model/musicResp'
import { MusicListItem } from './MusicListItem'

/**
 * MusicListContainer 歌曲列表容器组件
 * 提供可滚动的歌曲列表,支持下拉刷新功能
 */
@ComponentV2
export struct MusicListContainer {
  // ========== 参数 ==========

  /** 歌曲列表数据 */
  @Param musicList: musicList[] = []

  /** 收藏列表(用于判断歌曲是否已收藏) */
  @Param collectMusic: musicList[] = []

  /** 刷新状态,必填参数 */
  @Param @Require isRefreshing: boolean

  // ========== 事件回调 ==========

  /** 歌曲点击回调 */
  @Event onMusicClick?: (item: musicList, index: number) => void

  /** 下载按钮点击回调 */
  @Event onDownloadClick?: (item: musicList) => void

  /** 收藏按钮点击回调 */
  @Event onCollectClick?: (item: musicList) => void

  /** 刷新回调 */
  @Event onRefresh?: () => void

  /**
   * 构建UI
   * 包含可滚动列表和下拉刷新功能
   */
  build() {
    Scroll() {
      Refresh({ refreshing: this.isRefreshing }) {
          List() {
            ForEach(this.musicList, (item: musicList, index: number) => {
              ListItem() {
                MusicListItem({
                  item: item,
                  index: index,
                  isCollected: this.collectMusic.some(m => m.rid === item.rid),
                  onMusicClick: (musicItem) => {
                    this.onMusicClick?.(musicItem, index)
                  },
                  onDownloadClick: (musicItem) => {
                    this.onDownloadClick?.(musicItem)
                  },
                  onCollectClick: (musicItem) => {
                    this.onCollectClick?.(musicItem)
                  }
                })
              }
            }, (item: musicList, index: number) => item.rid + index.toString())
          }
          .scrollBar(BarState.Off)
          .height('100%').padding({ bottom: 10 })
      }
      .onStateChange((refreshingStatus: RefreshStatus) => {
        if (refreshingStatus === RefreshStatus.Refresh) {
          this.onRefresh?.()
        }
      })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
