import { musicList, musicInfo } from './musicResp'
import { AppMusicTabbar } from '../component/AppMusicTabbar'
import { MusicTabContent } from '../component/TabContentBuilder'
import { MusicListContainer } from '../component/MusicListContainer'
import { MusicViewModel } from '../viewmodel/MusicViewModel'

@Entry
@ComponentV2
struct Index {
  @Local viewModel: MusicViewModel = new MusicViewModel()
  @Local currentTab: number = 0
  @Local musicUrl: string = ''
  @Local isSearchMode: boolean = false
  private title: string[] = ['热门', '新歌', '随机', '收藏']

  async aboutToAppear(): Promise<void> {
    console.log('Index aboutToAppear 开始')
    try {
      // 串行加载列表，避免并发请求
      await this.viewModel.loadHotMusicList()
      await this.viewModel.loadNewMusicList()
      await this.viewModel.loadRandomMusicList()

      // 设置播放列表为热门音乐，并播放第一首
      if (this.viewModel.hotMusicList.length > 0) {
        this.viewModel.setPlayList(this.viewModel.hotMusicList, 0)
        await this.viewModel.playMusic(this.viewModel.hotMusicList[0].rid)
        this.musicUrl = this.viewModel.musicUrl
      }
    } catch (error) {
      console.error('Index aboutToAppear 加载失败:', error)
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.viewModel.showLyrics) {
          this.LyricsView()
        } else {
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
              top: 10,
              bottom: 10
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
                  isRefreshing: this.viewModel.isRefreshing,
                  onMusicClick: async (musicItem, index) => {
                    this.viewModel.setPlayList(this.viewModel.hotMusicList, index)
                    await this.viewModel.playMusic(musicItem.rid)
                    this.musicUrl = this.viewModel.musicUrl
                  },
                  onDownloadClick: (musicItem) => {
                    console.log('下载歌曲:', musicItem.name)
                  },
                  onCollectClick: (musicItem) => {
                    console.log('收藏歌曲:', musicItem.name)
                  },
                  onRefresh: async () => {
                    console.log('热门歌曲下拉刷新')
                    await this.viewModel.loadHotMusicList()
                  }
                })

                // 新歌
                MusicTabContent({
                  tabTitle: '新歌',
                  musicList: this.viewModel.newMusicList,
                  isRefreshing: this.viewModel.isRefreshing,
                  onMusicClick: async (musicItem, index) => {
                    this.viewModel.setPlayList(this.viewModel.newMusicList, index)
                    await this.viewModel.playMusic(musicItem.rid)
                    this.musicUrl = this.viewModel.musicUrl
                  },
                  onDownloadClick: (musicItem) => {
                    console.log('下载歌曲:', musicItem.name)
                  },
                  onCollectClick: (musicItem) => {
                    console.log('收藏歌曲:', musicItem.name)
                  },
                  onRefresh: async () => {
                    console.log('新歌下拉刷新')
                    await this.viewModel.loadNewMusicList()
                  }
                })

                // 随机
                MusicTabContent({
                  tabTitle: '随机',
                  musicList: this.viewModel.randomMusicList,
                  isRefreshing: this.viewModel.isRefreshing,
                  onMusicClick: async (musicItem, index) => {
                    this.viewModel.setPlayList(this.viewModel.randomMusicList, index)
                    await this.viewModel.playMusic(musicItem.rid)
                    this.musicUrl = this.viewModel.musicUrl
                  },
                  onDownloadClick: (musicItem) => {
                    console.log('下载歌曲:', musicItem.name)
                  },
                  onCollectClick: (musicItem) => {
                    console.log('收藏歌曲:', musicItem.name)
                  },
                  onRefresh: async () => {
                    console.log('随机歌曲下拉刷新')
                    await this.viewModel.loadRandomMusicList()
                  }
                })
                if (!this.viewModel.collection) {
                  TabContent() {
                    this.CollectionView()
                  }
                  .tabBar('收藏')
                }
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
            currentSongName: this.viewModel.musicRes.data?.url ? '正在播放' : '',
            currentArtist: '',
            onLrcClick: () => this.viewModel.toggleLyrics(),
            onProgressUpdate: (progress: number) => {
              this.viewModel.currentProgress = progress
              this.viewModel.updateCurrentLyricIndex()
            },
            onPreviousClick: async () => {
              await this.viewModel.playPrevious()
              this.musicUrl = this.viewModel.musicUrl
            },
            onNextClick: async () => {
              await this.viewModel.playNext()
              this.musicUrl = this.viewModel.musicUrl
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

  @Builder
  LyricsView() {
    Column() {
      // 歌曲信息
      Column() {
        Text(this.viewModel.currentPlayList[this.viewModel.currentPlayIndex]?.name || '')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.viewModel.currentPlayList[this.viewModel.currentPlayIndex]?.artist || '')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20, bottom: 20 })

      List({ scroller: this.viewModel.scroller }) {
        ForEach(this.viewModel.currentLyricLines, (item: musicInfo, index: number) => {
          ListItem() {
            Text(item.text)
              .fontSize(index === this.viewModel.currentLyricIndex ? 22 : 16)
              .fontWeight(index === this.viewModel.currentLyricIndex ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(index === this.viewModel.currentLyricIndex ? '#39c5bb' : '#666666')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 8, bottom: 8 })
              .opacity(index === this.viewModel.currentLyricIndex ? 1 : 0.5)
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
              .scale({
                x: index === this.viewModel.currentLyricIndex ? 1.1 : 1,
                y: index === this.viewModel.currentLyricIndex ? 1.1 : 1
              })
              .animation({
                duration: 300,
                curve: Curve.EaseOut
              })
          }
        }, (item: musicInfo, index: number) => index.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Color.Transparent)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .alignListItem(ListItemAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor('#ffffffff')
  }

  @Builder
  CollectionView() {
    Column() {
      Text('我的收藏')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
        .fontColor('#333333')

      Text('暂无收藏歌曲')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
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
          isRefreshing: false,
          onMusicClick: async (musicItem, index) => {
            this.viewModel.setPlayList(this.viewModel.searchMusicList, index)
            await this.viewModel.playMusic(musicItem.rid)
            this.musicUrl = this.viewModel.musicUrl
          },
          onDownloadClick: (musicItem) => {
            console.log('下载歌曲:', musicItem.name)
          },
          onCollectClick: (musicItem) => {
            console.log('收藏歌曲:', musicItem.name)
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
}
