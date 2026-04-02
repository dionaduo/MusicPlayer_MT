@ComponentV2
export struct PlaybackControls {
  @Param @Require isPlaying: boolean
  @Event onPlayPause?: () => void
  @Event onPrevious?: () => void
  @Event onNext?: () => void

  build() {
    Row({ space: 5 }) {
      // 上一首
      Image($r('app.media.last_music'))
        .width(30)
        .onClick(() => {
          this.onPrevious?.()
        })

      // 播放/暂停
      Image(this.isPlaying ? $r('app.media.player') : $r('app.media.stoped'))
        .width(30)
        .height(30)
        .onClick(() => {
          this.onPlayPause?.()
        })

      // 下一首
      Column() {
        Image($r('app.media.next_music'))
          .width(30)
          .onClick(() => {
            this.onNext?.()
          })
      }
    }
  }
}
