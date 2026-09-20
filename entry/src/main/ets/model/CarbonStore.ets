import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { CarbonRecord, BehaviorDef, CategoryStat, TrendPoint, RedemptionRecord } from './CarbonTypes';
import { CarbonFactors } from './CarbonFactors';
import { AppConst, AppColor } from '../common/Constants';
import { DateUtil } from '../common/DateUtil';

export class CarbonStore {
  private static instance: CarbonStore | null = null;
  private prefs: preferences.Preferences | null = null;
  private records: CarbonRecord[] = [];
  private redemptions: RedemptionRecord[] = [];
  private loaded: boolean = false;

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
    this.prefs = await preferences.getPreferences(context, AppConst.STORE_NAME);
    const raw = await this.prefs.get(AppConst.KEY_RECORDS, '[]') as string;
    this.records = this.parse(raw);
    const rawRedeem = await this.prefs.get(AppConst.KEY_REDEMPTIONS, '[]') as string;
    this.redemptions = this.parseRedemptions(rawRedeem);
    this.loaded = true;
    AppStorage.setOrCreate('recordsVersion', 1);
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

  async getSetting(key: string, def: string): Promise<string> {
    if (this.prefs === null) {
      return def;
    }
    return await this.prefs.get(key, def) as string;
  }

  async setSetting(key: string, value: string): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    await this.prefs.put(key, value);
    await this.prefs.flush();
  }

  private async persist(): Promise<void> {
    if (this.prefs === null) {
      return;
    }
    await this.prefs.put(AppConst.KEY_RECORDS, JSON.stringify(this.records));
    await this.prefs.put(AppConst.KEY_REDEMPTIONS, JSON.stringify(this.redemptions));
    await this.prefs.flush();
  }

  private notify(): void {
    const v = AppStorage.get<number>('recordsVersion') ?? 0;
    AppStorage.setOrCreate('recordsVersion', v + 1);
  }

  getRecords(): CarbonRecord[] {
    const copy: CarbonRecord[] = this.records.slice();
    copy.sort((a: CarbonRecord, b: CarbonRecord) => b.timestamp - a.timestamp);
    return copy;
  }

  addRecord(behavior: BehaviorDef, amount: number, note: string): CarbonRecord {
    const saved = behavior.factor * amount;
    const points = Math.max(1, Math.round(saved * AppConst.POINTS_PER_KG));
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
    return this.totalPoints() - this.spentPoints();
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
    for (let i = 2; i >= 0; i--) {
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

  exportCsv(): string {
    let csv = 'id,日期,类别,行为,数量,单位,减排量kgCO2e,积分,备注\n';
    this.getRecords().forEach((r: CarbonRecord) => {
      csv += r.id + ',' + r.dateKey + ',' + r.category + ',' + r.name + ',' +
        r.amount.toString() + ',' + r.unit + ',' + r.saved.toFixed(4) + ',' +
        r.points.toString() + ',' + (r.note === '' ? '-' : r.note) + '\n';
    });
    return csv;
  }

  exportJson(): string {
    return JSON.stringify(this.records, null, 2);
  }
}
