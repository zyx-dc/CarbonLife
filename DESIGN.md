---
version: alpha
name: CarbonLife-design-system
description: >-
  CarbonLife（碳足迹）是一款面向 HarmonyOS / ArkTS 原生（ArkUI 声明式 UI）的
  低碳生活记录与激励 App。视觉语言为「深林绿 + 暖白」的温暖可信体系：以深绿承载品牌与
  关键数据，以琥珀金承载积分与成就，卡片圆角柔和、阴影克制，动效轻量。系统内置浅色/深色
  双主题，并为无障碍提供「减弱动效」开关。目标是让任何 AI Agent 在改动 ArkUI 代码前，
  能读到一套真实存在、与 `common/Theme.ets` 一一对应的设计 token。

platform: HarmonyOS ArkUI (ArkTS, stage model)
targets:
  - phone
  - tablet
sourceOfTruth: entry/src/main/ets/common/Theme.ets
fontStack: "HarmonyOS Sans SC, Noto Sans SC, system default"

# 浅色主题（默认）——与 Theme.light() 对应
colors:
  primary: "#0F3D2E"           # 深林绿：主按钮、关键数据、选中态
  primary-light: "#1B5E20"     # 次级强调、次要数据
  primary-soft: "#ECF0EE"      # 标签底色、选中项背景（代码中 = rgba(15,61,46,0.08)）
  accent: "#FFB300"            # 琥珀金：积分、成就、高亮
  background: "#F5F7F5"        # 页面背景
  surface: "#FFFFFF"           # 浮层/弹窗背景
  card: "#FFFFFF"              # 卡片背景
  elevated: "#FFFFFF"          # 提升层级卡片
  on-surface: "#1C1C1E"        # 主文字
  on-surface-muted: "#6E6E73"  # 次级/说明文字
  on-primary: "#FFFFFF"        # 主色按钮上的文字
  divider: "rgba(28,28,30,0.08)"  # 分割线
  border: "rgba(28,28,30,0.10)"   # 卡片/输入框边框
  shadow: "#E6ECE8"            # 卡片阴影色
  error: "#FF453A"             # 删除、错误
  success: "#34C759"           # 成功、完成
  chart-blue: "#0A84FF"
  chart-orange: "#FF9F0A"
  chart-purple: "#BF5AF2"
  chart-teal: "#40C8E0"

# 深色主题色板见正文「Color Palette & Roles → 深色主题」。
# （`colors-dark` 不是合法的 token 键，放这里会被 lint 忽略，故仅存于正文。）

# 字体层级——与 AppTypography 对应（size / weight / lineHeight）
typography:
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

# 圆角——与 AppRadius 对应
rounded:
  none: "0px"
  sm: "8px"
  md: "16px"
  lg: "24px"
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

# 阴影与动效：非 token 键，规范见正文「Depth & Elevation」与「Component Stylings」。
# 阴影 soft radius12/offsetY12，medium radius20/offsetY20；动效 enter 500ms / press 120ms / stagger 60ms。

components:
  card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 {spacing.lg}"
  button-secondary:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 {spacing.lg}"
  button-ghost:
    backgroundColor: "{colors.background}"
    textColor: "{colors.primary}"
    typography: "{typography.body-medium}"
    rounded: "{rounded.md}"
    height: "48px"
    padding: "0 {spacing.lg}"
  stat-value-primary:
    textColor: "{colors.primary}"
    typography: "{typography.h2}"
  stat-value-secondary:
    textColor: "{colors.primary-light}"
    typography: "{typography.h2}"
  stat-value-points:
    textColor: "{colors.accent}"
    typography: "{typography.h2}"
  stats-strip:
    backgroundColor: "{colors.elevated}"
    textColor: "{colors.on-surface-muted}"
    typography: "{typography.caption}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  pill-tab:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "{spacing.xs} {spacing.md}"
  pill-tab-active:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
  tab-bar:
    backgroundColor: "{colors.card}"
    textColor: "{colors.on-surface-muted}"
    height: "64px"
  badge:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary}"
    typography: "{typography.caption-medium}"
    rounded: "{rounded.sm}"
    padding: "{spacing.xs} {spacing.sm}"
  input:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.sm}"
    height: "44px"
  task-card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
  task-check-done:
    backgroundColor: "{colors.success}"
    rounded: "{rounded.full}"
    size: "22px"
    height: "22px"
    width: "22px"
  danger-action:
    textColor: "{colors.error}"
  divider-line:
    backgroundColor: "{colors.divider}"
    height: "1px"
  share-sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  chart-series-travel:
    backgroundColor: "{colors.chart-blue}"
  chart-series-energy:
    backgroundColor: "{colors.chart-orange}"
  chart-series-recycle:
    backgroundColor: "{colors.chart-purple}"
  chart-series-food:
    backgroundColor: "{colors.chart-teal}"
---

## Visual Theme & Atmosphere

CarbonLife 的视觉隐喻是「清晨的森林」：深林绿（`{colors.primary}`）像树冠，暖白画布（`{colors.background}`）像透进来的光，琥珀金（`{colors.accent}`）像积分与成就的奖章。整体气质**温暖、可信、克制**，不喧哗、不炫技——它是一款每天都要打开的记录工具，而不是需要被「惊艳」的营销页。

系统刻意做了三件事来区别于通用默认 UI：

1. **克制的用色**：除主色与强调色外，界面以中性灰阶为主；深色模式下主色换成更亮的薄荷绿（`#34C759`），保证暗底对比度。
2. **柔和的几何**：卡片 16vp 圆角、按钮 16vp 圆角、浮层 24vp 圆角，没有任何直角，呼应「绿色/自然」的品牌温度。
3. **轻量的动效**：进入淡入上滑 500ms、按压缩放 0.97 / 120ms、列表 stagger 60ms。所有动效都遵循无障碍「减弱动效」开关。

**关键特征：**
- 深林绿主色 + 暖白画布构成「清新自然」基调，与「低碳」主题强关联
- 琥珀金专属于积分/成就语义，从不作通用装饰色
- 大字号数据 + 中性灰说明文字，信息层级靠**字号+颜色**而非粗体堆叠
- 全部图标为**单色 SVG 剪影**，运行时通过 `fillColor` 上主题色
- 卡片阴影是「极淡的一层」，多数卡片靠留白与圆角而非阴影区分层级
- 明亮的浅色主题与 OLED 友好的深色主题并行，同一套 token 角色

## Color Palette & Roles

### 品牌 & 强调
- **深林绿**（`{colors.primary}` #0F3D2E）：主按钮背景、关键数据（累计减排）、选中态、Tab 激活色。品牌的「单一电压」。
- **再生绿**（`{colors.primary-light}` #1B5E20）：次级强调、次要数据、正向后动词。
- **柔绿底**（`{colors.primary-soft}` rgba(15,61,46,0.08)）：标签背景、选中项底色、二级按钮底。注意它是低透明度描边色，**不是**独立品牌色。
- **琥珀金**（`{colors.accent}` #FFB300）：**仅供积分与成就语义**（今日积分、徽章、兑换按钮文字）。不得当作通用强调色随意使用。

### 表面 & 背景
- **页面背景**（`{colors.background}` #F5F7F5）：带一丝绿调的暖白，是整个 App 的「呼吸」。
- **卡片**（`{colors.card}` #FFFFFF）：内容卡片与列表项表面。
- **浮层**（`{colors.surface}` #FFFFFF）：弹窗、分享面板。
- **提升层**（`{colors.elevated}` #FFFFFF）：需要再上一级的浮层（深色模式下为 #2C2C2E）。

### 文字
- **主文字**（`{colors.on-surface}` #1C1C1E）：标题与正文。**从不用纯黑**。
- **次文字**（`{colors.on-surface-muted}` #6E6E73）：说明、单位、时间戳。
- **反色文字**（`{colors.on-primary}`）：主色按钮/标签上的文字。

### 语义
- **成功**（`{colors.success}` #34C759）：任务完成勾选、正向状态。
- **危险**（`{colors.error}` #FF453A）：删除、清空、错误提示。

### 图表（数据看板专用）
- **chart-blue** `{colors.chart-blue}` · **chart-orange** `{colors.chart-orange}` · **chart-purple** `{colors.chart-purple}` · **chart-teal** `{colors.chart-teal}`
- 类别映射：出行=蓝、节能=橙、回收=紫、餐饮=青（见 `CarbonFactors.categoryColor`）。

### 深色主题
切换由 `EntryAbility` 写入 `AppStorage 'colorMode'`，`Theme.current()` 据此返回对应色板。**主色在深色下变为薄荷绿以提高可读性，而非继续使用深绿。**

| Role | 浅色 | 深色 |
|---|---|---|
| primary | `#0F3D2E` | `#34C759` |
| primary-light | `#1B5E20` | `#66BB6A` |
| primary-soft | rgba(15,61,46,0.08) | rgba(52,199,89,0.15) |
| accent | `#FFB300` | `#FFB300` |
| background | `#F5F7F5` | `#0A0A0A` |
| surface | `#FFFFFF` | `#1C1C1E` |
| card | `#FFFFFF` | `#121212` |
| elevated | `#FFFFFF` | `#2C2C2E` |
| on-surface | `#1C1C1E` | `#F5F5F7` |
| on-surface-muted | `#6E6E73` | `#8E8E93` |
| on-primary | `#FFFFFF` | `#1C1C1E` |
| divider | rgba(28,28,30,0.08) | rgba(245,245,247,0.10) |
| border | rgba(28,28,30,0.10) | rgba(245,245,247,0.15) |
| shadow | `#E6ECE8` | rgba(0,0,0,0.50) |
| error | `#FF453A` | `#FF6961` |
| success | `#34C759` | `#34C759` |
| chart-blue | `#0A84FF` | `#64D2FF` |
| chart-orange | `#FF9F0A` | `#FFB340` |
| chart-purple | `#BF5AF2` | `#DAA5FF` |
| chart-teal | `#40C8E0` | `#6EE1FF` |

## Typography Rules

### 字体
全站使用系统默认字体（HarmonyOS Sans / 系统中文字体）。不引入自定义字库，通过**字号 + 字重**建立层级。

### 层级

| Token | Size | Weight | Line Height | 用途 |
|---|---|---|---|---|
| `{typography.h1}` | 32 | 700 | 40 | 启动页大标题 |
| `{typography.h2}` | 24 | 700 | 32 | 页面标题 |
| `{typography.h3}` | 20 | 500 | 28 | 弹窗/卡片标题 |
| `{typography.h4}` | 17 | 500 | 24 | 小标题、数据标签 |
| `{typography.body}` | 15 | 400 | 22 | 正文 |
| `{typography.body-medium}` | 15 | 500 | 22 | 列表主文案、按钮文字 |
| `{typography.caption}` | 13 | 400 | 18 | 说明、单位 |
| `{typography.caption-medium}` | 13 | 500 | 18 | 分类标签、小标题 |
| `{typography.small}` | 11 | 400 | 16 | 辅助提示 |

### 原则
- **数据优先**：大数值用 24/32 加粗 + 品牌色或强调色，单位紧随其下用 `caption` + `on-surface-muted`。
- **层级靠字号与颜色**：h4 与 body-medium 同为 15/17 级，靠字重与颜色区分。
- **短文案克制**：说明类文字最多 2 行（`maxLines(2)`），避免卡片高度抖动。

## Component Stylings

> 所有组件均为 ArkUI 自定义组件（`components/` 目录）。此处仅定义视觉规则，交互逻辑见对应 `.ets`。

### 卡片 `AppCard`
- 背景 `{colors.card}`、圆角 `{rounded.md}`(16)、内边距默认 `{spacing.md}`(16)。
- 阴影 `AppShadow.soft()`（radius 12 / offsetY 12 / 阴影色 `{colors.shadow}`）；`showBorder` 时叠加 `0.5px {colors.border}`。
- 进入动画：淡入 + 上移 20vp，500ms，支持 `enterDelayIndex × 60ms` 错峰。

### 按钮 `AppButton`
三种类型，均 48vp 高、`{rounded.md}` 圆角、`{typography.body-medium}`：
- **primary**：底 `{colors.primary}`，字 `{colors.on-primary}`。
- **secondary**：底 `{colors.primary-soft}`，字 `{colors.primary}`。
- **ghost**：透明底 + `1px {colors.primary}` 边框，字 `{colors.primary}`。
- 禁用：底 `{colors.divider}`，字 `{colors.on-surface-muted}`，整体 0.6 透明度。
- 按压：`scale(0.97)`，120ms。

### 分段选择器 / 类别 Pill
- 未选：底 `{colors.background}`、字 `{colors.on-surface}`、圆角 `{rounded.md}`。
- 选中：底 `{colors.primary}`、字 `{colors.on-primary}`。

### 底部导航 `Tabs`
- 背景 `{colors.card}`，高 64vp，5 个入口，图标 24×24 单色 SVG。
- 激活：图标与文字 `{colors.primary}`，图标 `scale(1.08)`；未激活 `{colors.on-surface-muted}` + 0.7 透明度。

### 徽章 `BadgeItem`
- 宽 30%，`{rounded.md}`，内边距 `{spacing.md}`。
- 已解锁：图标 `{colors.primary}`、底 `{colors.primary-soft}`；
- 未解锁：图标 `{colors.on-surface-muted}` + 0.45 透明度、底 `{colors.card}`。

### 任务卡 `TaskCard`
- 未完成：底 `{colors.card}`；完成：底 `{colors.background}`、文字 `{colors.on-surface-muted}`。
- 勾选圆圈 22×22，完成时填充 `{colors.success}`。
- `0.5px {colors.border}` 描边，`{rounded.md}`。

### 输入框
- 底 `{colors.background}`、圆角 `{rounded.sm}`(8)、高 44vp，占位符 `{colors.on-surface-muted}`。

### 图表（Canvas）
- 折线：`{colors.primary}` 2px + 3px 圆点；柱状：`barColor` 默认 `{colors.primary}`。
- 坐标轴 `{colors.divider}` 1px，刻度文字 `{colors.on-surface-muted}` 10px，画布高 180vp。
- 饼图：类别色环，中心挖空为 `{colors.card}`；无数据时画 `{colors.divider}` 圆 + 「暂无数据」。

### 分享面板
- 底 `{colors.card}`、`{rounded.lg}`(24)、内边距 `{spacing.lg}`；遮罩 `rgba(0,0,0,0.45)`。

## Layout Principles

### 间距系统
基于 8 的倍数（含 4 与 2 的微调步进）：

| Token | 值(vp) | 用途 |
|---|---|---|
| `{spacing.xs}` | 4 | 图标与文字间距 |
| `{spacing.sm}` | 8 | 行内元素、小内边距 |
| `{spacing.md}` | 16 | 卡片内边距、模块间距、页面左右边距 |
| `{spacing.lg}` | 24 | 弹窗内边距、大模块间距 |
| `{spacing.xl}` | 32 | 分区间距 |
| `{spacing.xxl}` | 48 | 启动页元素间距 |

### 网格与容器
- 页面内容左右留白固定 `{spacing.md}`(16)，卡片纵向间距 `{spacing.md}`。
- 首页数据卡为 **2×2 网格**（今日减排/积分；累计减排/种树），用竖向 `Divider` 分隔。
- 徽章网格为 **3 列**（每项宽 30%，`SpaceBetween`）。
- 手机为主目标；平板（`deviceTypes: tablet`）暂用同一单列布局，后续再补多列。

### 留白哲学
内容优先：用大字号数据与充足留白强调核心信息，**不要用分割线填满页面**。卡片之间靠间距而非边框区分；仅卡片内部或列表行之间用 `{colors.divider}`。

## Depth & Elevation

| 层级 | 处理 | 用途 |
|---|---|---|
| 0 平坦 | 无阴影，仅 `{colors.border}` 描边 | 列表项、行、科普折叠卡 |
| 1 卡片 | `AppShadow.soft()`（radius 12 / offsetY 12 / `{colors.shadow}`） | 普通内容卡片 |
| 2 浮层 | `AppShadow.medium()`（radius 20 / offsetY 20） | 分享面板、弹出层 |

**阴影哲学**：极淡、单层、暖灰调（浅色为 #E6ECE8，深色为 40% 黑）。App 从不使用沉重投影；深色模式下阴影更依赖 `{colors.elevated}` 的色阶而非阴影本身。

## Do's and Don'ts

### Do
- 用 `{colors.primary}` 承载品牌与关键数据，用 `{colors.accent}` 专门承载积分/成就
- 页面背景用 `{colors.background}`（暖白），卡片用 `{colors.card}`（纯白），形成微妙的表面分离
- 所有按钮保持 `{rounded.md}`(16) 圆角与 `scale(0.97)` 按压反馈，全局一致
- 图标一律用单色 SVG，运行时 `.fillColor(AppColor.PRIMARY)`，使其自动适配主题
- 大数值用品牌色/强调色 + 大字号，单位用 `caption` + `on-surface-muted` 紧贴其下
- 动效统一走 `AppMotion`，并遵守 `reduceMotion`（开启时 duration 置 0）
- 深色主题用 `Theme.dark()` 的对应角色，主色切换为薄荷绿

### Don't
- 不要把琥珀金 `{colors.accent}` 当作通用强调色到处使用——它只属于积分与成就
- 不要用纯黑 `#000000` 作正文色——浅色主题正文用 `{colors.on-surface}` #1C1C1E
- 不要给卡片堆叠多层或深色重投影——本系统只有一层极淡阴影
- 不要用直角卡片/按钮——圆角是品牌温度的一部分
- 不要在列表里塞满分割线——用间距和留白分组
- 不要在 `build()` 中直接硬编码十六进制色值——一律走 `AppColor.*` 动态 token
- 不要在 AI 识图/识别的标签映射里写死模型索引而不加兜底——识别失败必须回退到手动选择

## Responsive Behavior

### 断点（vp）
| 名称 | 宽度 | 变化 |
|---|---|---|
| 手机 | < 600 | 单列，卡片左右 16vp 边距，2×2 数据网格，5 Tab |
| 平板 | ≥ 600 | 目前沿用单列；建议后续把看板/卡片改为 2 列，图表高度提升至 240vp |

### 触控目标
- 主按钮 48vp 高、Tab 项 52vp 高、步进器按钮 44×44vp，均达到 44×44 的最小触控目标。
- 任务/列表行整行可点击，不依赖小图标命中。

### 折叠策略
- 分屏/窄屏下 `Tabs` 设为 `scrollable(false)` + `BarMode.Fixed`，保持 5 项等宽。
- 长文本（科普正文、建议）最多 2 行预览，点击展开。
- 图表用 `width('100%')` 自适应，不做横向滚动。

### 动效降级
- `AppStorage 'reduceMotion' === true` 时：进入动画 duration=0、按压动画 duration=0、stagger=0、Canvas 数值动画直接落到终值。

## Agent Prompt Guide

### 快速取色
- 主按钮：`{colors.primary}` / 文字 `{colors.on-primary}`
- 关键数据：`{colors.primary}`；积分/成就：`{colors.accent}`
- 页面底：`{colors.background}`；卡片：`{colors.card}`
- 主文字 `{colors.on-surface}`；次文字 `{colors.on-surface-muted}`
- 删除/错误：`{colors.error}`；成功/完成：`{colors.success}`

### 示例 Prompt（ArkTS）
1. 「在 CarbonLife 里新建一个内容卡片：背景用 `AppColor.CARD`，圆角 `AppRadius.MD`，内边距 `AppSpacing.MD`，阴影用 `AppShadow.soft()`，进入时用 `AppCard` 的 `enter/enterDelayIndex`。」
2. 「做一个主按钮：高 48，圆角 `AppRadius.MD`，底色 `AppColor.PRIMARY`，文字 `AppColor.TEXT_INVERSE`，字号 15/500，按压缩放到 0.97、时长 120ms。」
3. 「把今日/累计数据做成 2×2 网格：数值 24 加粗，今日用 `AppColor.PRIMARY`、积分用 `AppColor.ACCENT`、累计用 `AppColor.CHART_BLUE`，单位用 13/`AppColor.TEXT_SUB`。」
4. 「给看板加一个折线图：用 `LineChartView`，线色 `AppColor.PRIMARY`，轴色 `AppColor.DIVIDER`，刻度 10px `AppColor.TEXT_SUB`，高度 180。」

### 迭代规则
1. 一次只改一个组件。
2. 颜色/字号/间距一律引用 token（`AppColor` / `AppTypography` / `AppSpacing` / `AppRadius`），禁止硬编码。
3. 新增组件样式，优先在 YAML `components:` 中补一条 token。
4. 修改前先确认上表「Known Gaps」是否涉及该组件，避免把「文档已定义」误当成「代码已生效」。
5. 改完 UI 后运行 `hvigorw assembleHap` 确认可构建。

## Known Gaps & Implementation Notes

> 本文件是**设计规范**。以下状态已对照当前代码（`entry/src/main/ets`）核实，改代码前请先阅读，避免文档与实现漂移。

**已修复（2026-09 复核）：**
- ✅ **深色模式已生效**：`EntryAbility.applyConfiguration` 已改为 `config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK` 并存入 `'dark' | 'light'` 字符串，`Theme.isDark()` 判定正确。
- ✅ **分布式权限已在运行时申请**：`EntryAbility.requestDistributedPermission()` 调用 `requestPermissionsFromUser(['ohos.permission.DISTRIBUTED_DATASYNC'])`。
- ✅ **家庭碳积分已支持聚合**：`FamilyService` 改为 `members: MemberData[]`，按 `deviceId` 区分成员，`getSaved()/getPoints()` 对全部成员求和。
- ✅ **图表重绘已修正**：`Chart.ets` 在动画回调与 `reduceMotion` 分支中显式调用 `this.draw()`，并移除了 `DashboardTab` 的 `.id('dashboard_' + version)` 强制重建 hack。
- ✅ **`clearAll()` 连带清空兑换记录**：`records` 与 `redemptions` 一起清空，积分余额不再可能为负。
- ✅ **CSV 导出已转义并加 BOM**：含逗号/引号/换行的字段按 RFC 4180 转义，输出以 `\uFEFF` 开头（Excel 中文不再乱码）。
- ✅ **家庭成员列表已展示**：`HomeTab` 家庭卡片新增成员列表（昵称 + 「我」标记 + 各自减排/积分），按 `deviceId` 区分，`sessionId` 非空时显示；`FamilyService` 已导出 `MemberData` 并提供 `isLocal()`。

**仍待完成：**
- **减弱动效是死代码**：`reduceMotion` 仍被硬编码为 `false`，且没有 UI 开关；`AppMotion` 的降级分支不会执行。
- **平板未做多列布局**：`deviceTypes` 已声明 tablet，但布局仍是单列。
- **UI 层文档**：旧版 `DESIGN_SYSTEM.md` 已由本文件取代（保留作历史参考）。
