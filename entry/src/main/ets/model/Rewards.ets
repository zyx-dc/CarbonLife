import { BadgeDef, DailyTask, KnowledgeItem, CarbonRecord, QuizQuestion, TaskRewardRecord } from './CarbonTypes';
import { CarbonStore } from './CarbonStore';
import { DateUtil } from '../common/DateUtil';
import { AppConst } from '../common/Constants';

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
    return Math.floor(store.totalSaved() / AppConst.TREE_PER_KG);
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

  /**
   * 结算今日任务奖励：对「已完成但今日尚未发放」的任务发放积分。
   * 幂等——同一天同一任务只发放一次。返回本次新发放的任务数。
   */
  static syncTaskRewards(store: CarbonStore): number {
    const now = Date.now();
    const dateKey = DateUtil.dayKey(now);
    const pending: TaskRewardRecord[] = [];
    Rewards.TASKS.forEach((t: DailyTask) => {
      if (Rewards.taskDone(t.key, store) && !store.hasTaskReward(dateKey, t.key)) {
        pending.push({ dateKey: dateKey, taskKey: t.key, points: t.points, timestamp: now });
      }
    });
    if (pending.length > 0) {
      store.addTaskRewards(pending);
    }
    return pending.length;
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
      summary: '排放达峰后转入下降，排放与吸收相抵即为中和。',
      content: '碳达峰是指二氧化碳排放量达到历史最高值后，经历平台期进入持续下降的过程；碳中和是指在一定时期内，通过植树造林、节能减排等形式抵消自身排放，实现“净零排放”。这是我国面向世界的庄严承诺，也是一场广泛而深刻的经济社会系统性变革。',
      points: [
        '碳达峰：排放量达到峰值后不再增长',
        '碳中和：排放与吸收相抵消，净排放为零',
        '国家目标：2030 年前碳达峰、2060 年前碳中和',
        '关键路径：能源转型、节能提效、生态碳汇'
      ],
      factLabel: '国家目标',
      fact: '2030 碳达峰 · 2060 碳中和',
      readMin: 2
    },
    {
      id: 'k2',
      title: '日常出行的碳足迹对比',
      tag: '绿色出行',
      summary: '步行骑行几乎零排放，公交地铁次之，私家车最高。',
      content: '不同出行方式单位里程的碳排放差异明显。步行和骑行几乎不产生碳排放；公交车、地铁因人均分摊而排放较低；私家燃油车排放最高。短途出行优先步行或骑行，中长途优先公共交通，是最直接、最易坚持的减排方式。',
      points: [
        '步行 / 骑行：几乎零排放，还能锻炼身体',
        '公交 / 地铁：人均排放低，适合中长途',
        '私家燃油车：单位里程排放最高',
        '原则：短途走路骑车，中长途乘公共交通'
      ],
      factLabel: '相比驾车每公里可减排',
      fact: '骑行 0.17 · 公交 0.12 · 地铁 0.14 kg',
      readMin: 2
    },
    {
      id: 'k3',
      title: '家庭节能的 5 个小技巧',
      tag: '节能降碳',
      summary: '空调、照明与待机能耗是家庭用电的主要来源。',
      content: '家庭用电是居民碳排放的重要来源。空调温度、照明灯具、待机电器都藏着大量可节约的空间。养成随手关灯、拔掉闲置插头、集中洗涤等小习惯，长期累积的减排效果非常可观，也能直接降低电费。',
      points: [
        '空调夏季不低于 26℃，每调高 1℃ 更省电',
        '照明尽量更换为 LED 节能灯',
        '拔掉待机电器插头，减少“隐形耗电”',
        '冰箱远离热源、定期除霜；洗衣集中洗涤'
      ],
      factLabel: '节能换算',
      fact: '每节约 1 度电 ≈ 减排 0.581 kg CO₂e',
      readMin: 2
    },
    {
      id: 'k4',
      title: '垃圾分类与回收的价值',
      tag: '循环利用',
      summary: '回收让材料重生，显著降低原生生产排放。',
      content: '废纸、塑料、金属、玻璃、旧衣物等可再生资源回收后重新利用，可显著减少原生材料生产过程中的能耗与排放。投放前简单清洗、正确分类，能提高再生质量。旧衣回收的减排系数最高，千万不要随手丢弃。',
      points: [
        '废纸、塑料、金属、玻璃、旧衣皆可回收',
        '回收可减少原生材料生产的能耗与排放',
        '投放前简单清洗、正确分类，提高再生质量',
        '旧衣回收减排系数最高，别随手丢弃'
      ],
      factLabel: '每回收 1 kg 可减排',
      fact: '废纸 0.9 · 塑料 1.5 · 金属 2.0 · 旧衣 2.5 kg',
      readMin: 2
    },
    {
      id: 'k5',
      title: '光盘行动与低碳饮食',
      tag: '低碳生活',
      summary: '减少食物浪费、增加素食都能降低碳排放。',
      content: '食物从生产、运输到烹饪都伴随碳排放，浪费食物等于浪费这些碳排放。践行光盘行动、按需点餐、减少一次性餐具使用，并适当增加素食比例，都是简单有效、对身体也友好的低碳饮食方式。',
      points: [
        '食物全生命周期都伴随碳排放',
        '光盘行动 = 减少浪费 = 减少排放',
        '适当增加素食比例，减排又健康',
        '自带餐具，减少一次性用品'
      ],
      factLabel: '每素食 1 餐',
      fact: '约减排 1.0 kg CO₂e',
      readMin: 2
    },
    {
      id: 'k6',
      title: '个人碳足迹如何计算',
      tag: '知识科普',
      summary: '碳足迹 = 活动量 × 排放因子。',
      content: '个人碳足迹通常采用“活动数据 × 排放因子”的方式估算。排放因子来自权威机构的实测与统计，反映了单位活动量对应的碳排放强度。本应用内置常见低碳行为的排放因子库，你只需录入活动量，即可自动估算减排量。',
      points: [
        '核心公式：碳足迹 = 活动量 × 排放因子',
        '排放因子来自权威机构的实测与统计',
        '本应用内置常见低碳行为的因子库',
        '录入活动量即可自动估算减排量'
      ],
      factLabel: '计算示例',
      fact: '骑行 10 km × 0.17 = 1.70 kg CO₂e',
      readMin: 2
    }
  ];
}

export function knowledgeCover(id: string): Resource {
  switch (id) {
    case 'k1': return $r('app.media.photo_policy');
    case 'k2': return $r('app.media.photo_travel');
    case 'k3': return $r('app.media.photo_energy');
    case 'k4': return $r('app.media.photo_recycle');
    case 'k5': return $r('app.media.photo_food');
    case 'k6': return $r('app.media.photo_calc');
    default: return $r('app.media.photo_policy');
  }
}

export class QuizData {
  static readonly MAX: number = 15;

  static readonly QUESTIONS: QuizQuestion[] = [
    { id: 'q1', q: '日常通勤主要方式？', options: [ { label: '步行 / 骑行', score: 3 }, { label: '公共交通', score: 2 }, { label: '私家车', score: 0 } ] },
    { id: 'q2', q: '夏天家里空调一般设多少度？', options: [ { label: '26℃ 及以上', score: 3 }, { label: '24–25℃', score: 2 }, { label: '低于 24℃', score: 0 } ] },
    { id: 'q3', q: '践行光盘行动的情况？', options: [ { label: '几乎每餐', score: 3 }, { label: '经常', score: 2 }, { label: '偶尔', score: 0 } ] },
    { id: 'q4', q: '垃圾分类与回收的习惯？', options: [ { label: '总是分类', score: 3 }, { label: '有时分类', score: 1 }, { label: '很少分类', score: 0 } ] },
    { id: 'q5', q: '一次性餐具的使用？', options: [ { label: '自带餐具', score: 3 }, { label: '偶尔使用', score: 1 }, { label: '经常使用', score: 0 } ] }
  ];

  static level(score: number): string {
    if (score >= 12) {
      return '低碳达人';
    }
    if (score >= 8) {
      return '绿色践行者';
    }
    if (score >= 4) {
      return '低碳新手';
    }
    return '待加油';
  }

  static tip(score: number): string {
    if (score >= 12) {
      return '非常棒！你的生活方式已经相当低碳，继续保持并带动身边的人。';
    }
    if (score >= 8) {
      return '不错！在出行或节能上再前进一步，就能迈入达人行列。';
    }
    if (score >= 4) {
      return '已经有低碳意识，试着从绿色出行和光盘行动开始改变。';
    }
    return '别灰心，低碳生活从每一次小选择开始，去「记录」里打卡吧。';
  }
}
