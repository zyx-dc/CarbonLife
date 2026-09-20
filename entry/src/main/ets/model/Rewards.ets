import { BadgeDef, DailyTask, KnowledgeItem, CarbonRecord } from './CarbonTypes';
import { CarbonStore } from './CarbonStore';

export class Rewards {
  static readonly BADGES: BadgeDef[] = [
    { key: 'b1', name: '初识低碳', desc: '累计减排达到 1 kg CO₂e', icon: '🌱', target: 1 },
    { key: 'b2', name: '绿色出行家', desc: '出行类累计减排 5 kg CO₂e', icon: '🚲', target: 5 },
    { key: 'b3', name: '节能小能手', desc: '节能类累计减排 3 kg CO₂e', icon: '💡', target: 3 },
    { key: 'b4', name: '回收先锋', desc: '回收类累计减排 5 kg CO₂e', icon: '♻️', target: 5 },
    { key: 'b5', name: '光盘行动派', desc: '光盘行动累计 10 次', icon: '🍚', target: 10 },
    { key: 'b6', name: '低碳达人', desc: '累计减排达到 20 kg CO₂e', icon: '🏅', target: 20 },
    { key: 'b7', name: '碳中和先锋', desc: '累计减排达到 50 kg CO₂e', icon: '🌍', target: 50 }
  ];

  static readonly TASKS: DailyTask[] = [
    { key: 't1', name: '绿色出行', desc: '今日步行/骑行/公交出行 1 次', points: 20 },
    { key: 't2', name: '光盘行动', desc: '今日完成光盘行动 1 次', points: 20 },
    { key: 't3', name: '坚持记录', desc: '今日记录低碳行为 1 条', points: 10 },
    { key: 't4', name: '节能有我', desc: '今日节约用电或用水 1 次', points: 15 }
  ];

  static badgeProgress(key: string, store: CarbonStore): number {
    if (key === 'b2') {
      return store.savedByCategoryOf('出行');
    } else if (key === 'b3') {
      return store.savedByCategoryOf('节能');
    } else if (key === 'b4') {
      return store.savedByCategoryOf('回收');
    } else if (key === 'b5') {
      return store.countByBehavior('clean_plate');
    }
    return store.totalSaved();
  }

  static isUnlocked(badge: BadgeDef, store: CarbonStore): boolean {
    return Rewards.badgeProgress(badge.key, store) >= badge.target;
  }

  static unlockedCount(store: CarbonStore): number {
    let n = 0;
    Rewards.BADGES.forEach((b: BadgeDef) => {
      if (Rewards.isUnlocked(b, store)) {
        n += 1;
      }
    });
    return n;
  }

  static treeCount(store: CarbonStore): number {
    return Math.floor(store.totalSaved() / 10);
  }

  static taskDone(taskKey: string, store: CarbonStore): boolean {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const list = store.recordsInRange(start.getTime(), Date.now() + 1);
    if (taskKey === 't1') {
      return list.some((r: CarbonRecord) => r.category === '出行');
    } else if (taskKey === 't2') {
      return list.some((r: CarbonRecord) => r.behaviorKey === 'clean_plate');
    } else if (taskKey === 't3') {
      return list.length > 0;
    } else if (taskKey === 't4') {
      return list.some((r: CarbonRecord) => r.behaviorKey === 'save_power' || r.behaviorKey === 'save_water');
    }
    return false;
  }

  static suggestions(store: CarbonStore): string[] {
    const tips: string[] = [];
    if (store.totalCount() === 0) {
      tips.push('从今天开始记录第一条低碳行为吧，步行、光盘行动都很简单。');
      tips.push('建议每天通勤优先选择步行、骑行或公共交通。');
      return tips;
    }
    const travel = store.savedByCategoryOf('出行');
    const energy = store.savedByCategoryOf('节能');
    const recycle = store.savedByCategoryOf('回收');
    const food = store.savedByCategoryOf('餐饮');
    if (travel < energy || travel < 1) {
      tips.push('出行类减排偏低，尝试每周 2 天绿色通勤，减排提升最明显。');
    }
    if (energy < 1) {
      tips.push('随手关灯、空调调高 1℃，每度电可减排约 0.581 kg CO₂e。');
    }
    if (recycle < 1) {
      tips.push('把废纸、塑料瓶、旧衣物分类回收，回收减排系数更高。');
    }
    if (food < 1) {
      tips.push('坚持光盘行动，每周多吃一餐素食，减排又健康。');
    }
    if (store.todayCount() === 0) {
      tips.push('今天还没有记录，别忘了记录你的低碳行为哦。');
    }
    if (tips.length === 0) {
      tips.push('表现很棒！可以尝试挑战更高阶的减排目标。');
    }
    return tips;
  }
}

export class KnowledgeData {
  static readonly LIST: KnowledgeItem[] = [
    {
      id: 'k1',
      title: '什么是碳达峰与碳中和',
      tag: '双碳政策',
      summary: '碳达峰指排放量达到峰值后不再增长，碳中和指排放与吸收相抵消。',
      content: '碳达峰是指二氧化碳排放量达到历史最高值后，经历平台期进入持续下降的过程。碳中和是指在一定时期内，通过植树造林、节能减排等形式，抵消自身产生的二氧化碳排放，实现二氧化碳“零排放”。我国提出力争 2030 年前实现碳达峰、2060 年前实现碳中和。'
    },
    {
      id: 'k2',
      title: '日常出行的碳足迹对比',
      tag: '绿色出行',
      summary: '步行、骑行几乎零排放，公交地铁次之，私家车最高。',
      content: '不同出行方式单位里程碳排放差异明显：步行和骑行几乎不产生碳排放；公交车、地铁因人均分摊而排放较低；私家燃油车排放最高。短途出行优先步行或骑行，中长途优先公共交通，是最直接的减排方式。'
    },
    {
      id: 'k3',
      title: '家庭节能的 5 个小技巧',
      tag: '节能降碳',
      summary: '空调、照明、待机能耗是家庭用电的主要来源。',
      content: '1. 空调夏季设定不低于 26℃；2. 使用 LED 节能灯；3. 拔掉不用的电器插头，减少待机耗电；4. 洗衣机集中洗涤；5. 冰箱远离热源并定期除霜。每节约 1 度电，约减排 0.581 kg 二氧化碳。'
    },
    {
      id: 'k4',
      title: '垃圾分类与回收的价值',
      tag: '循环利用',
      summary: '回收 1 kg 塑料约减排 1.5 kg CO₂e。',
      content: '废纸、塑料、金属、玻璃、旧衣物等可再生资源回收后重新利用，可显著减少原生材料生产过程中的能耗与排放。例如每回收 1 kg 废纸约减排 0.9 kg，每回收 1 kg 塑料约减排 1.5 kg，每回收 1 kg 旧衣约减排 2.5 kg。'
    },
    {
      id: 'k5',
      title: '光盘行动与低碳饮食',
      tag: '低碳生活',
      summary: '减少食物浪费、多吃素食都能降低碳排放。',
      content: '食物从生产、运输到烹饪都伴随碳排放，浪费食物等于浪费这些碳排放。践行光盘行动、按需点餐、减少一次性餐具使用，适当增加素食比例，都是简单有效的低碳饮食方式。'
    },
    {
      id: 'k6',
      title: '个人碳足迹如何计算',
      tag: '知识科普',
      summary: '碳足迹 = 活动量 × 排放因子。',
      content: '个人碳足迹通常采用“活动数据 × 排放因子”的方式估算。例如出行减排量 = 行驶里程 × 单位里程排放因子。本应用内置常见低碳行为的排放因子库，用户只需录入活动量，即可自动计算减排量。'
    }
  ];
}
