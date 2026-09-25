import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { CarbonStore } from './CarbonStore';
import { AppConst } from '../common/Constants';
import { resolveStr } from '../common/Localize';

export class ReminderService {
  static readonly DEFAULT_HOUR: number = 20;
  static readonly DEFAULT_MINUTE: number = 0;

  static async getHour(): Promise<number> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_HOUR, ReminderService.DEFAULT_HOUR.toString());
    const n = parseInt(s);
    return isNaN(n) ? ReminderService.DEFAULT_HOUR : n;
  }

  static async getMinute(): Promise<number> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_MINUTE, ReminderService.DEFAULT_MINUTE.toString());
    const n = parseInt(s);
    return isNaN(n) ? ReminderService.DEFAULT_MINUTE : n;
  }

  static async setTime(hour: number, minute: number): Promise<void> {
    await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_HOUR, hour.toString());
    await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_MINUTE, minute.toString());
  }

  static async enable(): Promise<number> {
    const h = await ReminderService.getHour();
    const m = await ReminderService.getMinute();
    return ReminderService.enableAt(h, m);
  }

  static async enableAt(hour: number, minute: number): Promise<number> {
    // 先取消已存在的提醒，避免重复发布导致多条告警
    const prev = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_ID, '');
    if (prev !== '') {
      try {
        await reminderAgentManager.cancelReminder(parseInt(prev));
      } catch (e) {
      }
    }
    const req: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: resolveStr($r('app.string.reminder_notif_title')),
      content: resolveStr($r('app.string.reminder_notif_content')),
      notificationId: 1001,
      wantAgent: {
        pkgName: 'com.example.carbonlife',
        abilityName: 'EntryAbility'
      }
    };
    try {
      const id = await reminderAgentManager.publishReminder(req);
      await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_ID, id.toString());
      return id;
    } catch (e) {
      const err = e as Error;
      console.error('ReminderService enable failed: ' + err.message);
      throw new Error('开启提醒失败');
    }
  }

  static async disable(): Promise<void> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_ID, '');
    if (s === '') {
      return;
    }
    try {
      await reminderAgentManager.cancelReminder(parseInt(s));
      await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_ID, '');
    } catch (e) {
      // 取消失败则保留 id，便于下次重试，避免留下无法追踪的孤儿提醒
      console.error('ReminderService disable failed: ' + JSON.stringify(e));
    }
  }

  static async isEnabled(): Promise<boolean> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_ID, '');
    return s !== '';
  }
}
