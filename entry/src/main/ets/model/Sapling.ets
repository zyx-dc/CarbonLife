import { CarbonStore } from './CarbonStore';
import { CarbonRecord, TaskRewardRecord } from './CarbonTypes';
import { DateUtil } from '../common/DateUtil';

/**
 * 碳小树：把真实低碳行为沉淀成"一棵会长大的树"。
 *
 * 设计约束（防刷 / 不制造焦虑）：
 * - 成长值**完全由记录与任务奖励派生**，没有独立的可写状态 → 无法靠点按钮刷；
 * - 每日成长上限 80，约 6~8 条有效记录封顶，避免极小事重复刷；
 * - 连续记录有加成（每天 +5%，封顶 +50%），但**断签不掉级**，只影响当天加成；
 * - 连续天数只在"相邻自然日"累加，中间断档从 1 重新开始。
 *
 * 阶段（阈值 = 累计成长值）：
 *   0 种子 0 / 1 幼苗 60 / 2 小树 180 / 3 开花 420 / 4 结果 900 / 5 常青 2400
 */
export interface SaplingState {
  growth: number;
  stage: number;
  stageStart: number;
  /** 下一阶段阈值；已满级为 0 */
  stageEnd: number;
  /** 当前阶段内进度 0..1；已满级为 1 */
  progress: number;
  streak: number;
  bestStreak: number;
  activeDays: number;
  todayGrowth: number;
  capped: boolean;
  maxed: boolean;
  /** 行为结构：travel / energy / recycle / food / mixed，决定树冠装饰 */
  variant: string;
}

/** 单日原始行为数：增长算法的纯输入，便于单测。 */
export interface DayStat {
  dateKey: string;
  records: number;
  tasks: number;
}

export class Sapling {
  static readonly STAGE_GROWTH: number[] = [0, 60, 180, 420, 900, 2400];
  static readonly DAILY_CAP: number = 80;
  static readonly RECORD_GROWTH: number = 10;
  static readonly TASK_GROWTH: number = 15;
  static readonly STREAK_BONUS: number = 0.05;
  static readonly MAX_BONUS: number = 0.5;

  static of(store: CarbonStore): SaplingState {
    const recordCount: Map<string, number> = new Map<string, number>();
    const taskCount: Map<string, number> = new Map<string, number>();

    const records: CarbonRecord[] = store.getRecords();
    records.forEach((r: CarbonRecord) => {
      recordCount.set(r.dateKey, (recordCount.get(r.dateKey) ?? 0) + 1);
    });

    const tasks: TaskRewardRecord[] = store.getTaskRewards();
    tasks.forEach((t: TaskRewardRecord) => {
      taskCount.set(t.dateKey, (taskCount.get(t.dateKey) ?? 0) + 1);
    });

    const keys: string[] = [];
    recordCount.forEach((_v: number, k: string) => keys.push(k));
    taskCount.forEach((_v: number, k: string) => {
      if (!recordCount.has(k)) {
        keys.push(k);
      }
    });

    const stats: DayStat[] = keys.map((k: string) => {
      const s: DayStat = {
        dateKey: k,
        records: recordCount.get(k) ?? 0,
        tasks: taskCount.get(k) ?? 0
      };
      return s;
    });

    const state: SaplingState = Sapling.compute(stats, DateUtil.dayKey(Date.now()));
    state.variant = Sapling.variantOf(store);
    return state;
  }

  /**
   * 行为结构判定：主导类别占比 ≥ 40%（且至少有 5 条记录）才形成"偏向"，
   * 否则视为均衡。装饰层据此切换，让每棵树对自己的生活方式有辨识度。
   */
  static variantOf(store: CarbonStore): string {
    const records: CarbonRecord[] = store.getRecords();
    if (records.length < 5) {
      return 'mixed';
    }
    const counts: Map<string, number> = new Map<string, number>();
    records.forEach((r: CarbonRecord) => {
      counts.set(r.category, (counts.get(r.category) ?? 0) + 1);
    });
    let bestKey: string = '';
    let best: number = 0;
    counts.forEach((v: number, k: string) => {
      if (v > best) {
        best = v;
        bestKey = k;
      }
    });
    if (best / records.length < 0.4) {
      return 'mixed';
    }
    switch (bestKey) {
      case '出行': return 'travel';
      case '节能': return 'energy';
      case '回收': return 'recycle';
      case '餐饮': return 'food';
      default: return 'mixed';
    }
  }

  static variantNameRes(variant: string): ResourceStr {
    switch (variant) {
      case 'travel': return $r('app.string.home_sapling_variant_travel');
      case 'energy': return $r('app.string.home_sapling_variant_energy');
      case 'recycle': return $r('app.string.home_sapling_variant_recycle');
      case 'food': return $r('app.string.home_sapling_variant_food');
      default: return $r('app.string.home_sapling_variant_mixed');
    }
  }

  /** 纯函数：给定每天的原始行为数，算出小树状态。 */
  static compute(stats: DayStat[], todayKey: string): SaplingState {
    const sorted: DayStat[] = stats.slice();
    sorted.sort((a: DayStat, b: DayStat) => a.dateKey < b.dateKey ? -1 : (a.dateKey > b.dateKey ? 1 : 0));

    let growth: number = 0;
    let streak: number = 0;
    let bestStreak: number = 0;
    let activeDays: number = 0;
    let todayGrowth: number = 0;
    let todayRaw: number = 0;
    let prevTs: number = 0;

    sorted.forEach((d: DayStat) => {
      const ts: number = DateUtil.dayKeyToTimestamp(d.dateKey);
      const raw: number = Math.min(Sapling.DAILY_CAP,
        d.records * Sapling.RECORD_GROWTH + d.tasks * Sapling.TASK_GROWTH);
      if (raw <= 0) {
        streak = 0;
        prevTs = ts;
        return;
      }
      // 只有"相邻自然日"才续上连续；中间断档则从 1 重新开始
      if (prevTs > 0 && Math.round((ts - prevTs) / 86400000) > 1) {
        streak = 0;
      }
      streak = streak + 1;
      activeDays = activeDays + 1;
      bestStreak = Math.max(bestStreak, streak);
      const bonus: number = Math.min(Sapling.MAX_BONUS, (streak - 1) * Sapling.STREAK_BONUS);
      const gained: number = Math.round(raw * (1 + bonus));
      growth = growth + gained;
      if (d.dateKey === todayKey) {
        todayGrowth = gained;
        todayRaw = raw;
      }
      prevTs = ts;
    });

    const stage: number = Sapling.stageOf(growth);
    const stageStart: number = Sapling.STAGE_GROWTH[stage];
    const maxed: boolean = stage >= Sapling.STAGE_GROWTH.length - 1;
    const stageEnd: number = maxed ? 0 : Sapling.STAGE_GROWTH[stage + 1];
    const progress: number = maxed ? 1 : Math.max(0, Math.min(1, (growth - stageStart) / (stageEnd - stageStart)));

    return {
      growth: growth,
      stage: stage,
      stageStart: stageStart,
      stageEnd: stageEnd,
      progress: progress,
      streak: streak,
      bestStreak: bestStreak,
      activeDays: activeDays,
      todayGrowth: todayGrowth,
      capped: todayRaw >= Sapling.DAILY_CAP,
      maxed: maxed,
      variant: 'mixed'
    };
  }

  static stageOf(growth: number): number {
    let stage: number = 0;
    for (let i: number = 0; i < Sapling.STAGE_GROWTH.length; i++) {
      if (growth >= Sapling.STAGE_GROWTH[i]) {
        stage = i;
      }
    }
    return stage;
  }

  static stageNameRes(stage: number): ResourceStr {
    switch (stage) {
      case 1: return $r('app.string.home_sapling_stage_1');
      case 2: return $r('app.string.home_sapling_stage_2');
      case 3: return $r('app.string.home_sapling_stage_3');
      case 4: return $r('app.string.home_sapling_stage_4');
      case 5: return $r('app.string.home_sapling_stage_5');
      default: return $r('app.string.home_sapling_stage_0');
    }
  }
}
