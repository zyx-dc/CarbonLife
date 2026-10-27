/**
 * 分镜：一拍 = 0.5 秒（120 BPM），每条 2–7 拍。
 *
 * 素材约束：截图只有 1320×2232。铺满 1920 宽的裁切至少要放大 1.45 倍，
 * 正文小字会明显发虚。所以景别靠"整机在画面里变大变小"来做——
 * 整机是从 1320 降采样，怎么都比裁切锐；只有大数字、图表这类
 * 图形元素才允许满屏裁切。
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
      /** 水平偏移（画面宽度比例） */
      dx?: number;
      drift?: number;
    }
  | {
      kind: "card";
      beats: number;
      ground?: "light" | "dark";
      lines: { text: string; size: number; weight: number; lime?: boolean }[];
    };

const REC = "03-record-3km.png";
const AFTER = "04-home-after.png";
const REP = "05-report.png";
const D1 = "06-dash-day.png";
const D2 = "07-dash-week.png";
const D3 = "08-dash-month.png";
const RW = "09-rewards.png";
const KN = "10-knowledge.png";

export const SHOTS: Shot[] = [
  // ① 先立论
  { kind: "card", beats: 3, ground: "light", lines: [
    { text: "13 种低碳行为", size: 64, weight: 700 },
  ] },

  // ② 记录：中景 → 近景，同一屏两刀
  { kind: "phone", beats: 5, asset: REC, ground: "light", height: 800,
    caption: "四类场景，一次记录" },
  { kind: "phone", beats: 4, asset: REC, ground: "light", height: 860, dx: 0.04,
    caption: "填一个数量" },

  // ③ 结果：暗场 + 大数字，全片最重的一击
  { kind: "card", beats: 5, ground: "dark", lines: [
    { text: "0.51", size: 268, weight: 700, lime: true },
    { text: "kg CO₂e · 一次步行 3 公里", size: 27, weight: 400 },
  ] },

  // ④ 首页跟着变
  { kind: "phone", beats: 5, asset: AFTER, ground: "light", height: 790,
    caption: "减排、积分、成长值同时更新" },
  { kind: "phone", beats: 4, asset: AFTER, ground: "light", height: 860, dx: -0.05,
    caption: "碳小树 · 成长值 270" },

  { kind: "card", beats: 2, ground: "light", lines: [
    { text: "两步。", size: 112, weight: 700 },
  ] },

  // ⑤ 碳账单：主角，暗场给足时间
  { kind: "phone", beats: 7, asset: REP, ground: "dark", height: 820,
    caption: "碳账单" },
  { kind: "close", beats: 4, asset: REP, a: [660, 950, 1290], b: [660, 962, 1260],
    ground: "dark", inset: true, caption: "累计 3.91 kg · 421 积分" },
  { kind: "close", beats: 4, asset: REP, a: [660, 1300, 1290], b: [660, 1312, 1260],
    ground: "dark", inset: true, caption: "减排构成" },

  // ⑥ 看板三连：同一尺寸硬切，只换画面
  { kind: "phone", beats: 4, asset: D1, ground: "light", height: 780, caption: "看板 · 今日" },
  { kind: "phone", beats: 4, asset: D2, ground: "light", height: 780, caption: "看板 · 本周" },
  { kind: "phone", beats: 4, asset: D3, ground: "light", height: 780, caption: "看板 · 本月" },
  { kind: "card", beats: 2, ground: "light", lines: [
    { text: "日 · 周 · 月 · 年", size: 64, weight: 700 },
  ] },

  // ⑦ 积分 / 科普
  { kind: "close", beats: 4, asset: RW, a: [660, 620, 1290], b: [660, 632, 1260],
    caption: "积分 · 徽章 · 植树证书" },
  { kind: "phone", beats: 5, asset: KN, ground: "dark", height: 800,
    caption: "6 篇双碳科普 · 5 题自测" },

  // ⑧ 收尾
  { kind: "card", beats: 5, ground: "light", lines: [
    { text: "CarbonLife", size: 62, weight: 700 },
    { text: "记录每一次低碳行动", size: 26, weight: 400 },
  ] },
];

export const totalFrames = SHOTS.reduce((n, s) => n + s.beats * 30, 0);
