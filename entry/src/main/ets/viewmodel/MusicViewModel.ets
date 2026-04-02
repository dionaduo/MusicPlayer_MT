import { musicData, musicResponse, musicInfo, musicList, GetMusicInfoParams } from '../pages/musicResp'
import { getMusicInfo, getMusicList } from '../utils/musicApi'
import { ExtraRegionPosition, LengthMetrics, LengthUnit } from '@kit.ArkUI'

@ObservedV2
export class MusicViewModel {
  // 音乐播放相关状态
  @Trace musicRes: musicResponse<musicData> = {} as musicResponse<musicData>
  @Trace musicUrl: string = ''
  @Trace lyrics: string = ''
  @Trace currentLyricLines: Array<musicInfo> = []
  @Trace currentProgress: number = 0
  @Trace currentLyricIndex: number = -1
  @Trace musicId: string = '125380'
  // 歌曲列表相关状态
  @Trace hotMusicList: musicList[] = []
  @Trace newMusicList: musicList[] = []
  @Trace randomMusicList: musicList[] = []
  @Trace searchMusicList: musicList[] = []
  @Trace collection: boolean = false
  // UI状态
  @Trace showLyrics: boolean = false
  // 歌词滚动控制器
  @Trace scroller: Scroller = new Scroller()
  // 播放控制
  @Trace currentPlayList: musicList[] = [] // 当前播放列表
  @Trace currentPlayIndex: number = 0 // 当前播放索引

  // 刷新状态
  @Trace isRefreshing: boolean = false
  @Trace lastRefreshTime: number = -10000 // 初始化为-10秒，确保首次刷新正常
  @Trace refreshCount: number = 0
  //搜索关键字
  @Trace searchKeyword: string = ''
  private readonly MAX_REFRESH_PER_MINUTE: number = 6
  private readonly REFRESH_WINDOW: number = 60000 // 1分钟 = 60000ms

  // 加载音乐信息
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
      this.resetLyricIndex() // 重置歌词索引
      console.log('ViewModel 歌曲信息加载成功, musicUrl:', this.musicUrl)
    } catch (error) {
      console.error('ViewModel 加载歌曲信息失败:', error)
    }
  }

  // 加载热门歌曲列表
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

  // 加载新歌列表
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

  // 加载随机歌曲列表
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

  // 切换歌词显示
  toggleLyrics(): void {
    this.showLyrics = !this.showLyrics
  }

  // 更新当前歌词索引
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

  // 重置歌词索引（用于切换歌曲时）
  resetLyricIndex(): void {
    this.currentLyricIndex = -1.
  }

  // 播放歌曲
  async playMusic(musicId: string): Promise<void> {
    this.musicId = musicId
    await this.loadMusicInfo(musicId)
  }

  // 设置播放列表
  setPlayList(list: musicList[], index?: number): void {
    this.currentPlayList = list
    this.currentPlayIndex = index ?? 0
  }

  // 上一首
  async playPrevious(): Promise<void> {
    if (this.currentPlayList.length === 0) {
      return
    }

    this.currentPlayIndex = (this.currentPlayIndex - 1 + this.currentPlayList.length) % this.currentPlayList.length
    await this.playMusic(this.currentPlayList[this.currentPlayIndex].rid)
  }

  // 下一首
  async playNext(): Promise<void> {
    if (this.currentPlayList.length === 0) {
      return
    }

    this.currentPlayIndex = (this.currentPlayIndex + 1) % this.currentPlayList.length
    await this.playMusic(this.currentPlayList[this.currentPlayIndex].rid)
  }

  // 切换收藏状态
  toggleCollection(): void {
    this.collection = !this.collection
  }

  // 刷新所有列表
  async refreshAllLists(): Promise<void> {
    if (this.isRefreshing) {
      return
    } // 防止重复刷新

    if (!this.canRefresh()) {
      return
    }

    this.isRefreshing = true
    this.refreshCount++
    this.lastRefreshTime = Date.now()

    try {
      // 串行加载，避免并发请求
      await this.loadHotMusicList()
      await this.loadNewMusicList()
      await this.loadRandomMusicList()
    } catch (error) {
      console.error('刷新失败:', error)
    } finally {
      this.isRefreshing = false
    }
  }

  // 解析歌词
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

  // 解析时间
  private parseTime(timeStr: string): number {
    const parts = timeStr.split(':')
    const minutes = parseInt(parts[0])
    const seconds = parseFloat(parts[1])
    return (minutes * 60 + seconds) * 1000
  }

  // 检查是否可以刷新
  private canRefresh(): boolean {
    const now = Date.now()

    // 检查距离上次刷新是否至少10秒
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
}
