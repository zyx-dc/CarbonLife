/**
 * 分镜：一拍 = 0.5 秒（120 BPM），每条 3–8 拍。
 *
 * 三条约束：
 * 1) 不能抖：运镜交给 CSS transform（浮点），不用逐帧取整的裁剪。
 * 2) 不能糊：截图 1320 宽，铺满 1920 要放大 1.45 倍，正文小字会虚。
 *    景别靠"整机在画面里变大变小"，只有大数字/图表才做满屏特写。
 * 3) 数据要和 PPT 一致：全部截图取自同一状态
 *    （0.17 kg / 47 分 / 3.57 累计 / 成长值 270 / 连续 6 天）。
 *
 * 底色分配：白色界面一律上暗场（白卡放白底只有 σ≈11 的对比，发灰），
 * 浅色只留给文字卡和浅色界面，明暗交替本身就是节奏。
 */

export type Vec3 = [number, number, number]; // cx, cy, cropW（源图像素）

export type Shot =
  | {
      kind: "close";
      beats: number;
      asset: string;
      a: Vec3;
      b?: Vec3;
      ground?: "light" | "dark";
      inset?: boolean;
      caption?: string;
    }
  | {
      kind: "phone";
      beats: number;
      asset: string;
      ground?: "light" | "dark";
      caption?: string;
      height?: number;
      dx?: number;
      drift?: number;
      /** 点击指示环：源图像素坐标 */
      tap?: [number, number];
    }
  | {
      kind: "card";
      beats: number;
      ground?: "light" | "dark";
      lines: { text: string; size: number; weight: number; lime?: boolean }[];
    };

const HOME = "01-home.png";
const REC = "02-record.png";
const LOWER = "03-home-lower.png";
const REW = "04-rewards.png";
const KNOW = "05-knowledge.png";
const D1 = "06-dash-day.png";
const D2 = "07-dash-week.png";
const D3 = "08-dash-month.png";
const REP = "09-report.png";

export const SHOTS: Shot[] = [
  // ① 立论
  { kind: "card", beats: 4, ground: "light", lines: [
    { text: "13 种低碳行为", size: 64, weight: 700 },
  ] },

  // ② 记录：整机 → 更近，用点击指示说明"就点这里"
  { kind: "phone", beats: 6, asset: REC, ground: "light", height: 800,
    caption: "四类场景，一次记录" },
  { kind: "phone", beats: 5, asset: REC, ground: "light", height: 880, dx: 0.03,
    tap: [235, 964], caption: "选类别" },

  // ③ 端侧 AI：同一屏上半部
  { kind: "phone", beats: 5, asset: REC, ground: "light", height: 880, dx: -0.03,
    tap: [660, 610], caption: "也可以直接拍一张，本机识别" },

  // ④ 结果：暗场 + 大数字，全片唯一的青柠重音
  { kind: "card", beats: 6, ground: "dark", lines: [
    { text: "0.17", size: 268, weight: 700, lime: true },
    { text: "kg CO₂e · 今天第一笔", size: 27, weight: 400 },
  ] },

  // ⑤ 首页跟着变
  { kind: "phone", beats: 6, asset: HOME, ground: "dark", height: 790,
    caption: "减排、积分、成长值同时更新" },
  { kind: "phone", beats: 5, asset: HOME, ground: "dark", height: 880, dx: -0.04,
    caption: "碳小树 · 成长值 270" },

  // ⑥ 任务 + 家庭
  { kind: "phone", beats: 6, asset: LOWER, ground: "dark", height: 800,
    caption: "每日任务 · 家庭碳积分" },

  { kind: "card", beats: 3, ground: "light", lines: [
    { text: "两步。", size: 112, weight: 700 },
  ] },

  // ⑦ 碳账单：主角，暗场给足时间
  { kind: "phone", beats: 8, asset: REP, ground: "dark", height: 820,
    caption: "碳账单" },
  { kind: "close", beats: 5, asset: REP, a: [660, 950, 1290], b: [660, 962, 1260],
    ground: "dark", inset: true, caption: "累计 3.57 kg · 387 积分" },
  { kind: "close", beats: 5, asset: REP, a: [660, 1300, 1290], b: [660, 1312, 1260],
    ground: "dark", inset: true, caption: "减排构成" },

  // ⑧ 看板三连：同尺寸硬切，只换画面
  { kind: "phone", beats: 4, asset: D1, ground: "dark", height: 760, caption: "看板 · 今日" },
  { kind: "phone", beats: 4, asset: D2, ground: "dark", height: 760, caption: "看板 · 本周" },
  { kind: "phone", beats: 4, asset: D3, ground: "dark", height: 760, caption: "看板 · 本月" },
  { kind: "card", beats: 3, ground: "light", lines: [
    { text: "日 · 周 · 月 · 年", size: 64, weight: 700 },
  ] },

  // ⑨ 积分 / 科普
  { kind: "close", beats: 5, asset: REW, ground: "dark", a: [660, 620, 1290], b: [660, 632, 1260],
    caption: "积分 · 徽章 · 植树证书" },
  { kind: "phone", beats: 5, asset: KNOW, ground: "dark", height: 780,
    caption: "6 篇双碳科普 · 5 题自测" },

  // ⑩ 隐私 + 收尾
  { kind: "card", beats: 5, ground: "dark", lines: [
    { text: "数据默认留在本机", size: 52, weight: 700 },
    { text: "云备份由你自己开关", size: 26, weight: 400 },
  ] },
  { kind: "card", beats: 5, ground: "light", lines: [
    { text: "CarbonLife", size: 62, weight: 700 },
    { text: "记录每一次低碳行动", size: 26, weight: 400 },
    { text: "赛题二 · 碳足迹", size: 20, weight: 400 },
  ] },
];

export const totalFrames = SHOTS.reduce((n, s) => n + s.beats * 30, 0);
