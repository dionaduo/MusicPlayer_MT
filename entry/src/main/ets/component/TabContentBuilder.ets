/**
 * @file TabContentBuilder.ets
 * @description Tab内容构建器组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - TabContent封装
 * - 集成MusicListContainer
 * - 统一的Tab标题管理
 * - 简化Tab创建流程
 */

import { musicList } from '../model/musicResp'
import { MusicListContainer } from './MusicListContainer'

/**
 * MusicTabContent Tab内容构建器组件
 * 用于创建音乐Tab页面,封装了MusicListContainer
 */
@ComponentV2
export struct MusicTabContent {
  // ========== 参数 ==========

  /** 歌曲列表数据 */
  @Param musicList: musicList[] = []

  /** 收藏列表(用于判断歌曲是否已收藏) */
  @Param collectMusic: musicList[] = []

  /** Tab标题 */
  @Param tabTitle: string = ''

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
   * 创建TabContent并集成MusicListContainer
   */
  build() {
    TabContent() {
      if (this.musicList){
        MusicListContainer({
          musicList: this.musicList,
          collectMusic: this.collectMusic,
          isRefreshing: this.isRefreshing,
          onMusicClick: this.onMusicClick,
          onDownloadClick: this.onDownloadClick,
          onCollectClick: this.onCollectClick,
          onRefresh: this.onRefresh
        })
      } else {
        Column() {
          Text('暂无数据').fontSize(16).fontColor(Color.Gray).textAlign(TextAlign.Center)
        }
        .height('100%')
        .width('100%')
        .padding({ top: 10 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

    }
    .tabBar(this.tabTitle)
  }
}
