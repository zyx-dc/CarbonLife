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
  magenta: string;
  signal: string;
  signalDeep: string;
  onSignal: string;
  text: string;
  textSub: string;
  textInverse: string;
  textInverseSub: string;
  divider: string;
  border: string;
  shadow: string;
  primaryGlow: string;
  overlay: string;
  scrim: string;
  scrimFade: string;
  glass: string;
  glassStrong: string;
  glassBorder: string;
  bgWashTop: string;
  bgWashBottom: string;
  bgWashFade: string;
  blobA: string;
  blobAFade: string;
  blobB: string;
  blobBFade: string;
  blobC: string;
  blobCFade: string;
  danger: string;
  success: string;
  chartBlue: string;
  chartOrange: string;
  chartPurple: string;
  chartTeal: string;
  chartLine: string;
}

export class ThemeTokens {
  // 夜行荧光：主色为「电光青柠」——低照度下的高能见信号
  static readonly LIME: string = '#B6FF2E';
  static readonly LIME_DEEP: string = '#7FCB00';

  // 强调：电青，只属于积分与成就（浅色用加深版，保证正文 ≥4.5:1）
  static readonly CYAN: string = '#3DE0C8';
  static readonly CYAN_DEEP: string = '#0B7261';

  // 稀有高光：品红。仅作极少量点缀，制造「不和谐的秩序」
  static readonly MAGENTA: string = '#FF3D9A';

  // 数据可视化补充色：苔绿。与青柠/电青同属绿系，但足够区分
  static readonly SEA: string = '#2E8B57';

  // 图片压暗层上的文字：恒为浅色（图片底始终是暗 scrim，不随主题翻转）
  static readonly ON_DARK: string = '#F2FBE8';

  // 日光主题的墨绿（浅底上青柠不可读，改用墨作主色）
  static readonly INK: string = '#16210F';
  static readonly INK_DEEP: string = '#2F4A1D';

  static readonly DANGER_DARK: string = '#FF5C5C';
  static readonly DANGER_LIGHT: string = '#E5484D';
  static readonly SUCCESS_LIGHT: string = '#2E7D14';

  // 启动页专用（保持原样，不参与夜行荧光升级）
  static readonly FOREST: string = '#0F3D2E';
  static readonly FOREST_LIGHT: string = '#1B5E20';
  static readonly BG_LIGHT: string = '#F5F7F5';
}

export class Theme {
  static isDark(): boolean {
    return AppStorage.get<string>('colorMode') === 'dark';
  }

  static current(): ThemeColor {
    return Theme.isDark() ? Theme.dark() : Theme.light();
  }

  // 日光纸感：同源 DNA 的白天版——墨绿主色 + 青柠轨迹
  static light(): ThemeColor {
    return {
      bg: '#F5F7F5',
      surface: '#FFFFFF',
      card: '#FFFFFF',
      elevated: '#FFFFFF',
      primary: ThemeTokens.INK,
      primaryLight: ThemeTokens.INK_DEEP,
      primarySoft: 'rgba(22,33,15,0.10)',
      accent: ThemeTokens.CYAN_DEEP,
      magenta: '#D6006E',
      signal: ThemeTokens.LIME,
      signalDeep: ThemeTokens.LIME_DEEP,
      onSignal: '#0A0F07',
      text: '#12180D',
      textSub: '#5C6754',
      textInverse: '#F4FFE4',
      textInverseSub: 'rgba(244,255,228,0.72)',
      divider: 'rgba(18,24,13,0.10)',
      border: 'rgba(18,24,13,0.16)',
      shadow: 'rgba(20,30,16,0.14)',
      primaryGlow: 'rgba(22,33,15,0.22)',
      overlay: 'rgba(0,0,0,0.45)',
      scrim: 'rgba(10,15,7,0.45)',
      scrimFade: 'rgba(10,15,7,0.00)',
      glass: 'rgba(255,255,255,0.62)',
      glassStrong: 'rgba(255,255,255,0.85)',
      glassBorder: 'rgba(22,33,15,0.12)',
      bgWashTop: '#E4F2E7',
      bgWashBottom: '#ECF1E6',
      bgWashFade: '#00ECF1E6',
      blobA: '#8C5ED6A8',
      blobAFade: '#005ED6A8',
      blobB: '#4A14532D',
      blobBFade: '#0014532D',
      blobC: '#52F5BA60',
      blobCFade: '#00F5BA60',
      danger: ThemeTokens.DANGER_LIGHT,
      success: ThemeTokens.SUCCESS_LIGHT,
      chartBlue: '#0A84FF',
      chartOrange: '#E08600',
      chartPurple: '#9B4DFF',
      chartTeal: '#0FB5A0',
      chartLine: ThemeTokens.SUCCESS_LIGHT
    };
  }

  // 夜行荧光（默认气质）：OLED 近黑底 + 电光青柠读数 + 极少量品红高光
  static dark(): ThemeColor {
    return {
      bg: '#0A0A0A',
      surface: '#121712',
      card: '#101510',
      elevated: '#1A211A',
      primary: ThemeTokens.LIME,
      primaryLight: ThemeTokens.LIME_DEEP,
      primarySoft: 'rgba(182,255,46,0.14)',
      accent: ThemeTokens.CYAN,
      magenta: ThemeTokens.MAGENTA,
      signal: ThemeTokens.LIME,
      signalDeep: ThemeTokens.LIME_DEEP,
      onSignal: '#0A0F07',
      text: '#E9F7E0',
      textSub: '#82917B',
      textInverse: '#0A0F07',
      textInverseSub: 'rgba(10,15,7,0.62)',
      divider: 'rgba(255,255,255,0.10)',
      border: 'rgba(255,255,255,0.16)',
      shadow: 'rgba(0,0,0,0.60)',
      primaryGlow: 'rgba(182,255,46,0.30)',
      overlay: 'rgba(0,0,0,0.72)',
      scrim: 'rgba(6,10,7,0.55)',
      scrimFade: 'rgba(6,10,7,0.00)',
      glass: 'rgba(18,24,18,0.55)',
      glassStrong: 'rgba(18,24,18,0.82)',
      glassBorder: 'rgba(255,255,255,0.14)',
      bgWashTop: '#0A1410',
      bgWashBottom: '#0B120E',
      bgWashFade: '#000B120E',
      blobA: '#6B34C759',
      blobAFade: '#0034C759',
      blobB: '#5C1F5C3A',
      blobBFade: '#001F5C3A',
      blobC: '#4AF2B24C',
      blobCFade: '#00F2B24C',
      danger: ThemeTokens.DANGER_DARK,
      success: ThemeTokens.LIME,
      chartBlue: '#4DD0FF',
      chartOrange: '#FFB020',
      chartPurple: '#C77DFF',
      chartTeal: '#3DE0C8',
      chartLine: ThemeTokens.LIME
    };
  }
}

export interface TextStyle {
  size: number;
  weight: FontWeight;
  lineHeight: number;
}

export class AppTypography {
  // 展示级大数（Hero 读数）
  static readonly DISPLAY_LG: TextStyle = { size: 56, weight: FontWeight.Bold, lineHeight: 64 };
  static readonly DISPLAY: TextStyle = { size: 46, weight: FontWeight.Bold, lineHeight: 52 };
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
  static readonly XXL = 28;
  static readonly XL = 32;
  static readonly FULL = 9999;
}

export class AppShadow {
  static soft(): ShadowOptions {
    const c = Theme.current().shadow;
    return { radius: 24, color: c, offsetX: 0, offsetY: 8 };
  }

  static medium(): ShadowOptions {
    const c = Theme.current().shadow;
    return { radius: 28, color: c, offsetX: 0, offsetY: 16 };
  }

  static glow(): ShadowOptions {
    return { radius: 14, color: Theme.current().primaryGlow, offsetX: 0, offsetY: 6 };
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

  // 无限循环动效（背景漂移/呼吸/环轨）统一入口：减弱动效时退化为静止
  static loopOptions(duration: number, alternate: boolean): AnimateParam {
    if (AppMotion.reduceMotion()) {
      return { duration: 0 };
    }
    if (alternate) {
      return { duration, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate };
    }
    return { duration, curve: Curve.Linear, iterations: -1 };
  }
}

export class ToastHelper {
  static show(ctx: UIContext, message: ResourceStr): void {
    try {
      ctx.getPromptAction().showToast({ message, duration: 2000 });
    } catch (e) {
      console.error('Toast failed: ' + JSON.stringify(e));
    }
  }
}
