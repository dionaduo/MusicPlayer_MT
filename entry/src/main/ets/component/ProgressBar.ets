@ComponentV2
export struct ProgressBar {
  @Param @Require currentTime: number
  @Param @Require duration: number
  @Event onSeek?: (time: number) => void

  build() {
    Column() {
      Slider({
        value: this.currentTime,
        step: 1,
        min: 0,
        max: this.duration || 100,
        style: SliderStyle.OutSet
      })
        .blockColor(Color.Transparent)
        .trackColor('#ffb7c8e0')
        .selectedColor('#39c5bb')
        .width('100%')
        .height(15)
        .onChange((value: number) => {
          this.onSeek?.(value)
        })
    }
    .width('100%')
    .padding({ left: 10, right: 10 })
  }
}
