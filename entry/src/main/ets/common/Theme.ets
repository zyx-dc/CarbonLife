import { PromptAction, UIContext } from '@kit.ArkUI';

/**
 * Theme 设计系统
 * - 支持浅色/深色模式切换，跟随系统 Configuration.colorMode
 * - 所有动画读取 AppStorage 'reduceMotion'，遵循无障碍减弱动效
 */

export interface ThemeColor {
  bg: string;
  surface: string;
  card: string;
  elevated: string;
  primary: string;
  primaryLight: string;
  primarySoft: string;
  accent: string;
  text: string;
  textSub: string;
  textInverse: string;
  divider: string;
  border: string;
  shadow: string;
  overlay: string;
  danger: string;
  success: string;
  chartBlue: string;
  chartOrange: string;
  chartPurple: string;
  chartTeal: string;
}

export class ThemeTokens {
  // 主色：深林绿系
  static readonly FOREST: string = '#0F3D2E';
  static readonly FOREST_LIGHT: string = '#1B5E20';
  static readonly MINT: string = '#34C759';
  static readonly MINT_SOFT: string = '#66BB6A';

  // 强调：琥珀金
  static readonly AMBER: string = '#FFB300';

  // 背景与表面
  static readonly BG_LIGHT: string = '#F5F7F5';
  static readonly BG_DARK: string = '#0A0A0A';
  static readonly CARD_LIGHT: string = '#FFFFFF';
  static readonly CARD_DARK: string = '#121212';
  static readonly SURFACE_DARK: string = '#1C1C1E';

  // 文字
  static readonly TEXT_PRIMARY_LIGHT: string = '#1C1C1E';
  static readonly TEXT_SECONDARY_LIGHT: string = '#6E6E73';
  static readonly TEXT_PRIMARY_DARK: string = '#F5F5F7';
  static readonly TEXT_SECONDARY_DARK: string = '#8E8E93';

  // 辅助
  static readonly DANGER: string = '#FF453A';
  static readonly SUCCESS: string = '#34C759';
}

export class Theme {
  static isDark(): boolean {
    return AppStorage.get<string>('colorMode') === 'dark';
  }

  static current(): ThemeColor {
    return Theme.isDark() ? Theme.dark() : Theme.light();
  }

  static light(): ThemeColor {
    return {
      bg: ThemeTokens.BG_LIGHT,
      surface: '#FFFFFF',
      card: ThemeTokens.CARD_LIGHT,
      elevated: '#FFFFFF',
      primary: ThemeTokens.FOREST,
      primaryLight: ThemeTokens.FOREST_LIGHT,
      primarySoft: 'rgba(15,61,46,0.08)',
      accent: ThemeTokens.AMBER,
      text: ThemeTokens.TEXT_PRIMARY_LIGHT,
      textSub: ThemeTokens.TEXT_SECONDARY_LIGHT,
      textInverse: '#FFFFFF',
      divider: 'rgba(28,28,30,0.08)',
      border: 'rgba(28,28,30,0.10)',
      shadow: '#E6ECE8',
      overlay: 'rgba(0,0,0,0.45)',
      danger: ThemeTokens.DANGER,
      success: ThemeTokens.SUCCESS,
      chartBlue: '#0A84FF',
      chartOrange: '#FF9F0A',
      chartPurple: '#BF5AF2',
      chartTeal: '#40C8E0'
    };
  }

  static dark(): ThemeColor {
    return {
      bg: ThemeTokens.BG_DARK,
      surface: ThemeTokens.SURFACE_DARK,
      card: ThemeTokens.CARD_DARK,
      elevated: '#2C2C2E',
      primary: ThemeTokens.MINT,
      primaryLight: ThemeTokens.MINT_SOFT,
      primarySoft: 'rgba(52,199,89,0.15)',
      accent: ThemeTokens.AMBER,
      text: ThemeTokens.TEXT_PRIMARY_DARK,
      textSub: ThemeTokens.TEXT_SECONDARY_DARK,
      textInverse: '#1C1C1E',
      divider: 'rgba(245,245,247,0.10)',
      border: 'rgba(245,245,247,0.15)',
      shadow: 'rgba(0,0,0,0.50)',
      overlay: 'rgba(0,0,0,0.60)',
      danger: '#FF6961',
      success: ThemeTokens.MINT,
      chartBlue: '#64D2FF',
      chartOrange: '#FFB340',
      chartPurple: '#DAA5FF',
      chartTeal: '#6EE1FF'
    };
  }
}

export interface TextStyle {
  size: number;
  weight: FontWeight;
  lineHeight: number;
}

export class AppTypography {
  static readonly H1: TextStyle = { size: 32, weight: FontWeight.Bold, lineHeight: 40 };
  static readonly H2: TextStyle = { size: 24, weight: FontWeight.Bold, lineHeight: 32 };
  static readonly H3: TextStyle = { size: 20, weight: FontWeight.Medium, lineHeight: 28 };
  static readonly H4: TextStyle = { size: 17, weight: FontWeight.Medium, lineHeight: 24 };
  static readonly BODY: TextStyle = { size: 15, weight: FontWeight.Regular, lineHeight: 22 };
  static readonly BODY_MEDIUM: TextStyle = { size: 15, weight: FontWeight.Medium, lineHeight: 22 };
  static readonly CAPTION: TextStyle = { size: 13, weight: FontWeight.Regular, lineHeight: 18 };
  static readonly CAPTION_MEDIUM: TextStyle = { size: 13, weight: FontWeight.Medium, lineHeight: 18 };
  static readonly SMALL: TextStyle = { size: 11, weight: FontWeight.Regular, lineHeight: 16 };
}

export class AppSpacing {
  static readonly XXS = 2;
  static readonly XS = 4;
  static readonly SM = 8;
  static readonly MD = 16;
  static readonly LG = 24;
  static readonly XL = 32;
  static readonly XXL = 48;
}

export class AppRadius {
  static readonly SM = 8;
  static readonly MD = 16;
  static readonly LG = 24;
  static readonly XL = 32;
  static readonly FULL = 9999;
}

export class AppShadow {
  static soft(): ShadowOptions {
    const c = Theme.current().shadow;
    return { radius: 12, color: c, offsetX: 0, offsetY: 12 };
  }

  static medium(): ShadowOptions {
    const c = Theme.current().shadow;
    return { radius: 20, color: c, offsetX: 0, offsetY: 20 };
  }
}

export class AppMotion {
  static readonly EASE: Curve = Curve.EaseOut;
  static readonly EASE_IN_OUT: Curve = Curve.EaseInOut;
  static readonly ENTER_DURATION = 500;
  static readonly STAGGER = 60;
  static readonly PRESS_DURATION = 120;

  static reduceMotion(): boolean {
    return AppStorage.get<boolean>('reduceMotion') ?? false;
  }

  static enterOptions(): AnimateParam {
    if (AppMotion.reduceMotion()) {
      return { duration: 0 };
    }
    return { duration: AppMotion.ENTER_DURATION, curve: AppMotion.EASE };
  }

  static pressOptions(): AnimateParam {
    if (AppMotion.reduceMotion()) {
      return { duration: 0 };
    }
    return { duration: AppMotion.PRESS_DURATION, curve: AppMotion.EASE };
  }

  static staggerDelay(index: number): number {
    if (AppMotion.reduceMotion()) {
      return 0;
    }
    return index * AppMotion.STAGGER;
  }
}

export class ToastHelper {
  static show(ctx: UIContext, message: string): void {
    try {
      ctx.getPromptAction().showToast({ message, duration: 2000 });
    } catch (e) {
      console.error('Toast failed: ' + JSON.stringify(e));
    }
  }
}
