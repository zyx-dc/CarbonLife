export class DateUtil {
  static pad(n: number): string {
    return n < 10 ? '0' + n.toString() : n.toString();
  }

  static dayKey(ts: number): string {
    const d = new Date(ts);
    return d.getFullYear().toString() + '-' + DateUtil.pad(d.getMonth() + 1) + '-' + DateUtil.pad(d.getDate());
  }

  static monthKey(ts: number): string {
    const d = new Date(ts);
    return d.getFullYear().toString() + '-' + DateUtil.pad(d.getMonth() + 1);
  }

  static yearKey(ts: number): string {
    return new Date(ts).getFullYear().toString();
  }

  static startOfDay(ts: number): number {
    const d = new Date(ts);
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }

  static startOfWeek(ts: number): number {
    const d = new Date(DateUtil.startOfDay(ts));
    const day = d.getDay();
    const diff = day === 0 ? 6 : day - 1;
    d.setDate(d.getDate() - diff);
    return d.getTime();
  }

  static startOfMonth(ts: number): number {
    const d = new Date(ts);
    d.setDate(1);
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }

  static startOfYear(ts: number): number {
    const d = new Date(ts);
    d.setMonth(0, 1);
    d.setHours(0, 0, 0, 0);
    return d.getTime();
  }

  static formatTime(ts: number): string {
    const d = new Date(ts);
    return DateUtil.pad(d.getMonth() + 1) + '-' + DateUtil.pad(d.getDate()) + ' ' +
      DateUtil.pad(d.getHours()) + ':' + DateUtil.pad(d.getMinutes());
  }

  static formatDay(ts: number): string {
    const d = new Date(ts);
    return DateUtil.pad(d.getMonth() + 1) + '-' + DateUtil.pad(d.getDate());
  }
}
