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
 */
const BUNDLE = 'com.example.carbonlife';
const PREFIX = 'member:';

export class FamilyKvStore {
  private manager: distributedKVStore.KVManager | null = null;
  private store: distributedKVStore.SingleKVStore | null = null;
  private storeId: string = '';
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private listening: boolean = false;
  private opening: string | null = null;

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
        autoSync: false,
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
      console.info('FamilyKvStore syncComplete ' + JSON.stringify(result));
      cb();
    });
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

  /** 与同账号可信设备做一次 PUSH_PULL；没有目标设备时明确打日志，避免静默失败。 */
  sync(): void {
    if (this.store === null) {
      return;
    }
    try {
      const dm = this.ensureDeviceManager();
      if (dm === null) {
        return;
      }
      const devices = dm.getAvailableDeviceListSync();
      const ids: string[] = [];
      devices.forEach((device: distributedDeviceManager.DeviceBasicInfo) => {
        if (device.networkId !== undefined && device.networkId !== '') {
          ids.push(device.networkId);
        }
      });
      console.info('FamilyKvStore sync targets=' + ids.length + ' ids=' + ids.join(','));
      if (ids.length > 0) {
        this.store.sync(ids, distributedKVStore.SyncMode.PUSH_PULL);
      }
    } catch (e) {
      console.error('FamilyKvStore sync failed: ' + JSON.stringify(e));
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
