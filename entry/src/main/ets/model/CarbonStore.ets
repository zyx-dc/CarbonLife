import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { CarbonRecord, BehaviorDef, CategoryStat, TrendPoint, RedemptionRecord, TaskRewardRecord, BackupSnapshot } from './CarbonTypes';
import { CarbonFactors } from './CarbonFactors';
import { AppConst, AppColor } from '../common/Constants';
import { DateUtil } from '../common/DateUtil';
import { resolveStr } from '../common/Localize';

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
    let points = saved > 0 ? Math.max(AppConst.MIN_RECORD_POINTS, Math.round(saved * AppConst.POINTS_PER_KG)) : 0;
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

  findRecord(id: string): CarbonRecord | null {
    const hit = this.records.filter((r: CarbonRecord) => r.id === id);
    return hit.length > 0 ? hit[0] : null;
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
      points.push({ label: resolveStr($r('app.string.chart_axis_week', (6 - i).toString())), value: sum });
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
      points.push({ label: resolveStr($r('app.string.chart_axis_month', (d.getMonth() + 1).toString())), value: sum });
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

  // ---- 数据导入 ----

  private static parseCsvLine(line: string): string[] {
    const out: string[] = [];
    let cur = '';
    let inQuotes = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line.charAt(i);
      if (inQuotes) {
        if (ch === '"') {
          if (i + 1 < line.length && line.charAt(i + 1) === '"') {
            cur += '"';
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cur += ch;
        }
      } else if (ch === '"') {
        inQuotes = true;
      } else if (ch === ',') {
        out.push(cur);
        cur = '';
      } else {
        cur += ch;
      }
    }
    out.push(cur);
    return out;
  }

  // ---- 字段校验 / 归一化：导入的文件可能被手改或来自旧版本，必须逐字段校验 ----

  private static isFiniteNum(n: number): boolean {
    return n === n && n !== Infinity && n !== -Infinity;
  }

  private static strField(o: Record<string, Object>, key: string, def: string): string {
    const v = o[key];
    return typeof v === 'string' ? v as string : def;
  }

  private static numField(o: Record<string, Object>, key: string, def: number): number {
    const v = o[key];
    if (typeof v === 'number') {
      const n = v as number;
      return CarbonStore.isFiniteNum(n) ? n : def;
    }
    return def;
  }

  // 把任意 JSON 对象归一化为合法 CarbonRecord；不可用返回 null（丢弃该条）
  private static coerceRecord(item: Object): CarbonRecord | null {
    const o = item as Record<string, Object>;
    const id = o['id'];
    if (typeof id !== 'string' || (id as string) === '') {
      return null;
    }
    const def = CarbonFactors.find(CarbonStore.strField(o, 'behaviorKey', ''));
    const now = Date.now();
    let amount = CarbonStore.numField(o, 'amount', 0);
    if (amount < 0) {
      amount = 0;
    }
    let saved = CarbonStore.numField(o, 'saved', def.factor * amount);
    if (saved < 0) {
      saved = 0;
    }
    // 单条记录积分封顶：防止手工构造的大数积分被兑换
    let points = Math.floor(CarbonStore.numField(o, 'points', 0));
    if (points < 0) {
      points = 0;
    }
    if (points > AppConst.DAILY_RECORD_POINTS_CAP) {
      points = AppConst.DAILY_RECORD_POINTS_CAP;
    }
    let timestamp = CarbonStore.numField(o, 'timestamp', now);
    // 拒绝 > 1 天的未来时间戳，避免污染「今日 / 本周」统计
    if (timestamp <= 0 || timestamp > now + 86400000) {
      timestamp = now;
    }
    return {
      id: id as string,
      behaviorKey: def.key,
      category: CarbonStore.strField(o, 'category', def.category),
      name: CarbonStore.strField(o, 'name', def.name),
      amount: amount,
      unit: CarbonStore.strField(o, 'unit', def.unit),
      factor: def.factor,
      saved: saved,
      points: points,
      timestamp: timestamp,
      dateKey: DateUtil.dayKey(timestamp),
      note: CarbonStore.strField(o, 'note', '')
    };
  }

  private static coerceRedemption(item: Object): RedemptionRecord | null {
    const o = item as Record<string, Object>;
    const id = o['id'];
    if (typeof id !== 'string' || (id as string) === '') {
      return null;
    }
    const now = Date.now();
    let cost = CarbonStore.numField(o, 'cost', 0);
    if (cost < 0) {
      cost = 0;
    }
    let timestamp = CarbonStore.numField(o, 'timestamp', now);
    if (timestamp <= 0) {
      timestamp = now;
    }
    return {
      id: id as string,
      itemId: CarbonStore.strField(o, 'itemId', ''),
      itemName: CarbonStore.strField(o, 'itemName', ''),
      cost: cost,
      timestamp: timestamp
    };
  }

  private static coerceTaskReward(item: Object): TaskRewardRecord | null {
    const o = item as Record<string, Object>;
    const dateKey = o['dateKey'];
    const taskKey = o['taskKey'];
    if (typeof dateKey !== 'string' || (dateKey as string) === '' ||
      typeof taskKey !== 'string' || (taskKey as string) === '') {
      return null;
    }
    const now = Date.now();
    let timestamp = CarbonStore.numField(o, 'timestamp', now);
    if (timestamp <= 0) {
      timestamp = now;
    }
    let points = Math.floor(CarbonStore.numField(o, 'points', 0));
    if (points < 0) {
      points = 0;
    }
    return { dateKey: dateKey as string, taskKey: taskKey as string, points: points, timestamp: timestamp };
  }

  // 合并导入记录：按 id 去重，返回新增条数（入参须已通过 coerceRecord）
  importRecords(list: CarbonRecord[]): number {
    const ids: string[] = this.records.map((r: CarbonRecord) => r.id);
    let added = 0;
    list.forEach((r: CarbonRecord) => {
      if (r.id === '' || ids.indexOf(r.id) >= 0) {
        return;
      }
      ids.push(r.id);
      this.records.push(r);
      added += 1;
    });
    if (added > 0) {
      this.persist();
      this.notify();
    }
    return added;
  }

  // 导入导出的 JSON（CarbonRecord 数组）。返回新增条数，解析失败返回 -1
  importJson(text: string): number {
    try {
      const arr = JSON.parse(text) as Object[];
      if (!Array.isArray(arr)) {
        return -1;
      }
      const list: CarbonRecord[] = [];
      arr.forEach((item: Object) => {
        const rec = CarbonStore.coerceRecord(item);
        if (rec !== null) {
          list.push(rec);
        }
      });
      return this.importRecords(list);
    } catch (e) {
      return -1;
    }
  }

  // 导入导出的 CSV。返回新增条数，解析失败返回 -1
  importCsv(text: string): number {
    try {
      const lines = text.replace(/\r\n/g, '\n').split('\n').filter((l: string) => l.trim() !== '');
      if (lines.length <= 1) {
        return 0;
      }
      const list: CarbonRecord[] = [];
      for (let i = 1; i < lines.length; i++) {
        const cols = CarbonStore.parseCsvLine(lines[i]);
        if (cols.length < 9) {
          continue;
        }
        const name = cols[3];
        const matches = CarbonFactors.BEHAVIORS.filter((b: BehaviorDef) => b.name === name);
        const def = matches.length > 0 ? matches[0] : CarbonFactors.BEHAVIORS[0];
        const candidate: CarbonRecord = {
          id: cols[0],
          behaviorKey: def.key,
          category: cols[2] !== '' ? cols[2] : def.category,
          name: name !== '' ? name : def.name,
          amount: parseFloat(cols[4]) || 0,
          unit: cols[5] !== '' ? cols[5] : def.unit,
          factor: def.factor,
          saved: parseFloat(cols[6]) || 0,
          points: parseInt(cols[7]) || 0,
          timestamp: DateUtil.dayKeyToTimestamp(cols[1]),
          dateKey: cols[1],
          note: cols[8] === '-' ? '' : cols[8]
        };
        // 与 JSON/快照导入共用同一套校验（数值 clamp、日期归一、积分封顶）
        const rec = CarbonStore.coerceRecord(candidate);
        if (rec !== null) {
          list.push(rec);
        }
      }
      return this.importRecords(list);
    } catch (e) {
      return -1;
    }
  }

  // ---- 整包备份 / 恢复（记录 + 兑换 + 任务奖励；云备份的本地基础）----

  exportSnapshot(): string {
    const snap: BackupSnapshot = {
      app: 'CarbonLife',
      version: 1,
      updatedAt: Date.now(),
      records: this.records,
      redemptions: this.redemptions,
      taskRewards: this.taskRewards
    };
    return JSON.stringify(snap, null, 2);
  }

  // 合并恢复：按记录 id 与 (dateKey, taskKey) 去重。返回新增条数；解析失败返回 -1
  importSnapshot(text: string): number {
    try {
      const snap = JSON.parse(text) as BackupSnapshot;
      if (snap === null || snap === undefined || !Array.isArray(snap.records)) {
        return -1;
      }
      const recs: CarbonRecord[] = [];
      snap.records.forEach((item: CarbonRecord) => {
        const rec = CarbonStore.coerceRecord(item);
        if (rec !== null) {
          recs.push(rec);
        }
      });
      let added = this.importRecords(recs);
      const rIds: string[] = this.redemptions.map((r: RedemptionRecord) => r.id);
      if (Array.isArray(snap.redemptions)) {
        snap.redemptions.forEach((item: RedemptionRecord) => {
          const r = CarbonStore.coerceRedemption(item);
          if (r !== null && rIds.indexOf(r.id) < 0) {
            this.redemptions.push(r);
            rIds.push(r.id);
            added += 1;
          }
        });
      }
      const tKeys: string[] = this.taskRewards.map((t: TaskRewardRecord) => t.dateKey + '|' + t.taskKey);
      if (Array.isArray(snap.taskRewards)) {
        snap.taskRewards.forEach((item: TaskRewardRecord) => {
          const t = CarbonStore.coerceTaskReward(item);
          if (t === null) {
            return;
          }
          const k = t.dateKey + '|' + t.taskKey;
          if (tKeys.indexOf(k) < 0) {
            this.taskRewards.push(t);
            tKeys.push(k);
            added += 1;
          }
        });
      }
      if (added > 0) {
        this.persist();
        this.notify();
      }
      return added;
    } catch (e) {
      return -1;
    }
  }
}
