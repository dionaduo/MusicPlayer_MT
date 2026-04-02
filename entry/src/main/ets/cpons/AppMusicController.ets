import { media } from '@kit.MediaKit'
import { ConvertTime } from '../utils/tools'
import { ProgressBar } from './ProgressBar'
import { PlaybackControls } from './PlaybackControls'
import { VolumeControl } from '../component/VolumeControl'
import { SpeedMenu } from '../component/SpeedMenu'
import { FunctionButtons } from './FunctionButtons'

@Entry
@ComponentV2
export struct AppMusicController {
  @Local isPlayer: boolean = false
  @Local current: string = '00:00'
  @Local total: string = '00:00'
  @Local currentTimeNum: number = 0
  @Local durationNum: number = 0
  @Local playbackSpeed: number = 1.0
  @Local showSpeedMenu: boolean = false
  @Local volume: number = 1.0
  private avPlayer: media.AVPlayer | null = null
  private currentState: string = 'idle'
  private timerId: number = -1
  private readonly UPDATE_INTERVAL: number = 1000
  private readonly DEFAULT_VOLUME: number = 1.0

  async aboutToAppear(): Promise<void> {
    await this.initPlayer()
    this.startTimer()
  }

  aboutToDisappear(): void {
    this.cleanup()
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 主控制区域
      Column() {
        // 进度条
        ProgressBar({
          currentTime: this.currentTimeNum,
          duration: this.durationNum,
          onSeek: (time: number) => {
            this.seekToPosition(time)
          }
        })

        // 控制栏
        Row() {
          // 左侧：播放控制
          PlaybackControls({
            isPlaying: this.isPlayer,
            onPlayPause: () => {
              this.togglePlay()
            },
            onPrevious: () => {
              console.log('上一首')
            },
            onNext: () => {
              console.log('下一首')
            }
          })
            .layoutWeight(2)

          // 中间：时间显示
          Row() {
            Text(`${this.current} / ${this.total}`)
              .fontSize(13)
              .fontColor('#666')
              .fontWeight(FontWeight.Medium)
          }
          .layoutWeight(1)

          // 右侧：功能按钮组
          Row({ space: 12 }) {
            // 音量控制
            VolumeControl({
              volume: this.volume,
              onVolumeChange: (vol: number) => {
                this.setVolume(vol)
              },
              reverse: true
            })

            // 功能按钮
            FunctionButtons({
              playbackSpeed: this.playbackSpeed,
              showSpeedMenu: this.showSpeedMenu,
              onToggleSpeedMenu: () => {
                this.toggleSpeedMenu()
              },
              onSpeedChange: (speed: number) => {
                this.setPlaybackSpeed(speed)
              },
              onPlaylistClick: () => {
                console.log('播放列表')
              },
              onLyricsClick: () => {
                console.log('歌词')
              }
            })
          }
          .layoutWeight(2)
        }
        .width('100%')
        .height(60)
        .backgroundColor('#ffaa')
        .padding({ left: 15, right: 15 })
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .onClick(() => {
        this.closeMenusIfNeeded()
      })

      // 倍速选择菜单
      SpeedMenu({
        showMenu: this.showSpeedMenu,
        currentSpeed: this.playbackSpeed,
        onSpeedChange: (speed: number) => {
          this.setPlaybackSpeed(speed)
        }
      })
    }
  }

  private async initPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer()
      this.avPlayer.url =
        'https://lv-sycdn.kuwo.cn/7abae97f96748629e46b2e21505375dc/69cb5e39/resource/1307392909/trackmedia/M800001poe8Q1r0eAa.mp3'

      // 设置初始音量
      this.avPlayer.setVolume(this.volume)

      this.avPlayer.on('stateChange', (val) => {
        console.log('播放状态: ', val.toString())
        this.currentState = val.toString()
      })

      this.avPlayer.on('error', (error) => {
        console.error('播放错误: ', error.toString())
      })
    } catch (error) {
      console.error('播放器初始化失败:', error)
    }
  }

  private startTimer(): void {
    this.timerId = setInterval(() => {
      this.updatePlayerTime()
    }, this.UPDATE_INTERVAL)
  }

  private updatePlayerTime(): void {
    if (!this.avPlayer || !this.isPlayer) {
      return
    }

    try {
      const currentTime: number = this.avPlayer.currentTime
      const duration: number = this.avPlayer.duration

      if (currentTime && duration && duration > 0) {
        this.currentTimeNum = currentTime
        this.durationNum = duration
        this.current = ConvertTime(currentTime)
        this.total = ConvertTime(duration)

        if (currentTime >= duration && this.isPlayer) {
          this.isPlayer = false
          console.log('播放完成')
        }
      }
    } catch (error) {
      console.error('更新播放时间失败:', error)
    }
  }

  private cleanup(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
      this.timerId = -1
    }

    if (this.avPlayer) {
      this.avPlayer.release()
      this.avPlayer = null
    }
  }

  private async togglePlay(): Promise<void> {
    if (!this.avPlayer) {
      return
    }

    const isFinished: boolean = this.durationNum > 0 && this.currentTimeNum >= this.durationNum

    if (this.isPlayer) {
      this.pausePlay()
    } else if (isFinished) {
      await this.restartPlay()
    } else {
      await this.startPlay()
    }
  }

  private pausePlay(): void {
    this.avPlayer?.pause()
    this.isPlayer = false
  }

  private async startPlay(): Promise<void> {
    try {
      if (this.needsPrepare()) {
        await this.avPlayer?.prepare()
      }
      this.avPlayer?.play()
      this.isPlayer = true
    } catch (error) {
      console.error('播放失败:', error)
    }
  }

  private async restartPlay(): Promise<void> {
    try {
      this.seekToPosition(0)
      if (this.needsPrepare()) {
        await this.avPlayer?.prepare()
      }
      this.avPlayer?.play()
      this.isPlayer = true
    } catch (error) {
      console.error('重新播放失败:', error)
    }
  }

  private needsPrepare(): boolean {
    return this.currentState === 'idle' ||
      this.currentState === 'initialized' ||
      this.currentState === 'stopped'
  }

  private seekToPosition(time: number): void {
    if (!this.avPlayer) {
      return
    }

    try {
      this.current = ConvertTime(time)
      this.avPlayer.seek(time)
    } catch (error) {
      console.error('跳转失败:', error)
    }
  }

  private setPlaybackSpeed(speed: number): void {
    if (!this.avPlayer) {
      return
    }

    try {
      this.avPlayer.setSpeed(speed)
      this.playbackSpeed = speed
      this.showSpeedMenu = false
    } catch (error) {
      console.error('设置倍速失败:', error)
      this.playbackSpeed = 1.0
    }
  }

  private toggleSpeedMenu(): void {
    this.showSpeedMenu = !this.showSpeedMenu
  }

  private closeMenusIfNeeded(): void {
    if (this.showSpeedMenu) {
      this.showSpeedMenu = false
    }
  }

  private setVolume(vol: number): void {
    if (!this.avPlayer) {
      return
    }

    try {
      this.avPlayer.setVolume(vol)
      this.volume = vol
      console.log(`音量设置为: ${(vol * 100).toFixed(0)}%`)
    } catch (error) {
      console.error('设置音量失败:', error)
      this.volume = this.DEFAULT_VOLUME
    }
  }

  private toggleVolumeSlider(): void {
    // VolumeControl现在自己管理showVolumeSlider状态
  }
}