/**
 * @file Index.ets
 * @description 音乐播放器主页面
 * @module pages
 * @author CodeArts
 * @date 2026-04-02
 *
 * 功能特性:
 * - 热门/新歌/随机/收藏四个Tab页面
 * - 音乐搜索功能
 * - 歌词显示和同步
 * - 音乐播放控制
 * - 歌曲下载功能
 * - 下拉刷新
 * - MVVM架构设计
 */

import { musicList } from '../model/musicResp'
import { AppMusicTabbar } from '../component/AppMusicTabbar'
import { MusicTabContent } from '../component/TabContentBuilder'
import { MusicListContainer } from '../component/MusicListContainer'
import { MusicViewModel } from '../viewmodel/MusicViewModel'
import { downMusic, showToast } from '../utils/tools'
import { common } from '@kit.AbilityKit'
import { preferenceUtil } from '../utils/KVDatabaseUtil'
import { router } from '@kit.ArkUI'
import { MusicGlobalState } from '../utils/MusicGlobalState'

/**
 * Index 音乐播放器主页面
 * 应用入口页面,整合所有功能模块
 */
@Entry
@ComponentV2
struct Index {


  // ========== 本地状态 ==========

  /** 音乐视图模型,管理所有业务逻辑和状态 */
  @Local viewModel: MusicViewModel = new MusicViewModel()

  /** 当前Tab索引 */
  @Local currentTab: number = 0

  /** 当前播放音乐URL */
  @Local musicUrl: string = ''

  /** 是否处于搜索模式 */
  @Local isSearchMode: boolean = false

  /** 是否启用自动播放标志 */
  @Local enableAutoPlayFlag: boolean = false

  /** 全局音乐状态 */
  private globalState: MusicGlobalState = MusicGlobalState.getInstance()


  // ========== 私有属性 ==========

  /** UIAbility上下文,用于文件操作 */
  private context= (this.getUIContext().getHostContext())as common.UIAbilityContext

  /**
   * 页面初始化
   * 加载音乐列表但不自动播放
   */
  async aboutToAppear(): Promise<void> {
    console.log('Index aboutToAppear 开始')
    try {
      // 初始化持久化数据库
      preferenceUtil.init()

      // 串行加载列表，避免并发请求
      await this.viewModel.loadHotMusicList()
      await this.viewModel.loadNewMusicList()
      await this.viewModel.loadRandomMusicList()

      // 设置播放列表为热门音乐，但不自动播放
      if (this.viewModel.hotMusicList.length > 0) {
        this.viewModel.setPlayList(this.viewModel.hotMusicList, 0)
        // 只加载歌曲信息，不自动播放
        await this.viewModel.playMusic(this.viewModel.hotMusicList[0].rid)
        this.musicUrl = this.viewModel.musicUrl
        // 同步到全局状态
        this.globalState.setPlayList(this.viewModel.hotMusicList, 0)
        this.globalState.setLyricLines(this.viewModel.currentLyricLines)
      }

      // 加载收藏列表
      this.loadCollectMusicList()
    } catch (error) {
      console.error('Index aboutToAppear 加载失败:', error)
    }
  }

  /**
   * 加载收藏列表
   * 从preferences中读取收藏的rid列表，然后获取对应的歌曲信息
   */
  loadCollectMusicList(): void {
    try {
      const ridList = preferenceUtil.getCollectRidList()
      const collectMusic: musicList[] = []

      ridList.forEach(rid => {
        const collectKey = `musicCollectData${rid}`
        const musicItem = preferenceUtil.get(collectKey) as musicList
        if (musicItem && musicItem.rid) {
          collectMusic.push(musicItem)
        }
      })

      this.viewModel.collectMusic = collectMusic
      console.log('收藏列表加载成功，共', collectMusic.length, '首')
    } catch (error) {
      console.error('加载收藏列表失败:', error)
      this.viewModel.collectMusic = []
    }
  }

  /**
   * 歌词按钮点击事件
   * 跳转到歌词页面
   */
  onLrcClick(): void {
    try {
      console.log('准备跳转到歌词页面,当前数据:', {
        playListLength: this.viewModel.currentPlayList.length,
        playIndex: this.viewModel.currentPlayIndex,
        lyricLinesLength: this.viewModel.currentLyricLines.length,
        lyricIndex: this.viewModel.currentLyricIndex
      })

      router.pushUrl({
        url: 'pages/LyricsV2',
        params: {
          currentPlayList: this.viewModel.currentPlayList,
          currentPlayIndex: this.viewModel.currentPlayIndex,
          currentLyricLines: this.viewModel.currentLyricLines,
          currentLyricIndex: this.viewModel.currentLyricIndex
        }
      }, router.RouterMode.Standard)
    } catch (error) {
      console.error('跳转到歌词页面失败:', error)
    }
  }


  @Builder
  SearchResultView() {
    Column() {
      if (this.viewModel.searchMusicList.length === 0) {
        Column() {
          Text('未找到相关歌曲')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        MusicListContainer({
          musicList: this.viewModel.searchMusicList,
          collectMusic: this.viewModel.collectMusic,
          isRefreshing: false,
          onMusicClick: async (musicItem, index) => {
            this.viewModel.setPlayList(this.viewModel.searchMusicList, index)
            await this.viewModel.playMusic(musicItem.rid)
            this.musicUrl = this.viewModel.musicUrl
            this.enableAutoPlayFlag = true
            // 同步到全局状态
            this.globalState.setPlayList(this.viewModel.searchMusicList, index)
            this.globalState.setLyricLines(this.viewModel.currentLyricLines)
          },
          onDownloadClick: async (musicItem) => {
            console.log('下载歌曲:', musicItem.name)
            try {
              // 先加载歌曲信息获取URL
              await this.viewModel.playMusic(musicItem.rid)
              // 等待musicUrl更新
              if (this.musicUrl && musicItem.name && this.context) {
                console.log('开始下载:', musicItem.name)
                await downMusic(this.musicUrl, musicItem.name + '.mp3', this.context)
              } else {
                console.error('下载失败: musicUrl为空或context不存在')
              }
            } catch (error) {
              console.error('下载歌曲失败:', error)
            }
          },
          onCollectClick: (musicItem) => {
            console.log('收藏歌曲:', musicItem.name)
            const collectKey = `musicCollectData${musicItem.rid}`
            const existingData = preferenceUtil.get(collectKey) as musicList

            if (existingData && existingData.rid === musicItem.rid) {
              // 已收藏，执行取消收藏
              preferenceUtil.delete(collectKey)
              showToast('取消收藏')
            } else {
              // 未收藏，执行收藏
              preferenceUtil.put(collectKey, musicItem)
              showToast('收藏成功')
            }
            // 重新加载收藏列表
            this.loadCollectMusicList()
          },
          onRefresh: () => {
            // 搜索结果不需要下拉刷新
          }
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  build() {
    Stack() {
      Column() {
        Column() {
          // 搜索栏
          Row() {
            Search({ placeholder: '搜索音乐' })
              .searchButton('搜索')
              .backgroundColor('#f5f5f5')
              .placeholderColor('#999999')
              .textFont({ size: 14 })
              .height(40)
              .width('100%')
              .onChange((value: string) => {
                this.viewModel.searchKeyword = value
              })
              .onSubmit(() => {
                console.log('搜索关键词:', this.viewModel.searchKeyword)
                if (this.viewModel.searchKeyword.trim()) {
                  this.isSearchMode = true
                  this.viewModel.searchMusic(this.viewModel.searchKeyword)
                }
              })
          }
          .width('100%')
          .padding({
            left: 10,
            right: 10,
            top: 20,
          })

          // 搜索结果或Tabs
          if (this.isSearchMode && this.viewModel.searchKeyword.length > 0) {
            this.SearchResultView()
          } else {
            Tabs({ barPosition: BarPosition.Start }) {
              // 热门音乐
              MusicTabContent({
                tabTitle: '热门',
                musicList: this.viewModel.hotMusicList,
                collectMusic: this.viewModel.collectMusic,
                isRefreshing: this.viewModel.isRefreshing,
                onMusicClick: async (musicItem, index) => {
                  this.viewModel.setPlayList(this.viewModel.hotMusicList, index)
                  await this.viewModel.playMusic(musicItem.rid)
                  this.musicUrl = this.viewModel.musicUrl
                  // 点击歌曲时启用自动播放标志
                  this.enableAutoPlayFlag = true
                  // 同步到全局状态
                  this.globalState.setPlayList(this.viewModel.hotMusicList, index)
                  this.globalState.setLyricLines(this.viewModel.currentLyricLines)
                },
                onDownloadClick: async (musicItem) => {
                  try {
                    await this.viewModel.playMusic(musicItem.rid);
                    if (this.musicUrl && musicItem.name && this.context) {
                      await downMusic(this.musicUrl, musicItem.name + '.mp3', this.context);
                    }
                  } catch (error) {
                    console.error('下载歌曲失败:', error);
                  }
                },
                onCollectClick: (musicItem) => {
                  console.log('收藏歌曲:', musicItem.name)
                  const collectKey = `musicCollectData${musicItem.rid}`
                  const existingData = preferenceUtil.get(collectKey) as musicList

                  if (existingData && existingData.rid === musicItem.rid) {
                    // 已收藏，执行取消收藏
                    preferenceUtil.delete(collectKey)
                    preferenceUtil.removeCollectRid(musicItem.rid)
                    showToast('取消收藏')
                  } else {
                    // 未收藏，执行收藏
                    preferenceUtil.put(collectKey, musicItem)
                    preferenceUtil.addCollectRid(musicItem.rid)
                    showToast('收藏成功')
                  }
                  // 重新加载收藏列表
                  this.loadCollectMusicList()
                },
                onRefresh: async () => {
                  console.log('热门歌曲下拉刷新')
                  this.viewModel.isRefreshing = true
                  setTimeout(() => {
                    this.viewModel.isRefreshing = false
                  }, 3000)
                  await this.viewModel.loadHotMusicList()
                }
              })

              // 新歌
              MusicTabContent({
                tabTitle: '新歌',
                musicList: this.viewModel.newMusicList,
                collectMusic: this.viewModel.collectMusic,
                isRefreshing: this.viewModel.isRefreshing,
                onMusicClick: async (musicItem, index) => {
                  this.viewModel.setPlayList(this.viewModel.newMusicList, index)
                  await this.viewModel.playMusic(musicItem.rid)
                  this.musicUrl = this.viewModel.musicUrl
                  this.enableAutoPlayFlag = true
                  // 同步到全局状态
                  this.globalState.setPlayList(this.viewModel.newMusicList, index)
                  this.globalState.setLyricLines(this.viewModel.currentLyricLines)
                },
                onDownloadClick: async (musicItem) => {
                  console.log('下载歌曲:', musicItem.name)
                  try {
                    await this.viewModel.playMusic(musicItem.rid)
                    if (this.musicUrl && musicItem.name && this.context) {
                      await downMusic(this.musicUrl, musicItem.name + '.mp3', this.context)
                    } else {
                      console.error('下载失败: musicUrl为空或context不存在')
                    }
                  } catch (error) {
                    console.error('下载歌曲失败:', error)
                  }
                },
                onCollectClick: (musicItem) => {
                  console.log('收藏歌曲:', musicItem.name)
                  const collectKey = `musicCollectData${musicItem.rid}`
                  const existingData = preferenceUtil.get(collectKey) as musicList

                  if (existingData && existingData.rid === musicItem.rid) {
                    // 已收藏，执行取消收藏
                    preferenceUtil.delete(collectKey)
                    preferenceUtil.removeCollectRid(musicItem.rid)
                    showToast('取消收藏')
                  } else {
                    // 未收藏，执行收藏
                    preferenceUtil.put(collectKey, musicItem)
                    preferenceUtil.addCollectRid(musicItem.rid)
                    showToast('收藏成功')
                  }
                  // 重新加载收藏列表
                  this.loadCollectMusicList()
                },
                onRefresh: async () => {
                  console.log('新歌下拉刷新')
                  this.viewModel.isRefreshing = true
                  setTimeout(() => {
                    this.viewModel.isRefreshing = false
                  }, 3000)
                  await this.viewModel.loadNewMusicList()
                }
              })

              // 随机
              MusicTabContent({
                tabTitle: '随机',
                musicList: this.viewModel.randomMusicList,
                collectMusic: this.viewModel.collectMusic,
                isRefreshing: this.viewModel.isRefreshing,
                onMusicClick: async (musicItem, index) => {
                  this.viewModel.setPlayList(this.viewModel.randomMusicList, index)
                  await this.viewModel.playMusic(musicItem.rid)
                  this.musicUrl = this.viewModel.musicUrl
                  this.enableAutoPlayFlag = true
                  // 同步到全局状态
                  this.globalState.setPlayList(this.viewModel.randomMusicList, index)
                  this.globalState.setLyricLines(this.viewModel.currentLyricLines)
                },
                onDownloadClick: async (musicItem) => {
                  console.log('下载歌曲:', musicItem.name)
                  try {
                    // 先加载歌曲信息获取URL
                    await this.viewModel.playMusic(musicItem.rid)
                    // 等待musicUrl更新
                    if (this.musicUrl && musicItem.name && this.context) {
                      await downMusic(this.musicUrl, musicItem.name + '.mp3', this.context)
                    } else {
                      console.error('下载失败: musicUrl为空或context不存在')
                    }
                  } catch (error) {
                    console.error('下载歌曲失败:', error)
                  }
                },
                onCollectClick: (musicItem) => {
                  console.log('收藏歌曲:', musicItem.name)
                  const collectKey = `musicCollectData${musicItem.rid}`
                  const existingData = preferenceUtil.get(collectKey) as musicList

                  if (existingData && existingData.rid === musicItem.rid) {
                    // 已收藏，执行取消收藏
                    preferenceUtil.delete(collectKey)
                    preferenceUtil.removeCollectRid(musicItem.rid)
                    showToast('取消收藏')
                  } else {
                    // 未收藏，执行收藏
                    preferenceUtil.put(collectKey, musicItem)
                    preferenceUtil.addCollectRid(musicItem.rid)
                    showToast('收藏成功')
                  }
                  // 重新加载收藏列表
                  this.loadCollectMusicList()
                },
                onRefresh: async () => {
                  console.log('随机歌曲下拉刷新')
                  this.viewModel.isRefreshing = true
                  setTimeout(() => {
                    this.viewModel.isRefreshing = false
                  }, 3000)
                  await this.viewModel.loadRandomMusicList()
                }
              })

              //收藏
              MusicTabContent({
                tabTitle: '收藏',
                musicList: this.viewModel.collectMusic,
                collectMusic: this.viewModel.collectMusic,
                isRefreshing: this.viewModel.isRefreshing,
                onMusicClick: async (musicItem, index) => {
                  this.viewModel.setPlayList(this.viewModel.collectMusic, index)
                  await this.viewModel.playMusic(musicItem.rid)
                  this.musicUrl = this.viewModel.musicUrl
                  this.enableAutoPlayFlag = true
                  // 同步到全局状态
                  this.globalState.setPlayList(this.viewModel.collectMusic, index)
                  this.globalState.setLyricLines(this.viewModel.currentLyricLines)
                },
                onDownloadClick: async (musicItem) => {
                  console.log('下载歌曲:', musicItem.name)
                  try {
                    // 先加载歌曲信息获取URL
                    await this.viewModel.playMusic(musicItem.rid)
                    // 等待musicUrl更新
                    if (this.musicUrl && musicItem.name && this.context) {
                      await downMusic(this.musicUrl, musicItem.name + '.mp3', this.context)
                    } else {
                      console.error('下载失败: musicUrl为空或context不存在')
                    }
                  } catch (error) {
                    console.error('下载歌曲失败:', error)
                  }
                },
                onCollectClick: (musicItem) => {
                  console.log('取消收藏歌曲:', musicItem.name)
                  const collectKey = `musicCollectData${musicItem.rid}`
                  preferenceUtil.delete(collectKey)
                  preferenceUtil.removeCollectRid(musicItem.rid)
                  // 重新加载收藏列表
                  this.loadCollectMusicList()
                  showToast('取消收藏')
                },
                onRefresh: async () => {
                  console.log('收藏列表下拉刷新')
                  this.viewModel.isRefreshing = true
                  setTimeout(() => {
                    this.viewModel.isRefreshing = false
                  }, 3000)
                  // 重新加载收藏列表
                  this.loadCollectMusicList()
                }
              })

            }
            .layoutWeight(1)
            .barHeight(40)
          }
        }
        .layoutWeight(1)
      }

      Row() {
        AppMusicTabbar({
          musicUrl: this.musicUrl,
          lyrics: this.viewModel.lyrics,
          currentSongName: this.viewModel.currentPlayList[this.viewModel.currentPlayIndex]?.name || '',
          currentArtist: this.viewModel.currentPlayList[this.viewModel.currentPlayIndex]?.artist || '',
          autoPlayEnabled: this.enableAutoPlayFlag,
          onLrcClick: () => this.onLrcClick(),
          onProgressUpdate: (progress: number) => {
            // 同步到viewModel
            this.viewModel.currentProgress = progress
            this.viewModel.updateCurrentLyricIndex()
            // 同步到全局状态
            this.globalState.updateProgress(progress)
          },
          onPreviousClick: async () => {
            await this.viewModel.playPrevious()
            this.musicUrl = this.viewModel.musicUrl
            this.enableAutoPlayFlag = true
            // 同步到全局状态
            this.globalState.setPlayList(this.viewModel.currentPlayList, this.viewModel.currentPlayIndex)
            this.globalState.setLyricLines(this.viewModel.currentLyricLines)
          },
          onNextClick: async () => {
            await this.viewModel.playNext()
            this.musicUrl = this.viewModel.musicUrl
            this.enableAutoPlayFlag = true
            // 同步到全局状态
            this.globalState.setPlayList(this.viewModel.currentPlayList, this.viewModel.currentPlayIndex)
            this.globalState.setLyricLines(this.viewModel.currentLyricLines)
          },
          onPlayClick: () => {
            this.enableAutoPlayFlag = true
          }
        })
      }
      .width('100%')
      .height('10%')
    }
    .width('100%')
    .height('100%')
  }
}
