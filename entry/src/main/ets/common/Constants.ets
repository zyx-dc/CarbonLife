import { Theme, ThemeTokens } from './Theme';

/**
 * AppColor 已重构为动态主题 getter。
 * - 浅色/深色模式通过 AppStorage 'colorMode' 切换
 * - 所有旧代码中的 AppColor.PRIMARY 等静态调用会自动取当前主题色
 */
export class AppColor {
  static get PRIMARY(): string { return Theme.current().primary; }
  static get PRIMARY_LIGHT(): string { return Theme.current().primaryLight; }
  static get PRIMARY_SOFT(): string { return Theme.current().primarySoft; }
  static get ACCENT(): string { return Theme.current().accent; }
  static get MAGENTA(): string { return Theme.current().magenta; }
  // 图片压暗层上的文字色：恒为浅色，保证任何主题下叠加在照片上都可读
  static get ON_OVERLAY(): string { return ThemeTokens.ON_DARK; }
  // 关键读数用色：深色走信号青柠，浅色走墨绿（青柠在白底不可读）
  static get READING(): string { return Theme.isDark() ? Theme.current().signal : Theme.current().primary; }
  static get SIGNAL(): string { return Theme.current().signal; }
  static get SIGNAL_DEEP(): string { return Theme.current().signalDeep; }
  static get ON_SIGNAL(): string { return Theme.current().onSignal; }
  static get DANGER(): string { return Theme.current().danger; }
  static get BG(): string { return Theme.current().bg; }
  static get CARD(): string { return Theme.current().card; }
  static get ELEVATED(): string { return Theme.current().elevated; }
  static get TEXT(): string { return Theme.current().text; }
  static get TEXT_SUB(): string { return Theme.current().textSub; }
  static get TEXT_INVERSE(): string { return Theme.current().textInverse; }
  static get TEXT_INVERSE_SUB(): string { return Theme.current().textInverseSub; }
  static get DIVIDER(): string { return Theme.current().divider; }
  static get BORDER(): string { return Theme.current().border; }
  static get SHADOW(): string { return Theme.current().shadow; }
  static get OVERLAY(): string { return Theme.current().overlay; }
  static get SCRIM(): string { return Theme.current().scrim; }
  static get SCRIM_FADE(): string { return Theme.current().scrimFade; }
  static get GLASS(): string { return Theme.current().glass; }
  static get GLASS_STRONG(): string { return Theme.current().glassStrong; }
  static get GLASS_BORDER(): string { return Theme.current().glassBorder; }
  static get BG_WASH_TOP(): string { return Theme.current().bgWashTop; }
  static get BG_WASH_BOTTOM(): string { return Theme.current().bgWashBottom; }
  static get BG_WASH_FADE(): string { return Theme.current().bgWashFade; }
  static get BLOB_A(): string { return Theme.current().blobA; }
  static get BLOB_A_FADE(): string { return Theme.current().blobAFade; }
  static get BLOB_B(): string { return Theme.current().blobB; }
  static get BLOB_B_FADE(): string { return Theme.current().blobBFade; }
  static get BLOB_C(): string { return Theme.current().blobC; }
  static get BLOB_C_FADE(): string { return Theme.current().blobCFade; }
  static get PRIMARY_GLOW(): string { return Theme.current().primaryGlow; }
  static get SUCCESS(): string { return Theme.current().success; }
  static get CHART_BLUE(): string { return Theme.current().chartBlue; }
  static get CHART_ORANGE(): string { return Theme.current().chartOrange; }
  static get CHART_PURPLE(): string { return Theme.current().chartPurple; }
  static get CHART_TEAL(): string { return Theme.current().chartTeal; }
  // 图表主线色：深色=信号青柠，浅色=可读的品牌绿
  static get CHART_LINE(): string { return Theme.current().chartLine; }
}

export class AppConst {
  static readonly STORE_NAME: string = 'carbon_life_store';
  static readonly KEY_RECORDS: string = 'records';
  static readonly KEY_REDEMPTIONS: string = 'redemptions';
  static readonly KEY_FAMILY_SESSION: string = 'family_session';
  static readonly KEY_FAMILY_NAME: string = 'family_name';
  static readonly KEY_FAMILY_DEVICE_ID: string = 'family_device_id';
  static readonly KEY_TASK_REWARDS: string = 'task_rewards';
  static readonly KEY_REMINDER_ID: string = 'reminder_id';
  static readonly POINTS_PER_KG: number = 100;
  static readonly TREE_PER_KG: number = 10;
  // 每日「记录积分」上限，抑制极小减排的重复刷分
  static readonly DAILY_RECORD_POINTS_CAP: number = 300;
}
