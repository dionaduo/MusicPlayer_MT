/**
 * @file MusicGlobalState.ets
 * @description 音乐播放全局状态管理
 * @module utils
 * @author CodeArts
 * @date 2026-04-03
 *
 * 功能特性:
 * - 全局播放进度管理
 * - 全局歌词状态管理
 * - 跨页面状态同步
 * - 音乐播放列表状态
 */

import { musicInfo, musicList } from '../model/musicResp'

/**
 * MusicGlobalState 音乐播放全局状态管理类
 * 使用单例模式跨页面共享音乐播放状态
 */
@ObservedV2
export class MusicGlobalState {
  // ========== 单例模式 ==========

  private static instance: MusicGlobalState | null = null

  /**
   * 获取全局状态实例
   */
  static getInstance(): MusicGlobalState {
    if (!MusicGlobalState.instance) {
      MusicGlobalState.instance = new MusicGlobalState()
    }
    return MusicGlobalState.instance
  }

  // ========== 播放进度状态 ==========

  /** 当前播放进度(毫秒) */
  @Trace currentProgress: number = 0

  /** 当前歌词索引 */
  @Trace currentLyricIndex: number = -1

  // ========== 歌词数据状态 ==========

  /** 当前播放列表 */
  @Trace currentPlayList: musicList[] = []

  /** 当前播放索引 */
  @Trace currentPlayIndex: number = 0

  /** 歌词行数组 */
  @Trace currentLyricLines: musicInfo[] = []

  /** 歌词滚动控制器 */
  @Trace scroller: Scroller = new Scroller()

  // ========== 回调函数 ==========

  /** 进度更新回调 */
  private progressCallbacks: Array<(progress: number) => void> = []

  /** 歌词索引更新回调 */
  private lyricIndexCallbacks: Array<(index: number) => void> = []

  /**
   * 更新播放进度
   * @param progress 播放进度(毫秒)
   */
  updateProgress(progress: number): void {
    this.currentProgress = progress
    this.updateCurrentLyricIndex()
    // 通知所有监听器
    this.progressCallbacks.forEach(callback => callback(progress))
  }

  /**
   * 更新当前歌词索引
   * 根据当前播放进度更新歌词高亮位置
   */
  updateCurrentLyricIndex(): void {
    if (this.currentLyricLines.length === 0) {
      this.currentLyricIndex = -1
      return
    }

    let newIndex = -1
    for (let i = this.currentLyricLines.length - 1; i >= 0; i--) {
      if (this.currentProgress >= this.currentLyricLines[i].time) {
        newIndex = i
        break
      }
    }

    if (newIndex !== this.currentLyricIndex) {
      this.currentLyricIndex = newIndex
      if (newIndex >= 0) {
        this.scroller.scrollToIndex(newIndex, true, ScrollAlign.CENTER)
      }
      // 通知所有监听器
      this.lyricIndexCallbacks.forEach(callback => callback(newIndex))
    }
  }

  /**
   * 设置播放列表
   * @param list 播放列表
   * @param index 起始索引
   */
  setPlayList(list: musicList[], index?: number): void {
    this.currentPlayList = list
    this.currentPlayIndex = index ?? 0
  }

  /**
   * 设置歌词数据
   * @param lyricLines 歌词行数组
   */
  setLyricLines(lyricLines: musicInfo[]): void {
    this.currentLyricLines = lyricLines
    this.currentLyricIndex = -1
  }

  /**
   * 注册进度更新回调
   * @param callback 回调函数
   * @returns 取消注册的函数
   */
  registerProgressCallback(callback: (progress: number) => void): () => void {
    this.progressCallbacks.push(callback)
    // 返回取消注册的函数
    return () => {
      const index = this.progressCallbacks.indexOf(callback)
      if (index > -1) {
        this.progressCallbacks.splice(index, 1)
      }
    }
  }

  /**
   * 注册歌词索引更新回调
   * @param callback 回调函数
   * @returns 取消注册的函数
   */
  registerLyricIndexCallback(callback: (index: number) => void): () => void {
    this.lyricIndexCallbacks.push(callback)
    // 返回取消注册的函数
    return () => {
      const index = this.lyricIndexCallbacks.indexOf(callback)
      if (index > -1) {
        this.lyricIndexCallbacks.splice(index, 1)
      }
    }
  }
}
