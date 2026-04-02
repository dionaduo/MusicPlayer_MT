import { musicList } from '../pages/musicResp'
import { MusicListItem } from './MusicListItem'

@ComponentV2
export struct MusicListContainer {
  @Param musicList: musicList[] = []
  @Param @Require isRefreshing: boolean
  @Event onMusicClick?: (item: musicList, index: number) => void
  @Event onDownloadClick?: (item: musicList) => void
  @Event onCollectClick?: (item: musicList) => void
  @Event onRefresh?: () => void

  build() {
    Scroll() {
      Refresh({ refreshing: this.isRefreshing }) {
        List() {
          ForEach(this.musicList, (item: musicList, index: number) => {
            ListItem() {
              MusicListItem({
                item: item,
                index: index,
                onMusicClick: (musicItem) => {
                  this.onMusicClick?.(musicItem, index)
                },
                onDownloadClick: (musicItem) => {
                  this.onDownloadClick?.(musicItem)
                },
                onCollectClick: (musicItem) => {
                  this.onCollectClick?.(musicItem)
                }
              })
            }
          }, (item: musicList, index: number) => item.rid + index.toString())
        }.height('100%').padding({ bottom: 10 })
      }
      .onStateChange((refreshingStatus: RefreshStatus) => {
        if (refreshingStatus === RefreshStatus.Refresh) {
          this.onRefresh?.()
          if (this.musicList) {
            !this.isRefreshing
          }
        }
      })
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
