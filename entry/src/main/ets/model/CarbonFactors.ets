import { BehaviorDef } from './CarbonTypes';
import { AppColor } from '../common/Constants';
import { ThemeTokens } from '../common/Theme';

export class CarbonFactors {
  static readonly CATEGORIES: string[] = ['出行', '节能', '回收', '餐饮'];

  // 类别数据色：全部落在「夜行荧光」绿系（青柠→电青→次级青柠→苔绿），四类可区分且不跑色
  static categoryColor(category: string): string {
    if (category === '出行') {
      return AppColor.SIGNAL;
    } else if (category === '节能') {
      return AppColor.ACCENT;
    } else if (category === '回收') {
      return AppColor.PRIMARY_LIGHT;
    }
    return ThemeTokens.SEA;
  }

  static readonly BEHAVIORS: BehaviorDef[] = [
    {
      key: 'walk',
      category: '出行',
      name: '步行替代驾车',
      unit: 'km',
      factor: 0.17,
      step: 1,
      icon: '🚶',
      tip: '每步行 1 公里，约减排 0.17 kg CO₂e'
    },
    {
      key: 'bike',
      category: '出行',
      name: '骑行替代驾车',
      unit: 'km',
      factor: 0.17,
      step: 1,
      icon: '🚲',
      tip: '每骑行 1 公里，约减排 0.17 kg CO₂e'
    },
    {
      key: 'bus',
      category: '出行',
      name: '公交替代驾车',
      unit: 'km',
      factor: 0.12,
      step: 1,
      icon: '🚌',
      tip: '每乘坐公交 1 公里，约减排 0.12 kg CO₂e'
    },
    {
      key: 'subway',
      category: '出行',
      name: '地铁替代驾车',
      unit: 'km',
      factor: 0.14,
      step: 1,
      icon: '🚇',
      tip: '每乘坐地铁 1 公里，约减排 0.14 kg CO₂e'
    },
    {
      key: 'save_power',
      category: '节能',
      name: '节约用电',
      unit: 'kWh',
      factor: 0.581,
      step: 0.5,
      icon: '💡',
      tip: '每节约 1 度电，约减排 0.581 kg CO₂e'
    },
    {
      key: 'save_water',
      category: '节能',
      name: '节约用水',
      unit: 'L',
      factor: 0.0003,
      step: 5,
      icon: '🚰',
      tip: '每节约 1 升水，约减排 0.0003 kg CO₂e'
    },
    {
      key: 'recycle_paper',
      category: '回收',
      name: '回收纸张',
      unit: 'kg',
      factor: 0.9,
      step: 0.5,
      icon: '📄',
      tip: '每回收 1 kg 废纸，约减排 0.9 kg CO₂e'
    },
    {
      key: 'recycle_plastic',
      category: '回收',
      name: '回收塑料',
      unit: 'kg',
      factor: 1.5,
      step: 0.5,
      icon: '♻️',
      tip: '每回收 1 kg 塑料，约减排 1.5 kg CO₂e'
    },
    {
      key: 'recycle_metal',
      category: '回收',
      name: '回收金属',
      unit: 'kg',
      factor: 2.0,
      step: 0.5,
      icon: '🔩',
      tip: '每回收 1 kg 金属，约减排 2.0 kg CO₂e'
    },
    {
      key: 'recycle_clothes',
      category: '回收',
      name: '旧衣回收',
      unit: 'kg',
      factor: 2.5,
      step: 0.5,
      icon: '👕',
      tip: '每回收 1 kg 旧衣，约减排 2.5 kg CO₂e'
    },
    {
      key: 'clean_plate',
      category: '餐饮',
      name: '光盘行动',
      unit: '餐',
      factor: 0.5,
      step: 1,
      icon: '🍚',
      tip: '每减少 1 餐浪费，约减排 0.5 kg CO₂e'
    },
    {
      key: 'no_disposable',
      category: '餐饮',
      name: '少用一次性餐具',
      unit: '次',
      factor: 0.05,
      step: 1,
      icon: '🥢',
      tip: '每少用 1 次一次性餐具，约减排 0.05 kg CO₂e'
    },
    {
      key: 'veg_meal',
      category: '餐饮',
      name: '素食一餐',
      unit: '餐',
      factor: 1.0,
      step: 1,
      icon: '🥗',
      tip: '每素食 1 餐，约减排 1.0 kg CO₂e'
    }
  ];

  static getByCategory(category: string): BehaviorDef[] {
    return CarbonFactors.BEHAVIORS.filter((b: BehaviorDef) => b.category === category);
  }

  static find(key: string): BehaviorDef {
    const list: BehaviorDef[] = CarbonFactors.BEHAVIORS.filter((b: BehaviorDef) => b.key === key);
    return list.length > 0 ? list[0] : CarbonFactors.BEHAVIORS[0];
  }
}

export function behaviorIcon(key: string): Resource {
  switch (key) {
    case 'walk': return $r('app.media.ic_walk');
    case 'bike': return $r('app.media.ic_bike');
    case 'bus': return $r('app.media.ic_bus');
    case 'subway': return $r('app.media.ic_subway');
    case 'save_power': return $r('app.media.ic_power');
    case 'save_water': return $r('app.media.ic_water');
    case 'recycle_paper': return $r('app.media.ic_paper');
    case 'recycle_plastic': return $r('app.media.ic_recycle');
    case 'recycle_metal': return $r('app.media.ic_metal');
    case 'recycle_clothes': return $r('app.media.ic_clothes');
    case 'clean_plate': return $r('app.media.ic_clean_plate');
    case 'no_disposable': return $r('app.media.ic_chopsticks');
    case 'veg_meal': return $r('app.media.ic_veg');
    default: return $r('app.media.ic_leaf');
  }
}
