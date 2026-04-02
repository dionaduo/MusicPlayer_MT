/**
 * @file SpeedMenu.ets
 * @description 播放速度菜单组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 播放速度选择菜单
 * - 多档速度选项(0.5x-2.0x)
 * - 当前速度高亮显示
 * - 悬浮菜单样式
 * - 阴影效果
 */

/**
 * SpeedMenu 播放速度菜单组件
 * 提供播放速度选择功能,支持多档速度调节
 */
@ComponentV2
export struct SpeedMenu {
  // ========== 参数 ==========

  /** 是否显示菜单,必填参数 */
  @Param @Require showMenu: boolean

  /** 当前播放速度,必填参数 */
  @Param @Require currentSpeed: number

  // ========== 常量 ==========

  /** 可选播放速度列表 */
  readonly speeds: number[] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

  // ========== 事件回调 ==========

  /** 速度变化回调 */
  @Event onSpeedChange?: (speed: number) => void

  /**
   * 构建UI
   * 显示播放速度选择菜单
   */
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

  /**
   * 获取速度显示文本
   * @param speed 速度值
   * @returns 显示文本
   */
  private getSpeedText(speed: number): string {
    return speed === 1.0 ? '正常' : `${speed}x`
  }
}
