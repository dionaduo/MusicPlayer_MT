/**
 * @file VolumeControl.ets
 * @description 音量控制组件
 * @module component
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 音量图标显示
 * - 垂直音量滑块
 * - 点击展开/收起音量控制
 * - 实时音量调节
 * - 阴影效果
 */

/**
 * VolumeControl 音量控制组件
 * 提供音量图标和垂直滑块,用于调节播放音量
 */
@ComponentV2
export struct VolumeControl {
  // ========== 参数 ==========

  /** 当前音量值,范围0-1,必填参数 */
  @Param @Require volume: number

  /** 音量滑块方向,必填参数 */
  @Param @Require reverse: boolean

  // ========== 本地状态 ==========

  /** 是否显示音量滑块 */
  @Local showVolumeSlider: boolean = false

  // ========== 事件回调 ==========

  /** 音量变化回调 */
  @Event onVolumeChange?: (volume: number) => void

  /**
   * 构建UI
   * 包含音量图标和垂直音量滑块
   */
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
