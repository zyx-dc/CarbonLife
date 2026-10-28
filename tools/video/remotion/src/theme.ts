import { Easing } from "remotion";

export const W = 1920;
export const H = 1080;
export const FPS = 60;
/** 120 BPM：一拍 0.5 秒 = 30 帧 */
export const BEAT = 30;

/**
 * 浅底压到 #E9E9EC 而不是近白：白色界面放上去才有边界，
 * 之前 #F3F3F5 上白卡只有 σ≈11 的对比，整帧发灰。
 */
export const LIGHT = "#E9E9EC";
export const DARK = "#080C07";
export const INK = "#12180D";
export const INK_SUB = "rgba(18,24,13,0.62)";
export const PAPER = "#F6F6F8";
export const PAPER_SUB = "rgba(246,246,248,0.55)";
export const LIME = "#B6FF2E";

export const FONT_FAMILY = "CarbonSans, 'Noto Sans SC', sans-serif";

/** 苹果式的入场缓动：只减速，永不 ease-in */
export const EASE_OUT = Easing.bezier(0.16, 1, 0.3, 1);
/** 镜头内部运镜：两端都慢，中段快 */
export const EASE_IO = Easing.bezier(0.45, 0, 0.25, 1);
