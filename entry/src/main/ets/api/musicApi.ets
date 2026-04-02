import { request } from '../utils/request'
import { GetMusicInfoParams, GetMusicListParams, musicData, musicList, musicResponse } from '../model/musicResp'

//获取歌曲的详细信息
export async function getMusicInfo(params: GetMusicInfoParams): Promise<musicResponse<musicData>> {
  params = {
    rid: params.rid,
    type: params.type || 'json',
    level: params.level || 'exhigh',
    lrc: params.lrc || true
  }
  return request.get('kw.php', { params })
}

//获取歌曲列表
export async function getMusicList(params?: GetMusicListParams): Promise<musicResponse<musicList[]>> {
  return request.get('songs.php', { params })
}
