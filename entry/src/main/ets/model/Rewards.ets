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

  // 当日 0 点时间戳按天缓存：taskDone 会被高频调用，避免反复 new Date()
  private static dayStartKey: string = '';
  private static dayStartTs: number = 0;

  private static todayStart(): number {
    const key = DateUtil.dayKey(Date.now());
    if (key !== Rewards.dayStartKey) {
      Rewards.dayStartKey = key;
      Rewards.dayStartTs = DateUtil.startOfDay(Date.now());
    }
    return Rewards.dayStartTs;
  }

  static taskDone(taskKey: string, store: CarbonStore): boolean {
    const list = store.recordsInRange(Rewards.todayStart(), Date.now() + 1);
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

  static suggestions(store: CarbonStore): ResourceStr[] {
    const tips: ResourceStr[] = [];
    if (store.totalCount() === 0) {
      tips.push($r('app.string.tip_first_action'));
      tips.push($r('app.string.tip_commute'));
      return tips;
    }
    const travel = store.savedByCategoryOf('出行');
    const energy = store.savedByCategoryOf('节能');
    const recycle = store.savedByCategoryOf('回收');
    const food = store.savedByCategoryOf('餐饮');
    if (travel < energy || travel < 1) {
      tips.push($r('app.string.tip_travel_low'));
    }
    if (energy < 1) {
      tips.push($r('app.string.tip_energy_low'));
    }
    if (recycle < 1) {
      tips.push($r('app.string.tip_recycle_low'));
    }
    if (food < 1) {
      tips.push($r('app.string.tip_food_low'));
    }
    if (store.todayCount() === 0) {
      tips.push($r('app.string.tip_today_empty'));
    }
    if (tips.length === 0) {
      tips.push($r('app.string.tip_all_good'));
    }
    return tips;
  }
}

export class KnowledgeData {
  static readonly LIST: KnowledgeItem[] = [
    {
      id: 'k1',
      title: $r('app.string.knowledge_k1_title'),
      tag: $r('app.string.knowledge_k1_tag'),
      summary: $r('app.string.knowledge_k1_summary'),
      content: $r('app.string.knowledge_k1_content'),
      points: [
        $r('app.string.knowledge_k1_p1'),
        $r('app.string.knowledge_k1_p2'),
        $r('app.string.knowledge_k1_p3'),
        $r('app.string.knowledge_k1_p4')
      ],
      factLabel: $r('app.string.knowledge_k1_fact_label'),
      fact: $r('app.string.knowledge_k1_fact'),
      readMin: 2
    },
    {
      id: 'k2',
      title: $r('app.string.knowledge_k2_title'),
      tag: $r('app.string.knowledge_k2_tag'),
      summary: $r('app.string.knowledge_k2_summary'),
      content: $r('app.string.knowledge_k2_content'),
      points: [
        $r('app.string.knowledge_k2_p1'),
        $r('app.string.knowledge_k2_p2'),
        $r('app.string.knowledge_k2_p3'),
        $r('app.string.knowledge_k2_p4')
      ],
      factLabel: $r('app.string.knowledge_k2_fact_label'),
      fact: $r('app.string.knowledge_k2_fact'),
      readMin: 2
    },
    {
      id: 'k3',
      title: $r('app.string.knowledge_k3_title'),
      tag: $r('app.string.knowledge_k3_tag'),
      summary: $r('app.string.knowledge_k3_summary'),
      content: $r('app.string.knowledge_k3_content'),
      points: [
        $r('app.string.knowledge_k3_p1'),
        $r('app.string.knowledge_k3_p2'),
        $r('app.string.knowledge_k3_p3'),
        $r('app.string.knowledge_k3_p4')
      ],
      factLabel: $r('app.string.knowledge_k3_fact_label'),
      fact: $r('app.string.knowledge_k3_fact'),
      readMin: 2
    },
    {
      id: 'k4',
      title: $r('app.string.knowledge_k4_title'),
      tag: $r('app.string.knowledge_k4_tag'),
      summary: $r('app.string.knowledge_k4_summary'),
      content: $r('app.string.knowledge_k4_content'),
      points: [
        $r('app.string.knowledge_k4_p1'),
        $r('app.string.knowledge_k4_p2'),
        $r('app.string.knowledge_k4_p3'),
        $r('app.string.knowledge_k4_p4')
      ],
      factLabel: $r('app.string.knowledge_k4_fact_label'),
      fact: $r('app.string.knowledge_k4_fact'),
      readMin: 2
    },
    {
      id: 'k5',
      title: $r('app.string.knowledge_k5_title'),
      tag: $r('app.string.knowledge_k5_tag'),
      summary: $r('app.string.knowledge_k5_summary'),
      content: $r('app.string.knowledge_k5_content'),
      points: [
        $r('app.string.knowledge_k5_p1'),
        $r('app.string.knowledge_k5_p2'),
        $r('app.string.knowledge_k5_p3'),
        $r('app.string.knowledge_k5_p4')
      ],
      factLabel: $r('app.string.knowledge_k5_fact_label'),
      fact: $r('app.string.knowledge_k5_fact'),
      readMin: 2
    },
    {
      id: 'k6',
      title: $r('app.string.knowledge_k6_title'),
      tag: $r('app.string.knowledge_k6_tag'),
      summary: $r('app.string.knowledge_k6_summary'),
      content: $r('app.string.knowledge_k6_content'),
      points: [
        $r('app.string.knowledge_k6_p1'),
        $r('app.string.knowledge_k6_p2'),
        $r('app.string.knowledge_k6_p3'),
        $r('app.string.knowledge_k6_p4')
      ],
      factLabel: $r('app.string.knowledge_k6_fact_label'),
      fact: $r('app.string.knowledge_k6_fact'),
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
    { id: 'q1', q: $r('app.string.quiz_q1'), options: [ { label: $r('app.string.quiz_o_walk_bike'), score: 3 }, { label: $r('app.string.quiz_o_public'), score: 2 }, { label: $r('app.string.quiz_o_car'), score: 0 } ] },
    { id: 'q2', q: $r('app.string.quiz_q2'), options: [ { label: $r('app.string.quiz_o_ac_high'), score: 3 }, { label: $r('app.string.quiz_o_ac_mid'), score: 2 }, { label: $r('app.string.quiz_o_ac_low'), score: 0 } ] },
    { id: 'q3', q: $r('app.string.quiz_q3'), options: [ { label: $r('app.string.quiz_o_almost_every'), score: 3 }, { label: $r('app.string.quiz_o_often'), score: 2 }, { label: $r('app.string.quiz_o_occasionally'), score: 0 } ] },
    { id: 'q4', q: $r('app.string.quiz_q4'), options: [ { label: $r('app.string.quiz_o_sort_always'), score: 3 }, { label: $r('app.string.quiz_o_sort_sometimes'), score: 1 }, { label: $r('app.string.quiz_o_sort_rarely'), score: 0 } ] },
    { id: 'q5', q: $r('app.string.quiz_q5'), options: [ { label: $r('app.string.quiz_o_own_tableware'), score: 3 }, { label: $r('app.string.quiz_o_disp_occasionally'), score: 1 }, { label: $r('app.string.quiz_o_disp_often'), score: 0 } ] }
  ];

  static level(score: number): ResourceStr {
    if (score >= 12) {
      return $r('app.string.quiz_level_master');
    }
    if (score >= 8) {
      return $r('app.string.quiz_level_practitioner');
    }
    if (score >= 4) {
      return $r('app.string.quiz_level_novice');
    }
    return $r('app.string.quiz_level_need_work');
  }

  static tip(score: number): ResourceStr {
    if (score >= 12) {
      return $r('app.string.quiz_tip_master');
    }
    if (score >= 8) {
      return $r('app.string.quiz_tip_practitioner');
    }
    if (score >= 4) {
      return $r('app.string.quiz_tip_novice');
    }
    return $r('app.string.quiz_tip_need_work');
  }
}
