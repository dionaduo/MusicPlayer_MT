export interface musicResponse<T> {
  code: number,
  msg: string,
  data: T
}

export interface musicData {
  url: string,
  lrc: string,
  processing_time: string
}

export interface musicInfo {
  time: number;
  text: string;
}

export interface musicList {
  rid: string;
  name: string;
  artist: string;
  pic: string;
  downurl: string[];
}

export interface GetMusicInfoParams {
  rid: string
  type?: string
  level?: string
  lrc?: boolean
}

export interface GetMusicListParams {
  type?: string
  keyword?: string
}

