@ComponentV2
export struct FunctionButtons {
  @Param @Require playbackSpeed: number
  @Param @Require showSpeedMenu: boolean
  @Event onToggleSpeedMenu?: () => void
  @Event onSpeedChange?: (speed: number) => void
  @Event onPlaylistClick?: () => void
  @Event onLyricsClick?: () => void

  build() {
    Row({ space: 12 }) {
      // 倍速按钮
      Text(this.getSpeedText(this.playbackSpeed))
        .fontSize(11)
        .fontColor('#39c5bb')
        .padding({
          left: 10,
          right: 10,
          top: 5,
          bottom: 5
        })
        .backgroundColor('#f0f0f0')
        .borderRadius(12)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.onToggleSpeedMenu?.()
        })

      // 播放列表按钮
      Image($r('app.media.music_list'))
        .width(26)
        .height(26)
        .onClick(() => {
          this.onPlaylistClick?.()
        })

      // 歌词按钮
      Image($r('app.media.music_lrc'))
        .width(26)
        .height(26)
        .onClick(() => {
          this.onLyricsClick?.()
        })
    }
  }

  private getSpeedText(speed: number): string {
    return speed === 1.0 ? '正常' : `${speed}x`
  }
}
