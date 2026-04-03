import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

class PreferenceUtil {
  static readonly preferencesName = "myPreferences";
  dataPerference: preferences.Preferences | null = null;

  constructor() {
    this.init();
  }

  init() {
    if (this.dataPerference != null) {
      return
    }
    let context = AppStorage.get("myContext") as common.UIAbilityContext
      || getContext(this) as common.UIAbilityContext;
    this.dataPerference = preferences.getPreferencesSync(context, { name: PreferenceUtil.preferencesName })
  }

  get(key: string) {
    return this.dataPerference?.getSync(key, "")
  }

  put(key: string, value: preferences.ValueType) {
    this.dataPerference?.put(key, value)
    this.flush()
  }

  delete(key: string) {
    this.dataPerference?.deleteSync(key);
    this.flush()
  }

  flush() {
    this.dataPerference?.flushSync();
  }

  // 获取收藏歌曲的rid列表
  getCollectRidList(): string[] {
    const ridList = this.dataPerference?.getSync('collectRidList', '') as string
    if (!ridList) {
      return []
    }
    try {
      return JSON.parse(ridList)
    } catch (error) {
      console.error('解析收藏列表失败:', error)
      return []
    }
  }

  // 添加收藏歌曲rid
  addCollectRid(rid: string) {
    const ridList = this.getCollectRidList()
    if (!ridList.includes(rid)) {
      ridList.push(rid)
      this.put('collectRidList', JSON.stringify(ridList))
    }
  }

  // 移除收藏歌曲rid
  removeCollectRid(rid: string) {
    const ridList = this.getCollectRidList()
    const index = ridList.indexOf(rid)
    if (index > -1) {
      ridList.splice(index, 1)
      this.put('collectRidList', JSON.stringify(ridList))
    }
  }

  // 清空收藏列表
  clearCollectList() {
    this.put('collectRidList', '')
  }
}

export const preferenceUtil = new PreferenceUtil()