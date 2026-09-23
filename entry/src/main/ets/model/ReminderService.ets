import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { CarbonStore } from './CarbonStore';
import { AppConst } from '../common/Constants';

export class ReminderService {
  static readonly HOUR: number = 20;
  static readonly MINUTE: number = 0;

  static async enable(): Promise<number> {
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
      hour: ReminderService.HOUR,
      minute: ReminderService.MINUTE,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: '低碳生活提醒',
      content: '记录今天的低碳行为，坚持减排赢积分！',
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
