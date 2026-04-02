import { media } from "@kit.MediaKit"
import { ConvertTime } from "../utils/tools"
import { VolumeControl } from "./VolumeControl"
import { avSession } from "@kit.AVSessionKit"

@ComponentV2
export struct AppMusicTabbar {
  @Param @Require musicUrl: string
  @Param lyrics: string = ''
  @Param currentSongName: string = ''
  @Param currentArtist: string = ''
  @Local volume: number = 1
  @Local avPlayer: media.AVPlayer | null = null
  @Local playerState: string = 'paused'
  @Local currentTime: string = '00:00'
  @Local durationTime: string = '00:00'
  @Local currentProgress: number = 0
  @Local totalDuration: number = 0
  @Local isPlaying: boolean = false
  @Local reverse: boolean = true
  @Event onLrcClick?: () => void
  @Event onProgressUpdate?: (progress: number) => void
  @Event onPreviousClick?: () => void
  @Event onNextClick?: () => void
  @Event onPlaylistClick?: () => void
  private readonly UPDATE_INTERVAL: number = 1000
  private readonly DEFAULT_VOLUME: number = 1.0
  private avSession: avSession.AVSession | null = null

  async aboutToAppear(): Promise<void> {
    console.log('AppMusicTabbar aboutToAppear 开始')
    try {
      this.avPlayer = await media.createAVPlayer()
      console.log('AVPlayer创建成功')
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

  aboutToUpdate(): void {
    if (this.avPlayer && this.musicUrl && this.playerState === 'idle') {
      this.avPlayer.url = this.musicUrl
      this.avPlayer.prepare().catch((e: string) => console.log('准备播放失败: ', e))
    }
  }

  @Monitor('musicUrl')
  onMusicUrlChange(): void {
    console.log('onMusicUrlChange 触发, musicUrl:', this.musicUrl)
    if (this.avPlayer && this.musicUrl) {
      const currentState = this.avPlayer.state
      console.log('当前播放器状态:', currentState)

      // 无论什么状态,都先重置播放器
      try {
        this.avPlayer.reset()
        console.log('播放器已重置')
        // 等待重置完成后再加载新音乐
        setTimeout(() => {
          if (this.avPlayer?.state === 'idle') {
            this.loadMusic()
          }
        }, 100)
      } catch (error) {
        console.error('重置播放器失败:', error)
        // 如果重置失败,尝试直接加载
        this.loadMusic()
      }
    }
  }

  build() {
    Column() {
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

      Row() {
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

  private loadMusic(): void {
    console.log('loadMusic 被调用, musicUrl:', this.musicUrl)
    if (this.avPlayer && this.musicUrl) {
      this.avPlayer.url = this.musicUrl
      console.log('设置播放器URL:', this.musicUrl)

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

  private setupPlayerListeners(): void {
    if (!this.avPlayer) {
      return
    }

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
          console.log('AVPlayer duration原始值:', this.totalDuration, '类型:', typeof this.totalDuration)
          // AVPlayer的duration已经是秒,不需要再乘以1000
          this.durationTime = ConvertTime(this.totalDuration) // 转换为毫秒
          console.log('歌曲准备完成,总时长(秒):', this.totalDuration, '格式化后:', this.durationTime)
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

    this.avPlayer.on('timeUpdate', async (time: number) => {
      this.currentProgress = time
      this.currentTime = ConvertTime(time) // 转换为毫秒
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