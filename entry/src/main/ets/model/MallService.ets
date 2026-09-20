import { util } from '@kit.ArkTS';
import { CarbonStore } from './CarbonStore';
import { RedeemItem, RedemptionRecord } from './CarbonTypes';

export interface RedeemResult {
  ok: boolean;
  message: string;
  code: string;
}

export class MallService {
  static readonly ITEMS: RedeemItem[] = [
    { id: 'm1', name: '低碳徽章·青铜', desc: '虚拟荣誉徽章，点亮你的荣誉墙', cost: 100, icon: '🥉', category: '荣誉' },
    { id: 'm2', name: '共享单车骑行券', desc: '碳普惠权益：1 次免费骑行', cost: 200, icon: '🚲', category: '出行' },
    { id: 'm3', name: '地铁 9 折券', desc: '碳普惠权益：地铁乘车优惠', cost: 300, icon: '🚇', category: '出行' },
    { id: 'm4', name: '环保购物袋', desc: '碳普惠权益：可降解环保袋', cost: 150, icon: '🛍️', category: '生活' },
    { id: 'm5', name: '认养一棵树', desc: '以你的名义在碳普惠平台认养一棵树', cost: 500, icon: '🌳', category: '公益' },
    { id: 'm6', name: '城市碳普惠电子证书', desc: '碳普惠平台颁发的电子荣誉证书', cost: 800, icon: '🏆', category: '荣誉' }
  ];

  static redeem(item: RedeemItem): RedeemResult {
    const store = CarbonStore.get();
    if (store.pointsBalance() < item.cost) {
      const lack = item.cost - store.pointsBalance();
      return { ok: false, message: '积分不足，还差 ' + lack.toString() + ' 分', code: '' };
    }
    const code = MallService.mockExchangeCode(item);
    const rec: RedemptionRecord = {
      id: util.generateRandomUUID(true),
      itemId: item.id,
      itemName: item.name,
      cost: item.cost,
      timestamp: Date.now()
    };
    store.addRedemption(rec);
    return { ok: true, message: '兑换成功', code: code };
  }

  private static mockExchangeCode(item: RedeemItem): string {
    const rand = Math.floor(Math.random() * 900000 + 100000);
    return 'CP' + item.id.toUpperCase() + rand.toString();
  }
}
