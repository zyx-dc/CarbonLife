import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { CarbonStore } from './CarbonStore';
import { AppConst } from '../common/Constants';

export class ReminderService {
  static readonly HOUR: number = 20;
  static readonly MINUTE: number = 0;

  static async enable(): Promise<number> {
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
    const id = await reminderAgentManager.publishReminder(req);
    await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_ID, id.toString());
    return id;
  }

  static async disable(): Promise<void> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_ID, '');
    if (s !== '') {
      try {
        await reminderAgentManager.cancelReminder(parseInt(s));
      } catch (e) {
      }
    }
    await CarbonStore.get().setSetting(AppConst.KEY_REMINDER_ID, '');
  }

  static async isEnabled(): Promise<boolean> {
    const s = await CarbonStore.get().getSetting(AppConst.KEY_REMINDER_ID, '');
    return s !== '';
  }
}
