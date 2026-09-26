---
version: alpha
name: CarbonLife-design-system
description: >-
  CarbonLife（碳足迹）是一款面向 HarmonyOS / ArkTS 原生（ArkUI 声明式 UI）的
  低碳生活记录与激励 App。视觉语言为「夜行荧光」：近黑深色玻璃底，电光青柠作为
  稀缺信号色，电青承载积分与成就；深浅模式跟随系统（冷启动读取系统 Configuration.colorMode，
  运行中实时跟随），浅色为「墨绿 + 纸感」并同样注入青柠信号。目标是让任何 AI Agent 在改动
  ArkUI 代码前，能读到一套真实存在、与 `common/Theme.ets` 一一对应的设计 token。

platform: HarmonyOS ArkUI (ArkTS, stage model)
targets:
  - phone
  - tablet
sourceOfTruth: entry/src/main/ets/common/Theme.ets
fontStack: "HarmonyOS Sans SC, Noto Sans SC, system default"

# ============ 深色主题（默认气质：夜行荧光）——与 Theme.dark() 对应 ============
colors:
  background: "#0A0A0A"          # 页面底色（保持原样，不参与荧光升级）
  surface: "#121712"             # 弹窗/浮层
  card: "#101510"                # 卡片基准（实际卡片多用 glass）
  elevated: "#1A211A"            # 输入框底、提升层级
  primary: "#B6FF2E"             # 电光青柠：品牌 = 信号色
  primary-light: "#7FCB00"       # 次级青柠（渐变末端、muted 强调）
  primary-soft: "rgba(182,255,46,0.14)"   # 青柠低透明底（标签/选中底）
  signal: "#B6FF2E"              # 信号色：填充/描边/辉光（与 primary 同值，语义分离）
  signal-deep: "#7FCB00"
  on-signal: "#0A0F07"           # 青柠填充上的近黑字
  accent: "#3DE0C8"              # 电青：仅积分与成就语义
  magenta: "#FF3D9A"             # 稀有高光：仅作极少量点缀，制造「不和谐的秩序」
  sea: "#2E8B57"                 # 数据可视化补充色：苔绿（类别「餐饮」，与绿系同族）
  on-surface: "#E9F7E0"          # 主文字（带绿调暖白）
  on-surface-muted: "#82917B"    # 次级/说明文字
  text-inverse: "#0A0F07"
  text-inverse-sub: "rgba(10,15,7,0.62)"
  divider: "rgba(255,255,255,0.10)"     # 分隔/网格（中性——避免青柠到处描边「廉价化」）
  border: "rgba(255,255,255,0.16)"      # 控件描边（中性）
  glass: "rgba(18,24,18,0.55)"          # 玻璃卡底
  glass-strong: "rgba(18,24,18,0.82)"   # 高不透明玻璃（hero/选项/输入）
  glass-border: "rgba(255,255,255,0.14)" # 玻璃卡描边（中性）
  scrim: "rgba(6,10,7,0.55)"            # 图片底部压暗
  scrim-fade: "rgba(6,10,7,0.00)"
  shadow: "rgba(0,0,0,0.60)"
  primary-glow: "rgba(182,255,46,0.30)"
  overlay: "rgba(0,0,0,0.72)"
  error: "#FF5C5C"               # 删除/错误
  success: "#B6FF2E"             # 成功/完成（跟随信号色）
  chart-blue: "#4DD0FF"
  chart-orange: "#FFB020"
  chart-purple: "#C77DFF"
  chart-teal: "#3DE0C8"
  chart-line: "#B6FF2E"           # 图表主线：深色=青柠，浅色=#3E8E1E（AppColor.CHART_LINE）

# 背景渐变/光斑（保持原样，非本轮设计变量）：
#   bg-wash-top #0A1410 · bg-wash-bottom #100F0A
#   blobA #6B34C759 · blobB #5C1F5C3A · blobC #4AF2B24C

# ============ 浅色主题（日光纸感）——与 Theme.light() 对应 ============
# colors-light 不是合法 token 键，故仅存于正文「Color Palette & Roles → 浅色主题」。
# 关键：浅色下 primary 为墨绿（保证白底可读），青柠改走 signal 仍作填充/描边。

# 字体层级——与 AppTypography 对应（size / weight / lineHeight）
typography:
  display-lg:
    fontFamily: system
    fontSize: "56px"
    fontWeight: 700
    lineHeight: "64px"
  display:
    fontFamily: system
    fontSize: "46px"
    fontWeight: 700
    lineHeight: "52px"
  h1:
    fontFamily: system
    fontSize: "32px"
    fontWeight: 700
    lineHeight: "40px"
  h2:
    fontFamily: system
    fontSize: "24px"
    fontWeight: 700
    lineHeight: "32px"
  h3:
    fontFamily: system
    fontSize: "20px"
    fontWeight: 500
    lineHeight: "28px"
  h4:
    fontFamily: system
    fontSize: "17px"
    fontWeight: 500
    lineHeight: "24px"
  body:
    fontFamily: system
    fontSize: "15px"
    fontWeight: 400
    lineHeight: "22px"
  body-medium:
    fontFamily: system
    fontSize: "15px"
    fontWeight: 500
    lineHeight: "22px"
  caption:
    fontFamily: system
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "18px"
  caption-medium:
    fontFamily: system
    fontSize: "13px"
    fontWeight: 500
    lineHeight: "18px"
  small:
    fontFamily: system
    fontSize: "11px"
    fontWeight: 400
    lineHeight: "16px"

# 圆角——与 AppRadius 对应（阶梯：卡 28 / 内图 28 顶部 / 按钮 16 / 小件 8 / pill 全圆）
rounded:
  none: "0px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xxl: "28px"
  xl: "32px"
  full: "9999px"

# 间距——与 AppSpacing 对应（vp≈px）
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"

components:
  card:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.xxl}"
    padding: "{spacing.md}"
  button-primary:
    backgroundColor: "{colors.signal}"
    textColor: "{colors.on-signal}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
  button-secondary:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
  hero-panel:
    backgroundColor: "{colors.glass-strong}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  eyebrow:
    textColor: "{colors.on-surface-muted}"
    typography: "{typography.small}"
  stat-value-signal:
    textColor: "{colors.signal}"
    typography: "{typography.h2}"
  stat-value-points:
    textColor: "{colors.accent}"
    typography: "{typography.h2}"
  stat-value-neutral:
    textColor: "{colors.on-surface}"
    typography: "{typography.h2}"
  pill-tab:
    backgroundColor: "{colors.glass-strong}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.full}"
  pill-tab-active:
    backgroundColor: "{colors.signal}"
    textColor: "{colors.on-signal}"
    rounded: "{rounded.full}"
  input:
    backgroundColor: "{colors.elevated}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.sm}"
    height: "44px"
  q-index:
    backgroundColor: "{colors.elevated}"
    textColor: "{colors.signal}"
    rounded: "{rounded.full}"
    size: "22px"
  progress-seg:
    backgroundColor: "{colors.border}"
    rounded: "{rounded.full}"
    height: "6px"
  progress-seg-done:
    backgroundColor: "{colors.signal}"
  chart-grid:
    backgroundColor: "{colors.divider}"
  chart-series-line:
    backgroundColor: "{colors.chart-line}"
  scrim-image:
    backgroundColor: "{colors.scrim}"
  danger-action:
    textColor: "{colors.error}"
---

## Visual Theme & Atmosphere

隐喻是「夜间的低碳仪表盘」：世界是近黑的（`{colors.background}` #0A0A0A），玻璃卡片像暗处的面板（`{colors.glass}`），而**电光青柠 `{colors.signal}` 是唯一的发光信号**——它只出现在真正需要被看见的地方：主操作、当前选中、以及单个关键读数。积分与成就则用**电青 `{colors.accent}`**，像另一种仪表。

系统刻意做了四件事来区别通用默认 UI：

1. **深浅模式跟随系统**：冷启动读取系统 `Configuration.colorMode`（`EntryAbility.onCreate`），运行中切换系统主题由 `onConfigurationUpdate` 实时跟随；`Index` 绑定 `colorMode` 并在其变化时重建 Tabs 子树，确保全部 `AppColor.*` 重新求值。深色为「夜行荧光」气质，浅色为「日光纸感」，两套均完整可用。
2. **青柠是稀缺信号，不是底漆**：一屏内青柠只用于「1 个主 CTA + 1 个关键数字 + 选中态」。其余描边、次级按钮、眉标一律走中性灰绿（`{colors.on-surface-muted}`）或 `{colors.border}`。
3. **玻璃 + 描边代替重投影**：卡片用 `backgroundBlur(24)` + `{colors.glass}` + `1px {colors.glass-border}`；辉光只给主 CTA 与 hero（`AppShadow.glow()`，radius 14 / opacity 0.30）。
4. **眉标（eyebrow）统一**：每页顶部为「英文小字眉标（大写 + `letterSpacing 2.5` + `{colors.on-surface-muted}`）+ 中文大标题」，五个 Tab 共用同一骨架。

**关键特征：**
- 青柠 `{colors.signal}` 与 `{colors.primary}` 同值但**语义分离**：primary 用于文字强调（浅色下为墨绿），signal 专用于填充/描边/辉光。
- 电青 `{colors.accent}` 专属于积分/成就，从不作通用强调色。
- 品红 `{colors.magenta}` 是**「不和谐的秩序」**：一屏至多一处极小的活点（如首页眉标旁的呼吸圆点），制造一个刻意跳出青柠/电青秩序的异质信号，不得用于文字或大面积填充。
- 大数值 + 中性说明文字，层级靠**字号 + 颜色**而非粗体堆叠。
- 图标为**单色双色调 SVG**：形状用 `fill`，层次靠 `fill-opacity`，运行时 `fillColor` 统一染色（见「Icon System」）。
- 页面背景的渐变与光斑、启动页 `Splash` 保持既有设计，不在本系统变量内。

## Color Palette & Roles

### 信号 & 品牌（深色）
- **电光青柠**（`{colors.signal}` #B6FF2E）：主按钮底、选中态、关键读数、描边辉光。**每屏限 1 主 CTA + 1 关键数字。**
- **次级青柠**（`{colors.primary-light}` #7FCB00）：渐变末端、低强度强调。
- **青柠低透底**（`{colors.primary-soft}`）：标签/次级按钮底。
- **近黑字**（`{colors.on-signal}` #0A0F07）：青柠填充上的文字。

### 强调（深色）
- **电青**（`{colors.accent}` #3DE0C8）：**仅积分与成就**（积分数字、任务积分、徽章）。不得当通用强调色。

### 表面 & 背景（深色）
- 页面底 `{colors.background}` #0A0A0A（保持原样）。
- 玻璃卡 `{colors.glass}`；高不透明玻璃 `{colors.glass-strong}`；描边 `{colors.glass-border}`。
- 输入底 `{colors.elevated}`；浮层 `{colors.surface}`。

### 文字（深色）
- 主文字 `{colors.on-surface}` #E9F7E0（带绿调暖白，**不用纯白**）。
- 次文字 `{colors.on-surface-muted}` #82917B（说明、单位、眉标、时间戳）。
- 反色文字 `{colors.on-signal}` / `{colors.text-inverse}`。

### 语义
- 成功/完成 `{colors.success}`（= 信号色）；危险/删除 `{colors.error}` #FF5C5C（**唯一允许的裸红**）。

### 图表
- 折线/柱：`{colors.signal}`、`{colors.primary-light}`；网格 `{colors.divider}`；**类别数据色全部落在绿系** `CarbonFactors.categoryColor`（出行=`signal` 青柠、节能=`accent` 电青、回收=`primary-light` 次级青柠、餐饮=苔绿 `#2E8B57`）——四类可区分，且与「夜行荧光」同色系，不引入蓝/橙等跑色。

### 浅色主题（日光纸感）
浅色下**青柠在白底不可读**，故 `primary` 让位给墨绿，青柠退回 `signal`（只作填充/描边/辉光，其上近黑字）。

| Role | 浅色 |
|---|---|
| primary（文字强调） | `#16210F` 墨绿 |
| primary-light | `#2F4A1D` |
| primary-soft | rgba(22,33,15,0.10) |
| signal / signal-deep | `#B6FF2E` / `#7FCB00` |
| on-signal | `#0A0F07` |
| accent（积分） | `#0E8F79` 深青 |
| background | `#F5F7F5`（保持原样） |
| card / surface / elevated | `#FFFFFF` |
| on-surface | `#12180D` |
| on-surface-muted | `#6A7562` |
| divider | rgba(18,24,13,0.10) |
| border | rgba(18,24,13,0.16) |
| glass / glass-strong | rgba(255,255,255,0.62) / 0.85 |
| scrim | rgba(10,15,7,0.45) |
| error / success | `#E5484D` / `#3E8E1E` |
| chart-* | `#0A84FF` / `#E08600` / `#9B4DFF` / `#0FB5A0` |

## Typography Rules

### 字体
全站系统默认字体（HarmonyOS Sans / 系统中文字体），不引入自定义字库，靠**字号 + 字重**建立层级。

### 层级

| Token | Size | Weight | Line Height | 用途 |
|---|---|---|---|---|
| `{typography.h1}` | 32 | 700 | 40 | 启动页大标题 |
| `{typography.h2}` | 24 | 700 | 32 | 页面标题 |
| `{typography.h3}` | 20 | 500 | 28 | 弹窗/文章标题、统计数值 |
| `{typography.h4}` | 17 | 500 | 24 | 小标题、数据标签 |
| `{typography.body}` | 15 | 400 | 22 | 正文 |
| `{typography.body-medium}` | 15 | 500 | 22 | 列表主文案、按钮文字 |
| `{typography.caption}` | 13 | 400 | 18 | 说明、单位 |
| `{typography.caption-medium}` | 13 | 500 | 18 | 分类标签 |
| `{typography.small}` | 11 | 400 | 16 | 辅助提示、眉标 |

### 原则
- **眉标**：`small` + 全大写 + `letterSpacing 2.5` + `{colors.on-surface-muted}`，每页一条。
- **数据优先**：大数值加粗 + `signal`/`accent`，单位紧随其下用 `caption` + `on-surface-muted`。
- **短文案克制**：说明类最多 2 行（`maxLines(2)`）。

## Icon System

- **网格**：24×24 viewBox，光学边距 2px；几何圆角、无尖角。
- **双色调**：主形 `fill-opacity="1"`；辅助形/暗部 `fill-opacity="0.30"`。因为 `fillColor` 只改颜色不改透明度，**同一份 SVG 在深浅两主题下都保留明暗层次**。
- **实现要点**：暗部必须是「洞」或独立于主形的元素（同一颜色叠加在同一填充上不可见）。带内腔的图标用 `fill-rule="evenodd"` 挖洞，再以 30% 形状填洞。
- **染色**：运行时 `.fillColor(AppColor.PRIMARY)` / `AppColor.SIGNAL` / `AppColor.TEXT_SUB`；选中行用 `signal`，未选中用 `on-surface-muted`。
- **语义**：低碳行为图标（步行/骑行/公交/地铁/节能/回收/餐饮…）语义保留，禁止无意义换形。

## Component Stylings

### 卡片 `AppCard`
- 底 `{colors.glass}` + `backdropBlur(24)` + `1px {colors.glass-border}` + `{rounded.xxl}`(28)。
- 阴影 `AppShadow.soft()`（radius 24 / offsetY 8）；进入动画淡入 + 上移 20vp，500ms，`enterDelayIndex × 60ms` 错峰。

### 按钮 `AppButton`
均 `{rounded.md}`(16)、`{typography.body-medium}`：
- **primary**：底 `{colors.signal}`（渐变到 `{colors.signal-deep}`），字 `{colors.on-signal}`，辉光 `AppShadow.glow()`。**每屏最多一个。**
- **secondary**：底 `{colors.glass}`，字 `{colors.on-surface}`，`1px {colors.border}`——**中性**，不再用青柠描边。
- **ghost**：透明底 + `1px {colors.primary}`，字 `{colors.primary}`。
- 按压 `scale(0.97)` / 120ms。

### 眉标头 `Header`（约定）
`Column`：眉标（`{typography.small}` 大写 + 字距 2.5 + `on-surface-muted`）+ 标题（`{typography.h2}` + `on-surface`）。五 Tab 统一。

### 选项 Pill / 分段
- 未选：底 `{colors.glass-strong}`，字 `{colors.on-surface}`，`1px {colors.border}`。
- 选中：底 `{colors.signal}`，字 `{colors.on-signal}`。

### 底部导航 `Tabs`
- 高 64vp，5 入口，图标 24×24。激活：`{colors.signal}` + `scale(1.1)`；未激活：`{colors.on-surface-muted}` + 0.65。

### 输入框
- 底 `{colors.elevated}`、`1px {colors.border}`、`{rounded.sm}`(8)、高 44vp、值 `{colors.on-surface}`、占位符 `{colors.on-surface-muted}`。

### 图表（Canvas）
- **线色**：统一 `AppColor.CHART_LINE`（深色=信号青柠、浅色=品牌绿 `#3E8E1E`）；折线 2vp 实线 + 3–4vp 同色圆点，面积用同色 32%→0 竖向渐变。点/填充/线同色系，不再用深灰黑。
- **Y 轴**：**动态上限** `niceCeil(dataMax)`（1/1.5/2/2.5/3/4/5/6/8/10 × 10ⁿ），不再固定 0–1.0；轴顶标单位 `kg`。
- **网格**：3 条 `{colors.divider}` 水平横线（25%/50%/75%），坐标轴 `{colors.divider}` 1px，画布高 180vp。
- **刻度文字**：字体单位用 **vp**（`px` 为物理像素会渲染过小）；轴数值 `caption`、横轴刻度 `small`，密集序列隔点显示、末端右对齐；右留白 20vp 防端点被裁。
- **稀疏数据**：本周期 0 条 → 空状态；仅 1 个非零桶 → 柱状（并提示「数据点较少」）；≥2 个非零桶 → 折线。
- 饼图：类别色环，中心挖空 `{colors.card}` + 合计；无数据画 `{colors.divider}` 圆 + 「暂无数据」。

### 看板口径
- 顶部三张汇总卡与「减排趋势」**同口径**：随「日/周/月/年」聚合（本日/本周/本月/本年），文案随之变化（如「kg 本周减排」）。

### 图像卡（科普）
- 封面满幅贴卡（负边距），顶部圆角与卡一致（`{rounded.xxl}`）。
- 底部叠 `{colors.scrim}`→`{colors.scrim-fade}` 压暗统一调性。
- 标签 chip：底 `{colors.overlay}` + 字 `AppColor.ON_OVERLAY`（恒浅色，图片上任何主题都可读；**不抢青柠**）。
- 封面右下角**不加**水印标识；仅保留底部 `{colors.scrim}` 压暗。

### 徽章 `BadgeItem` / 任务卡 `TaskCard`
- 徽章：宽 30%，`{rounded.md}`；解锁图标 `{colors.primary}`；未解锁 `{on-surface-muted}` + 0.45。
- 任务卡：完成时勾选圆填充 `{colors.success}`；`0.5px {colors.border}` 描边。

## Layout Principles

### 间距系统
8 的倍数（含 4/2 微调）：`{spacing.xs}` 4 · `{spacing.sm}` 8 · `{spacing.md}` 16 · `{spacing.lg}` 24 · `{spacing.xl}` 32 · `{spacing.xxl}` 48。
- 页面左右留白 `{spacing.md}`(16)，卡片纵向间距 `{spacing.md}`。
- 徽章网格 3 列（每项 30%）。

### 圆角阶梯
卡/图 `{rounded.xxl}`(28) → 按钮/内块 `{rounded.md}`(16) → 小件 `{rounded.sm}`(8) → pill `{rounded.full}`。**同层不混用。**

### 留白哲学
内容优先：大数值 + 充足留白强调核心；不靠分割线填满页面；组间靠间距而非边框。

## Depth & Elevation

| 层级 | 处理 | 用途 |
|---|---|---|
| 0 平坦 | 无阴影，仅 `{colors.border}` 描边 | 列表行、折叠卡 |
| 1 卡片 | `AppShadow.soft()` | 普通内容卡 |
| 2 辉光 | `AppShadow.glow()`（radius 14 / `{colors.primary-glow}` 0.30） | 仅主 CTA 与 hero |

深色下阴影几乎不可见，层次主要靠 `{colors.glass-strong}` 与 `{colors.border}` 的色阶。

## Do's and Don'ts

### Do
- 青柠 `{colors.signal}` 只用于「1 主 CTA + 1 关键数字 + 选中态」，其余降级为 `on-surface-muted` / `border`。
- 积分/成就一律 `{colors.accent}`；删除一律 `{colors.error}`。
- 每页用统一的「眉标 + 大标题」头。
- 图标用 `fillColor` + `fill-opacity` 双色调，选中 `signal` / 未选 `on-surface-muted`。
- 卡片用玻璃 + 描边；辉光只给主 CTA / hero。
- 浅色下 primary 用墨绿，青柠只作 signal 填充。

### Don't
- 不要把青柠当大面积底漆或到处描边（会立刻「廉价化」）。
- 不要用纯黑作正文、不要用纯白当深色主文字。
- 不要给卡片堆叠多层阴影或深色重投影。
- 不要把电青当通用强调色——它只属于积分/成就。
- 不要在 `build()` 硬编码 hex/数值——一律走 `AppColor.*` / `AppSpacing.*` / `AppRadius.*`。
- 不要改页面背景渐变/光斑的**配色**与 `Splash` 的**品牌色板**（既有设计）；允许在其上叠加缓慢动效（光斑漂移、启动页光晕呼吸/环轨卫星），但必须受 `reduceMotion` 控制。

## Responsive Behavior

### 断点（vp）
| 名称 | 宽度 | 变化 |
|---|---|---|
| 手机 | < 600 | 单列，左右 16vp 边距，5 Tab |
| 平板 | ≥ 600 | 目前沿用单列；建议后续看板/卡片改 2 列，图表高 240vp |

### 触控目标
主按钮 48vp、Tab 52vp、步进器 44×44vp，均 ≥ 44×44。

### 动效语言（Motion）
- **关键读数滚动**：`AnimatedNumber` 以 easeOutCubic 从当前值滚到目标值（首页今日减排、积分余额、看板汇总等），700ms。
- **图表入场**：折线图从左向右揭示 + 面积渐变 + 末端辉光（900ms）；柱图自底向上生长 + 顶部圆角 + 竖向渐变（700ms）；饼图扇形扫入 + 中心合计（800ms）。曲线统一 easeOutCubic。
- **背景呼吸**：首页背景三枚光斑以 9–13s 周期缓慢漂移/缩放（`playMode: Alternate`）。
- **启动页**：光晕呼吸 + 环轨卫星 + 掠光。
- **页面切换**：`Tabs.animationDuration 280ms`。

### 动效降级
`AppStorage 'reduceMotion' === true` 时：进入/按压动画 duration=0、stagger=0、光斑漂移与光晕/环轨不启动、数字滚动直接落终值、Canvas 数值直接落终值。

## Agent Prompt Guide

### 快速取色
- 主 CTA：底 `{colors.signal}` / 字 `{colors.on-signal}`；每屏仅一个。
- 关键数字：`{colors.signal}`；积分/成就：`{colors.accent}`；普通数值：`{colors.on-surface}`。
- 卡片：底 `{colors.glass}` + `1px {colors.glass-border}`；页面底 `{colors.background}`。
- 主文字 `{colors.on-surface}`；次文字/眉标 `{colors.on-surface-muted}`。
- 删除 `{colors.error}`；成功 `{colors.success}`。

### 示例 Prompt（ArkTS）
1. 「做一个页面头：眉标 `KNOWLEDGE`（`AppTypography.SMALL` 大写 + letterSpacing 2.5 + `AppColor.TEXT_SUB`）+ 标题（`AppTypography.H2` + `AppColor.TEXT`）。」
2. 「做一个主 CTA：高 48、圆角 `AppRadius.MD`、底 `AppColor.SIGNAL`、字 `AppColor.ON_SIGNAL`、按压 0.97/120ms。」
3. 「做一个中性次级按钮：底 `AppColor.GLASS`、字 `AppColor.TEXT`、`1px AppColor.BORDER`——不要用青柠描边。」
4. 「输入框：底 `AppColor.ELEVATED`、`1px AppColor.BORDER`、值 `AppColor.TEXT`、占位符 `AppColor.TEXT_SUB`。」
5. 「折线图：线色 `AppColor.SIGNAL`，3 条 `AppColor.DIVIDER` 网格线，轴色 `AppColor.DIVIDER`，刻度 10px `AppColor.TEXT_SUB`，高 180。」

### 迭代规则
1. 一次只改一个组件。
2. 颜色/字号/间距/圆角一律引用 token，禁止硬编码。
3. 新增组件样式，先在 YAML `components:` 补一条 token。
4. 改动前先读「Known Gaps」，避免把「文档已定义」误当「代码已生效」。
5. 改完运行 `scripts\run.ps1 -BuildOnly` 确认可构建。

## Known Gaps & Implementation Notes

> 本文件是**设计规范**。以下状态已对照当前代码核实，改代码前请阅读。

**已实现（2026-09 复核）：**
- ✅ **夜行荧光色板 + 信号色**：`Theme.ets` 深/浅两套色板，新增 `signal/signalDeep/onSignal/scrim/scrimFade/textInverseSub`。
- ✅ **深浅模式跟随系统**：`EntryAbility.onCreate` 读取 `this.context.config.colorMode` 初始化；运行中 `onConfigurationUpdate` 实时跟随；`Index` 绑定 `colorMode`，变化时重建 Tabs 子树以重算全部 `AppColor.*`。
- ✅ **动效升级**：`AnimatedNumber` 数字滚动、图表绘制入场（折线揭示/柱图生长/饼图扫入）、背景光斑呼吸、启动页光晕与环轨、Tab 切换动画——均受 `reduceMotion` 控制。
- ✅ **品红「不和谐的秩序」**：`AppColor.MAGENTA` 上线，首页眉标旁一处分红活点（呼吸），全站仅此一处。
- ✅ **科普专栏升级**：眉标、编号题号、分段进度、满幅封面 + 压暗、青柠信号条。
- ✅ **行为图标双色调**：13 个 SVG 用 `fill-opacity 0.30` 分层；修复 `ic_paper` 文字线不可见。
- ✅ **看板图表**：折线/柱图补 3 条网格线；指标卡主次（减排=signal / 积分=accent / 条数=中性）。
- ✅ **深色模式跟随系统**（浅色亦完整可用）。
- ✅ **家庭聚合 / 清空数据 / CSV BOM / 图表重绘**：见历史修复记录。

**仍待完成 / 已知限制：**
- **分布式权限弹窗**：`12100009` 已消除（改为先查授权态再申请、失败仅降级打日志）。但模拟器/部分环境对该权限不弹动态申请框，系统直接返回 denied（`It does not need to request permission`）→ 属**环境受限**，需真机复测。
- **减弱动效**：已在「首页 → 减弱动效」提供开关（写入 `AppStorage 'reduceMotion'`，`AppMotion.loopOptions` 等统一读取）；尚未接入系统无障碍设置。
- **平板未做多列布局**：仍单列。
- **青柠锚点审计（已收敛）**：关键读数浅色改走墨绿（`AppColor.READING`）、家庭卡片数值降为中性、看板类别数据改走 `chart-*` 数据色板；首页/看板现为「1 主 CTA + 1 关键读数 + 选中态」。
- **图像调性**：文章封面来自 Unsplash，风格不统一；已用底部压暗缓解，后续建议统一叠 duotone 或换冷调低饱和图。
- `DESIGN_SYSTEM.md` 已归档（DEPRECATED），仅历史参考。
