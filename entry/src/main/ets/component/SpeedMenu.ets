@ComponentV2
export struct SpeedMenu {
  @Param @Require showMenu: boolean
  @Param @Require currentSpeed: number
  readonly speeds: number[] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
  @Event onSpeedChange?: (speed: number) => void

  build() {
    if (this.showMenu) {
      Column() {
        ForEach(this.speeds, (speed: number) => {
          Row() {
            Text(this.getSpeedText(speed))
              .fontSize(14)
              .fontColor(this.currentSpeed === speed ? '#39c5bb' : '#333')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
              .backgroundColor(this.currentSpeed === speed ? '#e8f8f5' : '#ffffff')
              .onClick(() => {
                this.onSpeedChange?.(speed)
              })
          }
          .width('100%')
        })
      }
      .position({ x: '60%', y: '10%' })
      .width(90)
      .backgroundColor('#ffffff')
      .borderRadius(10)
      .shadow({
        radius: 10,
        color: '#33000000',
        offsetX: 0,
        offsetY: 4
      })
      .zIndex(20)
      .onClick(() => {
        // 阻止事件冒泡
      })
    }
  }

  private getSpeedText(speed: number): string {
    return speed === 1.0 ? '正常' : `${speed}x`
  }
}
