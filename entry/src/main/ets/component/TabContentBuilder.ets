import { musicList } from '../pages/musicResp'
import { MusicListContainer } from './MusicListContainer'

@ComponentV2
export struct MusicTabContent {
  @Param musicList: musicList[] = []
  @Param tabTitle: string = ''
  @Param @Require isRefreshing: boolean
  @Event onMusicClick?: (item: musicList, index: number) => void
  @Event onDownloadClick?: (item: musicList) => void
  @Event onCollectClick?: (item: musicList) => void
  @Event onRefresh?: () => void

  build() {
    TabContent() {
      MusicListContainer({
        musicList: this.musicList,
        isRefreshing: this.isRefreshing,
        onMusicClick: this.onMusicClick,
        onDownloadClick: this.onDownloadClick,
        onCollectClick: this.onCollectClick,
        onRefresh: this.onRefresh
      })
    }
    .tabBar(this.tabTitle)
  }
}
