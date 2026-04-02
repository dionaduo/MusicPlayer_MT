/**
 * @file AppMusicTabbar.ets
 * @description 音乐播放器底部控制栏组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 播放/暂停控制
 * - 进度条显示和拖动
 * - 上一首/下一首切换
 * - 音量控制
 * - 歌词显示切换
 * - 播放列表管理
 * - AVSession媒体会话集成
 */

import { media } from '@kit.MediaKit'
import { ConvertTime } from '../utils/tools'
import { VolumeControl } from './VolumeControl'
import { avSession } from '@kit.AVSessionKit'

/**
 * AppMusicTabbar 音乐播放器底部控制栏组件
 * 提供完整的音乐播放控制功能,包括播放控制、进度显示、音量调节等
 */
@ComponentV2
export struct AppMusicTabbar {
  // ========== 参数 ==========

  /** 音乐URL,必填参数 */
  @Param @Require musicUrl: string

  // ========== 可选参数 ==========

  /** 歌词文本 */
  @Param lyrics: string = ''

  /** 当前歌曲名称 */
  @Param currentSongName: string = ''

  /** 当前歌手名称 */
  @Param currentArtist: string = ''

  // ========== 本地状态 ==========

  /** 当前音量,范围0-1 */
  @Local volume: number = 1

  /** AVPlayer播放器实例 */
  @Local avPlayer: media.AVPlayer | null = null

  /** 播放器状态 */
  @Local playerState: string = 'paused'

  /** 当前播放时间(格式化) */
  @Local currentTime: string = '00:00'

  /** 总时长(格式化) */
  @Local durationTime: string = '00:00'

  /** 当前播放进度(毫秒) */
  @Local currentProgress: number = 0

  /** 总时长(毫秒) */
  @Local totalDuration: number = 0

  /** 是否正在播放 */
  @Local isPlaying: boolean = false

  /** 音量控制方向 */
  @Local reverse: boolean = true

  // ========== 事件回调 ==========

  /** 歌词按钮点击回调 */
  @Event onLrcClick?: () => void

  /** 进度更新回调 */
  @Event onProgressUpdate?: (progress: number) => void

  /** 上一首按钮点击回调 */
  @Event onPreviousClick?: () => void

  /** 下一首按钮点击回调 */
  @Event onNextClick?: () => void

  /** 播放列表按钮点击回调 */
  @Event onPlaylistClick?: () => void

  // ========== 常量 ==========

  /** 进度更新间隔(毫秒) */
  private readonly UPDATE_INTERVAL: number = 1000

  /** 默认音量 */
  private readonly DEFAULT_VOLUME: number = 1.0

  /** AVSession媒体会话实例 */
  private avSession: avSession.AVSession | null = null

  /**
   * 组件初始化
   * 创建AVPlayer播放器并设置监听器
   */
  async aboutToAppear(): Promise<void> {
    console.log('AppMusicTabbar aboutToAppear 开始')
    try {
      this.avPlayer = await media.createAVPlayer()
      if (this.avPlayer) {
        this.setupPlayerListeners()
        console.log('播放器监听器设置完成')
        await this.initAVSession()
        console.log('AVSession初始化完成')
      }
    } catch (error) {
      console.error('创建播放器失败', error)
    }
  }

  /**
   * 组件更新前检查
   * 如果播放器处于空闲状态且有音乐URL,则加载音乐
   */
  aboutToUpdate(): void {
    if (this.avPlayer && this.musicUrl && this.playerState === 'idle') {
      this.avPlayer.url = this.musicUrl
      this.avPlayer.prepare().catch((e: string) => console.log('准备播放失败: ', e))
    }
  }

  /**
   * 监听音乐URL变化
   * 当URL变化时重置播放器并加载新音乐
   */
  @Monitor('musicUrl')
  onMusicUrlChange(): void {
    if (this.avPlayer && this.musicUrl) {
      const currentState = this.avPlayer.state
      try {
        this.avPlayer.reset()
        setTimeout(() => {
          if (this.avPlayer?.state === 'idle') {
            this.loadMusic()
          }
        }, 100)
      } catch (error) {
        console.error('重置播放器失败:', error)
        this.loadMusic()
      }
    }
  }

  /**
   * 构建UI
   * 包含进度条、播放控制按钮、时间显示、音量控制等
   */
  build() {
    Column() {
      // 进度条
      Column() {
        Slider({
          value: this.currentProgress,
          max: this.totalDuration,
          step: 1,
          min: 0,
        })
          .outlineWidth('100%')
          .width('90%')
          .backgroundColor('#ffecf5f4')
          .blockColor('#39c5bb')
          .selectedColor('#39c5bb')
          .onChange((time: number) => this.avPlayer?.seek(time))
      }.height(10)
      .padding({ bottom: 5 })

      // 控制按钮区域
      Row() {
        // 左侧: 播放控制按钮
        Row({ space: 10 }) {
          Image($r('app.media.last_music'))
            .width(25)
            .onClick(() => this.onPreviousClick?.())
          Image(this.isPlaying ? $r('app.media.player') : $r('app.media.stoped'))
            .width(25)
            .onClick(() => this.togglePlay())
          Image($r('app.media.next_music'))
            .width(25)
            .onClick(() => this.onNextClick?.())
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)

        // 中间: 时间显示
        Row() {
          Text() {
            Span(this.currentTime || '00:00')
            Span(' / ')
            Span(this.durationTime || '00:00')
          }
        }
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)

        // 右侧: 功能按钮和音量控制
        Row({ space: 10 }) {
          Image($r('app.media.music_list'))
            .width(25)
            .onClick(() => this.onPlaylistClick?.())
          Image($r('app.media.music_lrc'))
            .width(30)
            .onClick(() => {
              this.onLrcClick?.()
            })
          VolumeControl({
            volume: this.volume,
            reverse: this.reverse,
            onVolumeChange: (vol: number) => {
              this.setVolume(vol)
            }
          })
        }
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
      }
      .backgroundColor(Color.White)
      .height('100%')
      .alignItems(VerticalAlign.Center)
    }
    .zIndex(999)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(Color.Transparent)
    .width('100%')
    .height('100%')
  }

  /**
   * 加载音乐
   * 设置播放器URL并准备播放
   */
  private loadMusic(): void {
    console.log('loadMusic 被调用, musicUrl:', this.musicUrl)
    if (this.avPlayer && this.musicUrl) {
      this.avPlayer.url = this.musicUrl

      setTimeout(() => {
        console.log('准备播放,当前状态:', this.avPlayer?.state)
        if (this.avPlayer?.state === 'initialized') {
          this.avPlayer.prepare().catch((e: string) => console.error('准备播放失败: ', e))
        } else {
          this.avPlayer?.prepare().catch((e: string) => console.error('准备播放失败: ', e))
        }
      }, 100)
    }
  }

  /**
   * 设置播放器监听器
   * 监听播放器状态变化和时间更新
   */
  private setupPlayerListeners(): void {
    if (!this.avPlayer) {
      return
    }

    // 监听播放器状态变化
    this.avPlayer.on('stateChange', async (state: string) => {
      console.log('播放器状态变化:', state)
      this.playerState = state

      // 更新AVSession状态
      if (this.avSession) {
        let playbackState: avSession.PlaybackState
        switch (state) {
          case 'playing':
            playbackState = avSession.PlaybackState.PLAYBACK_STATE_PLAY
            break
          case 'paused':
            playbackState = avSession.PlaybackState.PLAYBACK_STATE_PAUSE
            break
          case 'completed':
            playbackState = avSession.PlaybackState.PLAYBACK_STATE_STOP
            break
          default:
            playbackState = avSession.PlaybackState.PLAYBACK_STATE_PAUSE
        }

        try {
          await this.avSession.setAVPlaybackState({
            state: playbackState,
            position: {
              elapsedTime: this.currentProgress * 1000,
              updateTime: new Date().getTime()
            }
          })
        } catch (error) {
          console.error('更新播放状态失败:', error)
        }
      }

      // 根据状态执行相应操作
      switch (state) {
        case 'idle':
          if (this.musicUrl) {
            this.loadMusic()
          }
          break
        case 'initialized':
          this.avPlayer?.prepare().catch((e: string) => console.error('准备播放失败: ', e))
          break
        case 'prepared':
          this.totalDuration = this.avPlayer!.duration
          this.durationTime = ConvertTime(this.totalDuration)
          // 自动播放
          this.avPlayer?.play().catch((e: string) => console.error('自动播放失败:', e))
          break
        case 'playing':
          this.isPlaying = true
          break
        case 'paused':
        case 'completed':
          this.isPlaying = false
          break
        case 'error':
          console.error('播放失败: ', state)
          break
      }
    })

    // 监听播放时间更新
    this.avPlayer.on('timeUpdate', async (time: number) => {
      this.currentProgress = time
      this.currentTime = ConvertTime(time)
      this.onProgressUpdate?.(time)

      // 更新AVSession进度
      if (this.avSession) {
        try {
          await this.avSession.setAVPlaybackState({
            state: this.isPlaying ? avSession.PlaybackState.PLAYBACK_STATE_PLAY :
              avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
            position: {
              elapsedTime: time * 1000,
              updateTime: new Date().getTime()
            }
          })
        } catch (error) {
          console.error('更新播放进度失败:', error)
        }
      }
    })
  }

  /**
   * 设置音量
   * @param vol 音量值,范围0-1
   */
  private setVolume(vol: number): void {
    if (!this.avPlayer) {
      return
    }

    try {
      this.avPlayer.setVolume(vol)
      this.volume = vol
    } catch (error) {
      console.error('设置音量失败:', error)
      this.volume = this.DEFAULT_VOLUME
    }
  }

  /**
   * 切换播放/暂停状态
   */
  private togglePlay(): void {
    console.log('togglePlay 被调用,当前播放状态:', this.isPlaying)
    if (this.isPlaying) {
      this.avPlayer?.pause()
      console.log('暂停播放')
    } else {
      this.avPlayer?.play()
      console.log('开始播放')
    }
  }

  /**
   * 初始化AVSession媒体会话
   * 用于系统级媒体控制(通知栏、锁屏界面等)
   */
  private async initAVSession(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext()
      if (ctx) {
        this.avSession = await avSession.createAVSession(ctx, 'musicPlayer', 'audio')
      }

      if (this.avSession) {
        await this.avSession.setAVMetadata({
          assetId: 'music_001',
          title: '湘女多情',
          artist: '周杰伦',
        })

        await this.avSession.setAVPlaybackState({
          state: avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
          position: { elapsedTime: 0, updateTime: new Date().getTime() }
        })

        await this.avSession.activate()
      }
    } catch (error) {
      console.error('初始化 AVSession 失败:', error)
    }
  }
}
