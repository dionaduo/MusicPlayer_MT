/**
 * @file LyricsV2.ets
 * @description 歌词显示页面
 * @module pages
 * @author CodeArts
 * @date 2026-04-03
 *
 * 功能特性:
 * - 歌词显示和同步
 * - 歌曲信息展示
 * - 专辑封面旋转动画
 * - 歌词滚动和高亮
 * - 全局状态监听实现实时同步
 */

import { musicInfo, musicList } from '../model/musicResp'
import { MusicGlobalState } from '../utils/MusicGlobalState'

/**
 * LyricsV2 歌词显示页面
 * 独立的歌词展示页面,支持歌词同步滚动和高亮
 * 通过全局状态实现与Index页面的实时同步
 */
@Entry
@ComponentV2
struct LyricsV2 {

  // ========== 本地状态 ==========

  /** 全局音乐状态 */
  @Local globalState: MusicGlobalState = MusicGlobalState.getInstance()

  /** 当前播放列表 */
  @Local currentPlayList: Array<musicList> = []

  /** 当前播放索引 */
  @Local currentPlayIndex: number = 0

  /** 歌词行数组 */
  @Local currentLyricLines: Array<musicInfo> = []

  /** 当前歌词索引 */
  @Local currentLyricIndex: number = -1

  /** 歌词滚动控制器 */
  @Local scroller: Scroller = new Scroller()

  /** 旋转角度 */
  @Local rotateAngle: number = 0

  /** 旋转定时器 */
  @Local timer: number = 0

  /** 进度更新回调取消函数 */
  private unregisterProgressCallback: (() => void) | null = null

  /** 歌词索引更新回调取消函数 */
  private unregisterLyricIndexCallback: (() => void) | null = null

  /**
   * 页面初始化
   * 从全局状态获取数据并监听状态变化
   */
  aboutToAppear(): void {
    console.log('LyricsV2 aboutToAppear 开始')

    try {
      // 从全局状态获取数据
      this.currentPlayList = this.globalState.currentPlayList
      this.currentPlayIndex = this.globalState.currentPlayIndex
      this.currentLyricLines = this.globalState.currentLyricLines
      this.currentLyricIndex = this.globalState.currentLyricIndex
      this.scroller = this.globalState.scroller

      console.log('从全局状态获取到的数据:', {
        playListLength: this.currentPlayList.length,
        playIndex: this.currentPlayIndex,
        lyricLinesLength: this.currentLyricLines.length,
        lyricIndex: this.currentLyricIndex,
        currentSong: this.currentPlayList[this.currentPlayIndex]?.name || '无'
      })

      // 注册全局状态变化监听
      this.unregisterProgressCallback = this.globalState.registerProgressCallback((progress: number) => {
        console.log('收到进度更新:', progress)
      })

      this.unregisterLyricIndexCallback = this.globalState.registerLyricIndexCallback((index: number) => {
        console.log('收到歌词索引更新:', index)
        this.currentLyricIndex = index
      })

      // 如果没有数据,显示提示
      if (this.currentLyricLines.length === 0) {
        console.warn('歌词数据为空')
      }
      if (this.currentPlayList.length === 0) {
        console.warn('播放列表为空')
      }
    } catch (error) {
      console.error('获取全局状态失败:', error)
    }

    this.startRotate()

    console.log('LyricsV2 build 调用,当前数据:', {
      playListLength: this.currentPlayList.length,
      playIndex: this.currentPlayIndex,
      lyricLinesLength: this.currentLyricLines.length,
      lyricIndex: this.currentLyricIndex
    })

  }

  /**
   * 页面销毁前
   * 清理定时器和回调
   */
  aboutToDisappear(): void {
    if (this.timer) {
      clearTimeout(this.timer)
    }
    // 取消注册的回调
    if (this.unregisterProgressCallback) {
      this.unregisterProgressCallback()
      this.unregisterProgressCallback = null
    }
    if (this.unregisterLyricIndexCallback) {
      this.unregisterLyricIndexCallback()
      this.unregisterLyricIndexCallback = null
    }
  }

  /**
   * 组件复用
   * 清理定时器
   */
  aboutToReuse(): void {
    if (this.timer) {
      clearTimeout(this.timer)
    }
  }

  /**
   * 启动旋转动画
   */
  async startRotate(): Promise<void> {
    this.timer = setTimeout(() => {
      this.rotateAngle += 1
    }, 10)
  }

  /**
   * 返回按钮点击
   * 返回上一页
   */
  onBackClick(): void {
    this.getUIContext().getRouter().back()
  }

  build() {

    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.retrun'))
          .width(24)
          .height(24)
          .fillColor(Color.Black)
          .onClick(() => this.onBackClick())

        Text('歌词')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位,保持标题居中
        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(50)
      .padding({ top:30,left: 16, right: 16 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 歌曲信息
      Column() {
        Row({ space: 10 }) {
          Image(this.currentPlayList[this.currentPlayIndex]?.pic || '')
            .borderRadius(8)
            .width(100)
            .height(100)
            .animation({
              duration: 30,
            })
            .rotate({
              angle: this.rotateAngle
            })

          Column({ space: 5 }) {
            Text(this.currentPlayList[this.currentPlayIndex]?.name || '')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.currentPlayList[this.currentPlayIndex]?.artist || '')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .width('60%')
          .justifyContent(FlexAlign.Start)
        }
        .padding({ left: 20 })
        .justifyContent(FlexAlign.Start)
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20, bottom: 20 })

      // 歌词列表
      List({ scroller: this.scroller }) {
        ForEach(this.currentLyricLines, (item: musicInfo, index: number) => {
          ListItem() {
            Text(item.text)
              .fontSize(index === this.currentLyricIndex ? 20 : 16)
              .fontWeight(index === this.currentLyricIndex ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(index === this.currentLyricIndex ? '#39c5bb' : '#666666')
              .textAlign(TextAlign.Center)
              .width('90%')
              .padding({ top: 8, bottom: 8 })
              .opacity(index === this.currentLyricIndex ? 1 : 0.5)
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
              .scale({
                x: index === this.currentLyricIndex ? 1.1 : 1,
                y: index === this.currentLyricIndex ? 1.1 : 1
              })
              .animation({
                duration: 300,
                curve: Curve.EaseOut
              })
          }.width('100%')
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
      .scrollBar(BarState.Off)
      .alignListItem(ListItemAlign.Center)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#ffffffff')
  }
}
