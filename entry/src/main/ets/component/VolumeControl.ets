@ComponentV2
export struct VolumeControl {
  @Param @Require volume: number
  @Param @Require reverse: boolean
  @Local showVolumeSlider: boolean = false
  @Event onVolumeChange?: (volume: number) => void

  build() {
    Column() {
      // 音量图标
      Image(this.volume == 0 ? $r('app.media.low_sound') : $r('app.media.hight_sound'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.showVolumeSlider = !this.showVolumeSlider
        })

      // 音量滑块
      if (this.showVolumeSlider) {
        Column() {
          Slider({
            value: this.volume,
            step: 0.01,
            min: 0,
            max: 1,
            style: SliderStyle.OutSet,
            direction: Axis.Vertical,
            reverse: this.reverse
          })
            .blockColor(Color.Transparent)
            .trackColor('#e0e0e0')
            .selectedColor('#39c5bb')
            .width(5)
            .height(100)
            .onChange((value: number) => {
              this.onVolumeChange?.(value)
            })
        }
        .width(5)
        .position({ left: 5, top: -100 })
        .padding(8)
        .borderRadius(1)
        .height(100)
        .shadow({
          radius: 6,
          color: '#33000000',
          offsetX: 0,
          offsetY: 2
        })
        .onClick(() => {
          // 阻止事件冒泡
        })
      }
    }
    .width(30)
  }
}
