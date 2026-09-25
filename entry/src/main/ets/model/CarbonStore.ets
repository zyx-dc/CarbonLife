import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { CarbonRecord, BehaviorDef, CategoryStat, TrendPoint, RedemptionRecord, TaskRewardRecord } from './CarbonTypes';
import { CarbonFactors } from './CarbonFactors';
import { AppConst, AppColor } from '../common/Constants';
import { DateUtil } from '../common/DateUtil';

export class CarbonStore {
  private static instance: CarbonStore | null = null;
  private prefs: preferences.Preferences | null = null;
  private records: CarbonRecord[] = [];
  private redemptions: RedemptionRecord[] = [];
  private taskRewards: TaskRewardRecord[] = [];
  private loaded: boolean = false;
  private versionCounter: number = 1;
  private changeListeners: Array<() => void> = [];
  private writeQueue: Promise<void> = Promise.resolve();

  static get(): CarbonStore {
    if (CarbonStore.instance === null) {
      CarbonStore.instance = new CarbonStore();
    }
    return CarbonStore.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.loaded) {
      return;
    }
    try {
      this.prefs = await preferences.getPreferences(context, AppConst.STORE_NAME);
      const raw = await this.prefs.get(AppConst.KEY_RECORDS, '[]') as string;
      this.records = this.parse(raw);
      const rawRedeem = await this.prefs.get(AppConst.KEY_REDEMPTIONS, '[]') as string;
      this.redemptions = this.parseRedemptions(rawRedeem);
      const rawTasks = await this.prefs.get(AppConst.KEY_TASK_REWARDS, '[]') as string;
      this.taskRewards = this.parseTaskRewards(rawTasks);
      this.loaded = true;
      this.notify();
    } catch (e) {
      console.error('CarbonStore init failed: ' + JSON.stringify(e));
    }
  }

  private parse(raw: string): CarbonRecord[] {
    try {
      const arr: CarbonRecord[] = JSON.parse(raw) as CarbonRecord[];
      return arr;
    } catch (e) {
      return [];
    }
  }

  private parseRedemptions(raw: string): RedemptionRecord[] {
    try {
      const arr: RedemptionRecord[] = JSON.parse(raw) as RedemptionRecord[];
      return arr;
    } catch (e) {
      return [];
    }
  }

  private parseTaskRewards(raw: string): TaskRewardRecord[] {
    try {
      const arr: TaskRewardRecord[] = JSON.parse(raw) as TaskRewardRecord[];
      return arr;
    } catch (e) {
      return [];
    }
  }

  async getSetting(key: string, def: string): Promise<string> {
    if (this.prefs === null) {
      return def;
    }
    try {
      return await this.prefs.get(key, def) as string;
    } catch (e) {
      return def;
    }
  }

  async setSetting(key: string, value: string): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      await this.prefs.put(key, value);
      await this.prefs.flush();
    } catch (e) {
      console.error('CarbonStore setSetting failed: ' + JSON.stringify(e));
    }
  }

  private persist(): void {
    const recordsJson = JSON.stringify(this.records);
    const redeemJson = JSON.stringify(this.redemptions);
    const taskJson = JSON.stringify(this.taskRewards);
    // 串行化写入，避免并发 put/flush 交错导致旧快照覆盖新状态
    this.writeQueue = this.writeQueue.then(() => this.writeSnapshot(recordsJson, redeemJson, taskJson));
  }

  private async writeSnapshot(recordsJson: string, redeemJson: string, taskJson: string): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    try {
      await this.prefs.put(AppConst.KEY_RECORDS, recordsJson);
      await this.prefs.put(AppConst.KEY_REDEMPTIONS, redeemJson);
      await this.prefs.put(AppConst.KEY_TASK_REWARDS, taskJson);
      await this.prefs.flush();
    } catch (e) {
      console.error('CarbonStore persist failed: ' + JSON.stringify(e));
    }
  }

  addChangeListener(cb: () => void): void {
    this.changeListeners.push(cb);
  }

  removeChangeListener(cb: () => void): void {
    this.changeListeners = this.changeListeners.filter((l: () => void) => l !== cb);
  }

  private notify(): void {
    this.versionCounter = this.versionCounter + 1;
    AppStorage.setOrCreate('recordsVersion', this.versionCounter);
    this.changeListeners.forEach((l: () => void) => l());
  }

  getRecords(): CarbonRecord[] {
    const copy: CarbonRecord[] = this.records.slice();
    copy.sort((a: CarbonRecord, b: CarbonRecord) => b.timestamp - a.timestamp);
    return copy;
  }

  addRecord(behavior: BehaviorDef, amount: number, note: string): CarbonRecord {
    const saved = behavior.factor * amount;
    let points = saved > 0 ? Math.max(1, Math.round(saved * AppConst.POINTS_PER_KG)) : 0;
    // 每日「记录积分」封顶，抑制极小减排的重复刷分
    const remaining = AppConst.DAILY_RECORD_POINTS_CAP - this.recordPointsToday();
    points = remaining <= 0 ? 0 : Math.min(points, remaining);
    const now = Date.now();
    const rec: CarbonRecord = {
      id: util.generateRandomUUID(true),
      behaviorKey: behavior.key,
      category: behavior.category,
      name: behavior.name,
      amount: amount,
      unit: behavior.unit,
      factor: behavior.factor,
      saved: saved,
      points: points,
      timestamp: now,
      dateKey: DateUtil.dayKey(now),
      note: note
    };
    this.records.push(rec);
    this.persist();
    this.notify();
    return rec;
  }

  deleteRecord(id: string): void {
    this.records = this.records.filter((r: CarbonRecord) => r.id !== id);
    this.persist();
    this.notify();
  }

  clearAll(): void {
    this.records = [];
    this.redemptions = [];
    this.taskRewards = [];
    this.persist();
    this.notify();
  }

  totalSaved(): number {
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      sum += r.saved;
    });
    return sum;
  }

  totalPoints(): number {
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      sum += r.points;
    });
    this.taskRewards.forEach((t: TaskRewardRecord) => {
      sum += t.points;
    });
    return sum;
  }

  spentPoints(): number {
    let sum = 0;
    this.redemptions.forEach((r: RedemptionRecord) => {
      sum += r.cost;
    });
    return sum;
  }

  pointsBalance(): number {
    // 删除记录可能使已兑换的积分无法覆盖，兜底不低于 0
    return Math.max(0, this.totalPoints() - this.spentPoints());
  }

  getRedemptions(): RedemptionRecord[] {
    const copy: RedemptionRecord[] = this.redemptions.slice();
    copy.sort((a: RedemptionRecord, b: RedemptionRecord) => b.timestamp - a.timestamp);
    return copy;
  }

  addRedemption(rec: RedemptionRecord): void {
    this.redemptions.push(rec);
    this.persist();
    this.notify();
  }

  totalCount(): number {
    return this.records.length;
  }

  todaySaved(): number {
    const start = DateUtil.startOfDay(Date.now());
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.timestamp >= start) {
        sum += r.saved;
      }
    });
    return sum;
  }

  todayPoints(): number {
    const start = DateUtil.startOfDay(Date.now());
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.timestamp >= start) {
        sum += r.points;
      }
    });
    this.taskRewards.forEach((t: TaskRewardRecord) => {
      if (t.timestamp >= start) {
        sum += t.points;
      }
    });
    return sum;
  }

  todayCount(): number {
    const start = DateUtil.startOfDay(Date.now());
    let n = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.timestamp >= start) {
        n += 1;
      }
    });
    return n;
  }

  // 今日「记录」产生的积分（不含任务奖励），用于每日上限判断
  recordPointsToday(): number {
    const start = DateUtil.startOfDay(Date.now());
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.timestamp >= start) {
        sum += r.points;
      }
    });
    return sum;
  }

  hasTaskReward(dateKey: string, taskKey: string): boolean {
    return this.taskRewards.some((t: TaskRewardRecord) => t.dateKey === dateKey && t.taskKey === taskKey);
  }

  addTaskRewards(list: TaskRewardRecord[]): void {
    if (list.length === 0) {
      return;
    }
    list.forEach((t: TaskRewardRecord) => this.taskRewards.push(t));
    this.persist();
    this.notify();
  }

  getTaskRewards(): TaskRewardRecord[] {
    return this.taskRewards.slice();
  }

  countByBehavior(key: string): number {
    let n = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.behaviorKey === key) {
        n += 1;
      }
    });
    return n;
  }

  savedByCategory(): CategoryStat[] {
    const stats: CategoryStat[] = [];
    CarbonFactors.CATEGORIES.forEach((cat: string) => {
      let sum = 0;
      this.records.forEach((r: CarbonRecord) => {
        if (r.category === cat) {
          sum += r.saved;
        }
      });
      stats.push({ category: cat, saved: sum, color: CarbonFactors.categoryColor(cat) });
    });
    return stats;
  }

  savedByCategoryOf(cat: string): number {
    let sum = 0;
    this.records.forEach((r: CarbonRecord) => {
      if (r.category === cat) {
        sum += r.saved;
      }
    });
    return sum;
  }

  recordsInRange(start: number, end: number): CarbonRecord[] {
    return this.records.filter((r: CarbonRecord) => r.timestamp >= start && r.timestamp < end);
  }

  recentRecords(limit: number): CarbonRecord[] {
    const list = this.getRecords();
    return list.slice(0, limit);
  }

  trendDay(): TrendPoint[] {
    const points: TrendPoint[] = [];
    const base = DateUtil.startOfDay(Date.now());
    for (let i = 6; i >= 0; i--) {
      const dayStart = base - i * 86400000;
      const dayEnd = dayStart + 86400000;
      let sum = 0;
      this.records.forEach((r: CarbonRecord) => {
        if (r.timestamp >= dayStart && r.timestamp < dayEnd) {
          sum += r.saved;
        }
      });
      points.push({ label: DateUtil.formatDay(dayStart), value: sum });
    }
    return points;
  }

  trendWeek(): TrendPoint[] {
    const points: TrendPoint[] = [];
    const base = DateUtil.startOfWeek(Date.now());
    for (let i = 5; i >= 0; i--) {
      const ws = base - i * 7 * 86400000;
      const we = ws + 7 * 86400000;
      let sum = 0;
      this.records.forEach((r: CarbonRecord) => {
        if (r.timestamp >= ws && r.timestamp < we) {
          sum += r.saved;
        }
      });
      points.push({ label: '第' + (6 - i).toString() + '周', value: sum });
    }
    return points;
  }

  trendMonth(): TrendPoint[] {
    const points: TrendPoint[] = [];
    const now = new Date();
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const start = d.getTime();
      const end = new Date(d.getFullYear(), d.getMonth() + 1, 1).getTime();
      let sum = 0;
      this.records.forEach((r: CarbonRecord) => {
        if (r.timestamp >= start && r.timestamp < end) {
          sum += r.saved;
        }
      });
      points.push({ label: (d.getMonth() + 1).toString() + '月', value: sum });
    }
    return points;
  }

  trendYear(): TrendPoint[] {
    const points: TrendPoint[] = [];
    const year = new Date().getFullYear();
    for (let i = 4; i >= 0; i--) {
      const start = new Date(year - i, 0, 1).getTime();
      const end = new Date(year - i + 1, 0, 1).getTime();
      let sum = 0;
      this.records.forEach((r: CarbonRecord) => {
        if (r.timestamp >= start && r.timestamp < end) {
          sum += r.saved;
        }
      });
      points.push({ label: (year - i).toString(), value: sum });
    }
    return points;
  }

  trend(period: string): TrendPoint[] {
    if (period === 'week') {
      return this.trendWeek();
    } else if (period === 'month') {
      return this.trendMonth();
    } else if (period === 'year') {
      return this.trendYear();
    }
    return this.trendDay();
  }

  private csvField(value: string): string {
    let v = value;
    const first = v.length > 0 ? v.charAt(0) : '';
    // 防 CSV 公式注入：以 = + - @ 或制表/回车开头时前置单引号
    if (first === '=' || first === '+' || first === '-' || first === '@' ||
      first === '\t' || first === '\r') {
      v = "'" + v;
    }
    if (v.indexOf(',') >= 0 || v.indexOf('"') >= 0 ||
      v.indexOf('\n') >= 0 || v.indexOf('\r') >= 0) {
      return '"' + v.split('"').join('""') + '"';
    }
    return v;
  }

  exportCsv(): string {
    let csv = 'id,日期,类别,行为,数量,单位,减排量kgCO2e,积分,备注\n';
    this.getRecords().forEach((r: CarbonRecord) => {
      csv += this.csvField(r.id) + ',' + this.csvField(r.dateKey) + ',' + this.csvField(r.category) + ',' +
        this.csvField(r.name) + ',' + r.amount.toString() + ',' + this.csvField(r.unit) + ',' +
        r.saved.toFixed(4) + ',' + r.points.toString() + ',' +
        this.csvField(r.note === '' ? '-' : r.note) + '\n';
    });
    return '\uFEFF' + csv;
  }

  exportJson(): string {
    return JSON.stringify(this.records, null, 2);
  }
}
