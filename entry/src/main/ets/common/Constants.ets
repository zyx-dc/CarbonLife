import { Theme } from './Theme';

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
  static get DANGER(): string { return Theme.current().danger; }
  static get BG(): string { return Theme.current().bg; }
  static get CARD(): string { return Theme.current().card; }
  static get ELEVATED(): string { return Theme.current().elevated; }
  static get TEXT(): string { return Theme.current().text; }
  static get TEXT_SUB(): string { return Theme.current().textSub; }
  static get TEXT_INVERSE(): string { return Theme.current().textInverse; }
  static get DIVIDER(): string { return Theme.current().divider; }
  static get BORDER(): string { return Theme.current().border; }
  static get SHADOW(): string { return Theme.current().shadow; }
  static get OVERLAY(): string { return Theme.current().overlay; }
  static get SUCCESS(): string { return Theme.current().success; }
  static get CHART_BLUE(): string { return Theme.current().chartBlue; }
  static get CHART_ORANGE(): string { return Theme.current().chartOrange; }
  static get CHART_PURPLE(): string { return Theme.current().chartPurple; }
  static get CHART_TEAL(): string { return Theme.current().chartTeal; }
}

export class AppConst {
  static readonly STORE_NAME: string = 'carbon_life_store';
  static readonly KEY_RECORDS: string = 'records';
  static readonly KEY_REDEMPTIONS: string = 'redemptions';
  static readonly KEY_FAMILY_SESSION: string = 'family_session';
  static readonly KEY_FAMILY_NAME: string = 'family_name';
  static readonly KEY_FAMILY_DEVICE_ID: string = 'family_device_id';
  static readonly KEY_REMINDER_ID: string = 'reminder_id';
  static readonly POINTS_PER_KG: number = 100;
  static readonly TREE_PER_KG: number = 10;
}
