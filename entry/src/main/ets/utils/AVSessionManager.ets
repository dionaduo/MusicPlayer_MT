/**
 * @file AVSessionManager.ets
 * @description AVSession全局管理器
 * @module utils
 * @author CodeArts
 * @date 2026-04-06
 *
 * 功能特性:
 * - 全局单例管理AVSession
 * - 保持AVSession生命周期
 * - 提供统一的AVSession操作接口
 */

import { avSession } from '@kit.AVSessionKit'
import { BusinessError } from '@kit.BasicServicesKit'

/**
 * AVSession管理器
 * 使用单例模式确保应用生命周期内只有一个AVSession实例
 */
export class AVSessionManager {
  private static instance: AVSessionManager | null = null

  private session: avSession.AVSession | null = null
  private context: Context | null = null

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  static getInstance(): AVSessionManager {
    if (!AVSessionManager.instance) {
      AVSessionManager.instance = new AVSessionManager()
    }
    return AVSessionManager.instance
  }

  /**
   * 初始化AVSession
   */
  async init(context: Context): Promise<void> {
    if (this.session) {
      console.log('AVSession 已存在，无需重复创建')
      return
    }

    try {
      this.context = context
      this.session = await avSession.createAVSession(context, 'musicPlayer', 'audio')
      console.log('AVSession 创建成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 创建失败。code is ${code}, message is ${message}`)
    }
  }

  /**
   * 激活AVSession
   */
  async activate(): Promise<void> {
    if (!this.session) {
      console.error('AVSession 未初始化')
      return
    }

    try {
      await this.session.activate()
      console.log('AVSession 激活成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 激活失败。code is ${code}, message is ${message}`)
    }
  }

  /**
   * 去激活AVSession
   */
  async deactivate(): Promise<void> {
    if (!this.session) {
      console.error('AVSession 未初始化')
      return
    }

    try {
      await this.session.deactivate()
      console.log('AVSession 去激活成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 去激活失败。code is ${code}, message is ${message}`)
    }
  }

  /**
   * 设置AVSession元数据
   */
  async setAVMetadata(metadata: avSession.AVMetadata): Promise<void> {
    if (!this.session) {
      console.error('AVSession 未初始化')
      return
    }

    try {
      await this.session.setAVMetadata(metadata)
      console.log('AVSession 元数据设置成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 元数据设置失败。code is ${code}, message is ${message}`)
    }
  }

  /**
   * 设置AVSession播放状态
   */
  async setAVPlaybackState(state: avSession.AVPlaybackState): Promise<void> {
    if (!this.session) {
      console.error('AVSession 未初始化')
      return
    }

    try {
      await this.session.setAVPlaybackState(state)
      console.log('AVSession 播放状态设置成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 播放状态设置失败。code is ${code}, message is ${message}`)
    }
  }

  /**
   * 获取AVSession实例
   */
  getSession(): avSession.AVSession | null {
    return this.session
  }

  /**
   * 销毁AVSession
   */
  async destroy(): Promise<void> {
    if (!this.session) {
      console.log('AVSession 未初始化')
      return
    }

    try {
      await this.session.destroy()
      this.session = null
      console.log('AVSession 销毁成功')
    } catch (err) {
      let code = (err as BusinessError).code
      let message = (err as BusinessError).message
      console.error(`AVSession 销毁失败。code is ${code}, message is ${message}`)
    }
  }
}
