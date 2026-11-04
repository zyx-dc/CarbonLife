import { distributedKVStore } from '@kit.ArkData';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { common } from '@kit.AbilityKit';

/**
 * 家庭组的分布式 KV 封装（docs/ROADMAP.md 方案 A）。
 *
 * 关键点：
 * - 必须用 SINGLE_VERSION：DEVICE_COLLABORATION 的 getEntries(prefix) 只读本机分区，
 *   对端数据虽然同步过来了也读不到，表现就是“永远 1 个成员”；
 * - storeId 只允许 [A-Za-z0-9_]，家庭码统一加 `fam_` 前缀；
 * - sync 的 deviceIds 是 networkId（不是 deviceId），且只在同账号可信组网里才非空。
 *
 * 同步时机（「拔掉调试线就不同步」的真正原因）：
 * - autoSync 必须为 true，否则系统不会在设备上线时自动补一次 PUSH_PULL；
 * - 还必须监听 deviceStateChange：本机没有新事件时，只有这一个事件能触发补推；
 * - sync() 返回目标设备数，为 0 表示软总线尚未发现对端，由 FamilyService 安排退避重试。
 */
const BUNDLE = 'com.example.carbonlife';
const PREFIX = 'member:';

/** deviceStateChange 的回调参数，与 @ohos.distributedDeviceManager 的匿名类型保持一致。 */
interface DeviceStateEvent {
  action: distributedDeviceManager.DeviceStateChange;
  device: distributedDeviceManager.DeviceBasicInfo;
}

export class FamilyKvStore {
  private manager: distributedKVStore.KVManager | null = null;
  private store: distributedKVStore.SingleKVStore | null = null;
  private storeId: string = '';
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private listening: boolean = false;
  private opening: string | null = null;
  private watching: boolean = false;
  private lastOkAt: number = 0;

  async open(ctx: common.Context, storeId: string): Promise<void> {
    if (this.store !== null && this.storeId === storeId) {
      return;
    }
    if (this.opening === storeId) {
      return;
    }
    this.opening = storeId;
    try {
      if (this.manager === null) {
        this.manager = distributedKVStore.createKVManager({ context: ctx, bundleName: BUNDLE });
      }
      if (this.store !== null) {
        try {
          this.store.off('dataChange');
          this.store.off('syncComplete');
        } catch (e) {
          console.warn('FamilyKvStore off listeners failed: ' + JSON.stringify(e));
        }
        try {
          await this.manager.closeKVStore(BUNDLE, this.storeId);
        } catch (e) {
          console.warn('FamilyKvStore close old store failed: ' + JSON.stringify(e));
        }
        this.store = null;
        this.listening = false;
      }
      this.store = await this.manager.getKVStore<distributedKVStore.SingleKVStore>(storeId, {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        // 关键：true 时设备上线系统会自动补一次 PUSH_PULL；false 则只能靠手动 sync，
        // 而手动 sync 在冷启动那一刻常常查不到对端，之后就再也没有重试时机。
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      });
      this.storeId = storeId;
      console.info('FamilyKvStore open store=' + storeId);
    } finally {
      this.opening = null;
    }
  }

  onChanged(cb: () => void): void {
    if (this.store === null || this.listening) {
      return;
    }
    this.listening = true;
    this.store.on('dataChange', distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL, () => {
      console.info('FamilyKvStore dataChange');
      cb();
    });
    this.store.on('syncComplete', (result: Array<[string, number]>) => {
      // 必须「全部设备成功」才算成功：2 人家庭只有一台时 any/all 等价，
      // 但 3 人以上只要有一台失败就判成功，会让重试被提前清掉、缺口被掩盖。
      let allOk: boolean = result.length > 0;
      result.forEach((item: [string, number]) => {
        if (item[1] !== 0) {
          allOk = false;
        }
      });
      if (allOk) {
        this.lastOkAt = Date.now();
      }
      console.info('FamilyKvStore syncComplete ok=' + allOk + ' ' + JSON.stringify(result));
      cb();
    });
  }

  /** 上次同步成功的时间戳；0 表示从未成功过。 */
  lastSuccessAt(): number {
    return this.lastOkAt;
  }

  /**
   * 监听同账号可信设备的上下线。
   *
   * 这是「离线期间写入、对端回来再补推」的唯一触发点：本机没有新写入时，
   * 只有对端上线能把积压的变更送出去。只注册一次，切家庭组不重复挂监听。
   */
  watchPeers(cb: () => void): void {
    if (this.watching) {
      return;
    }
    const dm = this.ensureDeviceManager();
    if (dm === null) {
      return;
    }
    try {
      dm.on('deviceStateChange', (data: DeviceStateEvent) => {
        const online: boolean = data.action === distributedDeviceManager.DeviceStateChange.AVAILABLE;
        console.info('FamilyKvStore deviceState action=' + data.action +
          ' online=' + online + ' id=' + data.device.networkId);
        if (online) {
          cb();
        }
      });
      this.watching = true;
      console.info('FamilyKvStore watchPeers ok');
    } catch (e) {
      console.error('FamilyKvStore watchPeers failed: ' + JSON.stringify(e));
    }
  }

  /** 当前可用的可信设备数（不含本机）。 */
  peerCount(): number {
    const dm = this.ensureDeviceManager();
    if (dm === null) {
      return 0;
    }
    try {
      return dm.getAvailableDeviceListSync().length;
    } catch (e) {
      console.warn('FamilyKvStore peerCount failed: ' + JSON.stringify(e));
      return 0;
    }
  }

  async put(deviceId: string, json: string): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.put(PREFIX + deviceId, json);
  }

  async remove(deviceId: string): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.delete(PREFIX + deviceId);
  }

  async readAll(): Promise<string[]> {
    if (this.store === null) {
      return [];
    }
    const entries = await this.store.getEntries(PREFIX);
    const keys: string[] = [];
    const out: string[] = [];
    entries.forEach((entry: distributedKVStore.Entry) => {
      keys.push(entry.key);
      if (entry.value.type === distributedKVStore.ValueType.STRING &&
        typeof entry.value.value === 'string') {
        out.push(entry.value.value);
      }
    });
    console.info('FamilyKvStore read entries=' + entries.length + ' keys=' + keys.join(','));
    return out;
  }

  /**
   * 与同账号可信设备做一次 PUSH_PULL，返回本次的目标设备数。
   * 返回 0 说明软总线还没发现对端（冷启动最常见），调用方应安排退避重试。
   */
  sync(): number {
    if (this.store === null) {
      return 0;
    }
    try {
      const dm = this.ensureDeviceManager();
      if (dm === null) {
        return 0;
      }
      const devices = dm.getAvailableDeviceListSync();
      const ids: string[] = [];
      devices.forEach((device: distributedDeviceManager.DeviceBasicInfo) => {
        if (device.networkId !== undefined && device.networkId !== '') {
          ids.push(device.networkId);
        }
      });
      console.info('FamilyKvStore sync targets=' + ids.length + ' ids=' + ids.join(','));
      if (ids.length === 0) {
        return 0;
      }
      this.store.sync(ids, distributedKVStore.SyncMode.PUSH_PULL);
      return ids.length;
    } catch (e) {
      console.error('FamilyKvStore sync failed: ' + JSON.stringify(e));
      return 0;
    }
  }

  /** 本机的系统级设备 ID（udid-hash + appid 派生），比随机 UUID 更适合做成员键。 */
  localDeviceId(): string {
    try {
      const dm = this.ensureDeviceManager();
      if (dm !== null) {
        return dm.getLocalDeviceId();
      }
    } catch (e) {
      console.warn('FamilyKvStore getLocalDeviceId failed: ' + JSON.stringify(e));
    }
    return '';
  }

  private ensureDeviceManager(): distributedDeviceManager.DeviceManager | null {
    try {
      if (this.deviceManager === null) {
        this.deviceManager = distributedDeviceManager.createDeviceManager(BUNDLE);
      }
      return this.deviceManager;
    } catch (e) {
      console.error('FamilyKvStore createDeviceManager failed: ' + JSON.stringify(e));
      return null;
    }
  }
}
