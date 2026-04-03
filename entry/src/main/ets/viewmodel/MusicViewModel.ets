/**
 * @file MusicViewModel.ets
 * @description 音乐播放器视图模型
 * @module viewmodel
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 音乐播放状态管理
 * - 歌曲列表管理(热门/新歌/随机/搜索)
 * - 歌词解析和显示
 * - 播放控制(上一首/下一首)
 * - 搜索功能
 * - 刷新控制(防抖+频率限制)
 * - MVVM架构核心
 */

import { musicData, musicInfo, musicList, musicResponse } from '../model/musicResp'
import { getMusicInfo, getMusicList } from '../api/musicApi'

/**
 * MusicViewModel 音乐播放器视图模型
 * 管理所有音乐相关的业务逻辑和状态
 */
@ObservedV2
export class MusicViewModel {
  // ========== 音乐播放相关状态 ==========

  /** 音乐响应数据 */
  @Trace musicRes: musicResponse<musicData> = {} as musicResponse<musicData>

  /** 音乐播放URL */
  @Trace musicUrl: string = ''

  /** 歌词文本 */
  @Trace lyrics: string = ''

  /** 解析后的歌词行数组 */
  @Trace currentLyricLines: Array<musicInfo> = []

  /** 当前播放进度(毫秒) */
  @Trace currentProgress: number = 0

  /** 当前歌词索引 */
  @Trace currentLyricIndex: number = -1

  /** 当前音乐ID */
  @Trace musicId: string = '125380'

  // ========== 歌曲列表相关状态 ==========

  /** 热门音乐列表 */
  @Trace hotMusicList: musicList[] = []

  /** 新歌列表 */
  @Trace newMusicList: musicList[] = []

  /** 随机音乐列表 */
  @Trace randomMusicList: musicList[] = []

  /** 搜索音乐列表 */
  @Trace searchMusicList: musicList[] = []

  /** 收藏状态 */
  @Trace collection: boolean = false

  /** 收藏的歌曲 */
  @Trace collectMusic: musicList[] = []

  // ========== UI状态 ==========

  /** 是否显示歌词 */
  @Trace showLyrics: boolean = false

  /** 歌词滚动控制器 */
  @Trace scroller: Scroller = new Scroller()

  // ========== 播放控制 ==========

  /** 当前播放列表 */
  @Trace currentPlayList: musicList[] = []

  /** 当前播放索引 */
  @Trace currentPlayIndex: number = 0

  // ========== 刷新状态 ==========

  /** 是否正在刷新 */
  @Trace isRefreshing: boolean = false

  /** 上次刷新时间 */
  @Trace lastRefreshTime: number = -10000

  /** 刷新计数 */
  @Trace refreshCount: number = 0

  /** 搜索关键词 */
  @Trace searchKeyword: string = ''

  // ========== 常量 ==========

  /** 每分钟最大刷新次数 */
  private readonly MAX_REFRESH_PER_MINUTE: number = 6

  /** 刷新时间窗口(毫秒) */
  private readonly REFRESH_WINDOW: number = 60000

  /**
   * 加载音乐信息
   * 获取歌曲的播放URL、歌词等信息
   * @param musicId 音乐ID,默认使用当前musicId
   */
  async loadMusicInfo(musicId?: string): Promise<void> {
    try {
      const id = musicId || this.musicId
      const response: musicResponse<musicData> = await getMusicInfo({
        rid: id,
        type: 'json',
        level: 'exhigh',
        lrc: true
      })

      this.musicRes = response
      this.lyrics = this.musicRes.data.lrc
      this.parseLyrics(this.lyrics)
      this.musicUrl = this.musicRes.data.url
      this.resetLyricIndex()
    } catch (error) {
      console.error('ViewModel 加载歌曲信息失败:', error)
    }
  }

  /**
   * 加载热门歌曲列表
   */
  async loadHotMusicList(): Promise<void> {
    try {
      const response: musicResponse<musicList[]> = await getMusicList()
      this.hotMusicList = response.data || []
      console.log('热门音乐列表加载成功，共', this.hotMusicList.length, '首')
    } catch (e) {
      console.error('加载热门音乐列表失败:', e)
      this.hotMusicList = []
    }
  }

  /**
   * 加载新歌列表
   */
  async loadNewMusicList(): Promise<void> {
    try {
      const response: musicResponse<musicList[]> = await getMusicList({ type: 'new' })
      this.newMusicList = response.data || []
      console.log('新歌列表加载成功，共', this.newMusicList.length, '首')
    } catch (e) {
      console.error('加载新歌列表失败:', e)
      this.newMusicList = []
    }
  }

  /**
   * 加载随机歌曲列表
   */
  async loadRandomMusicList(): Promise<void> {
    try {
      const response: musicResponse<musicList[]> = await getMusicList({ type: 'rand' })
      this.randomMusicList = response.data || []
      console.log('随机音乐列表加载成功，共', this.randomMusicList.length, '首')
    } catch (e) {
      console.error('加载随机音乐列表失败:', e)
      this.randomMusicList = []
    }
  }

  /**
   * 搜索音乐
   * @param searchKey 搜索关键词
   */
  async searchMusic(searchKey: string): Promise<void> {
    try {
      const response: musicResponse<musicList[]> = await getMusicList({ type: 'search', keyword: searchKey })
      this.searchMusicList = response.data || []
      console.log('搜索音乐列表加载成功，共', this.searchMusicList.length, '首')
    } catch (e) {
      console.error('加载搜索音乐列表失败:', e)
      this.searchMusicList = []
    }
  }

  /**
   * 解析歌词
   * 将LRC格式歌词解析为歌词行数组
   * @param lrcText LRC格式歌词文本
   */
  private parseLyrics(lrcText: string): void {
    this.currentLyricLines = []
    const lines = lrcText.split(/\n/)

    lines.forEach((line) => {
      const match = line.match(/\[(\d+:\d+\.\d+)\](.*)/)
      if (match) {
        const time = this.parseTime(match[1])
        const text = match[2].trim()
        if (text) {
          this.currentLyricLines.push({ time, text })
        }
      }
    })

    this.currentLyricLines.sort((a, b) => a.time - b.time)
  }

  /**
   * 解析时间
   * 将LRC时间格式转换为毫秒数
   * @param timeStr 时间字符串,格式为 MM:SS.ms
   * @returns 毫秒数
   */
  private parseTime(timeStr: string): number {
    const parts = timeStr.split(':')
    const minutes = parseInt(parts[0])
    const seconds = parseFloat(parts[1])
    return (minutes * 60 + seconds) * 1000
  }

  /**
   * 切换歌词显示
   */
  toggleLyrics(): void {
    this.showLyrics = !this.showLyrics
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
        this.scroller.scrollToIndex(newIndex, true, ScrollAlign.CENTER,)
      }
    }
  }

  /**
   * 重置歌词索引
   * 用于切换歌曲时重置歌词位置
   */
  resetLyricIndex(): void {
    this.currentLyricIndex = -1
  }

  /**
   * 播放音乐
   * @param musicId 音乐ID
   */
  async playMusic(musicId: string): Promise<void> {
    this.musicId = musicId
    await this.loadMusicInfo(musicId)
  }

  /**
   * 设置播放列表
   * @param list 播放列表
   * @param index 起始索引,默认为0
   */
  setPlayList(list: musicList[], index?: number): void {
    this.currentPlayList = list
    this.currentPlayIndex = index ?? 0
  }

  /**
   * 上一首
   */
  async playPrevious(): Promise<void> {
    if (this.currentPlayList.length === 0) return

    this.currentPlayIndex = (this.currentPlayIndex - 1 + this.currentPlayList.length) % this.currentPlayList.length
    await this.playMusic(this.currentPlayList[this.currentPlayIndex].rid)
  }

  /**
   * 下一首
   */
  async playNext(): Promise<void> {
    if (this.currentPlayList.length === 0) return

    this.currentPlayIndex = (this.currentPlayIndex + 1) % this.currentPlayList.length
    await this.playMusic(this.currentPlayList[this.currentPlayIndex].rid)
  }

  /**
   * 切换收藏状态
   */
  toggleCollection(): void {
    this.collection = !this.collection
  }

  /**
   * 检查是否可以刷新
   * 实现防抖和频率限制
   * @returns 是否可以刷新
   */
  private canRefresh(): boolean {
    const now = Date.now()

    // 10秒防抖
    if (now - this.lastRefreshTime < 10000) {
      console.log('刷新请求过于频繁，请10秒后再试')
      return false
    }

    // 如果距离上次刷新超过1分钟，重置计数器
    if (now - this.lastRefreshTime > this.REFRESH_WINDOW) {
      this.refreshCount = 0
      this.lastRefreshTime = now
      return true
    }

    // 检查一分钟内的请求数量
    if (this.refreshCount >= this.MAX_REFRESH_PER_MINUTE) {
      console.log('刷新请求过于频繁，请稍后再试')
      return false
    }

    return true
  }

  /**
   * 刷新所有列表
   * 串行加载热门、新歌、随机列表
   */
  async refreshAllLists(): Promise<void> {
    if (this.isRefreshing) return

    if (!this.canRefresh()) {
      return
    }

    this.isRefreshing = true
    this.refreshCount++
    this.lastRefreshTime = Date.now()

    // 3秒后自动重置刷新状态，不管数据是否加载成功
    setTimeout(() => {
      this.isRefreshing = false
    }, 3000)

    try {
      // 串行加载，避免并发请求
      await this.loadHotMusicList()
      await this.loadNewMusicList()
      await this.loadRandomMusicList()
    } catch (error) {
      console.error('刷新失败:', error)
    }
  }
}
