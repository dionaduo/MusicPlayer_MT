/**
 * @file PlaybackMode.ets
 * @description 播放模式枚举和播放策略管理
 * @module utils/player
 * @author CodeArts
 * @date 2026-04-06
 *
 * 功能特性:
 * - 三种播放模式定义(顺序/单曲/随机)
 * - 播放模式切换逻辑
 * - 下一首/上一首播放策略
 */

import { musicList } from '../model/musicResp'

/**
 * 播放模式枚举
 */
export enum PlaybackMode {
  /** 顺序播放 */
  SEQUENTIAL = 'sequential',
  /** 单曲循环 */
  SINGLE_LOOP = 'single_loop',
  /** 随机播放 */
  RANDOM = 'random'
}

/**
 * 播放模式配置
 */
export interface PlaybackModeConfig {
  /** 播放模式 */
  mode: PlaybackMode
  /** 播放模式名称 */
  name: string
  /** 播放模式图标资源 */
  icon: Resource
}

/**
 * 播放策略管理器
 */
export class PlaybackStrategy {
  /** 播放模式配置列表 */
  private static readonly MODE_CONFIGS: PlaybackModeConfig[] = [
    {
      mode: PlaybackMode.SEQUENTIAL,
      name: '顺序播放',
      icon: $r('app.media.music_list')
    },
    {
      mode: PlaybackMode.SINGLE_LOOP,
      name: '单曲循环',
      icon: $r('app.media.single_player')
    },
    {
      mode: PlaybackMode.RANDOM,
      name: '随机播放',
      icon: $r('app.media.random_player')
    }
  ]

  /** 当前播放模式索引 */
  private static currentModeIndex: number = 0

  /**
   * 获取当前播放模式
   */
  static getCurrentMode(): PlaybackMode {
    return PlaybackStrategy.MODE_CONFIGS[PlaybackStrategy.currentModeIndex].mode
  }

  /**
   * 获取当前播放模式配置
   */
  static getCurrentModeConfig(): PlaybackModeConfig {
    return PlaybackStrategy.MODE_CONFIGS[PlaybackStrategy.currentModeIndex]
  }

  /**
   * 切换播放模式
   * 顺序播放 -> 单曲循环 -> 随机播放 -> 顺序播放
   */
  static switchMode(): PlaybackModeConfig {
    PlaybackStrategy.currentModeIndex = (PlaybackStrategy.currentModeIndex + 1) % PlaybackStrategy.MODE_CONFIGS.length
    return PlaybackStrategy.MODE_CONFIGS[PlaybackStrategy.currentModeIndex]
  }

  /**
   * 获取下一首播放索引
   * @param currentIndex 当前播放索引
   * @param playlist 播放列表
   * @returns 下一首的索引
   */
  static getNextIndex(currentIndex: number, playlist: musicList[]): number {
    if (playlist.length === 0) {
      return currentIndex
    }

    const mode = PlaybackStrategy.getCurrentMode()

    switch (mode) {
      case PlaybackMode.SEQUENTIAL:
        // 顺序播放：下一首
        return (currentIndex + 1) % playlist.length

      case PlaybackMode.SINGLE_LOOP:
        // 单曲循环：保持当前索引
        return currentIndex

      case PlaybackMode.RANDOM:
        // 随机播放：随机选择一个不同的索引
        return PlaybackStrategy.getRandomIndex(currentIndex, playlist.length)

      default:
        return (currentIndex + 1) % playlist.length
    }
  }

  /**
   * 获取上一首播放索引
   * @param currentIndex 当前播放索引
   * @param playlist 播放列表
   * @returns 上一首的索引
   */
  static getPreviousIndex(currentIndex: number, playlist: musicList[]): number {
    if (playlist.length === 0) {
      return currentIndex
    }

    const mode = PlaybackStrategy.getCurrentMode()

    switch (mode) {
      case PlaybackMode.SEQUENTIAL:
        // 顺序播放：上一首
        return (currentIndex - 1 + playlist.length) % playlist.length

      case PlaybackMode.SINGLE_LOOP:
        // 单曲循环：保持当前索引
        return currentIndex

      case PlaybackMode.RANDOM:
        // 随机播放：随机选择一个不同的索引
        return PlaybackStrategy.getRandomIndex(currentIndex, playlist.length)

      default:
        return (currentIndex - 1 + playlist.length) % playlist.length
    }
  }

  /**
   * 获取随机索引
   * @param currentIndex 当前索引
   * @param listLength 列表长度
   * @returns 随机索引
   */
  private static getRandomIndex(currentIndex: number, listLength: number): number {
    if (listLength <= 1) {
      return currentIndex
    }

    let randomIndex: number
    do {
      randomIndex = Math.floor(Math.random() * listLength)
    } while (randomIndex === currentIndex)

    return randomIndex
  }

  /**
   * 重置播放模式为顺序播放
   */
  static resetMode(): void {
    PlaybackStrategy.currentModeIndex = 0
    console.log('重置播放模式为顺序播放')
  }

  /**
   * 设置播放模式
   * @param mode 播放模式
   */
  static setMode(mode: PlaybackMode): void {
    const index = PlaybackStrategy.MODE_CONFIGS.findIndex(config => config.mode === mode)
    if (index !== -1) {
      PlaybackStrategy.currentModeIndex = index
      console.log('设置播放模式:', PlaybackStrategy.MODE_CONFIGS[index].name)
    }
  }
}
