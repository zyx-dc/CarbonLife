# CarbonLife 视觉设计系统

> ⚠️ **已归档 / DEPRECATED**：本文件的内容已迁移并升级为 spec 合规的 [`DESIGN.md`](./DESIGN.md)（YAML design tokens + 9 章节，可被 AI Agent 直接消费）。
> 新工作请以 `DESIGN.md` 为准；本文件仅保留作历史参考。差异提示：`DESIGN.md` 修正了原「验证清单」中不实的勾选（深色模式、减弱动效），并补齐了 `Known Gaps`。

> 版本：v1.0 | 工程：`CarbonLife` OpenHarmony ArkTS | 目标：统一、可维护、具备无障碍考量的视觉体系

---

## 1. 设计方向

### 品牌关键词
- **自然**：深林绿主色，传递低碳、环保、可持续。
- **可信**：信息层级清晰，数据图表准确可读。
- **温暖**：圆角卡片、柔和阴影、恰到好处的动效。
- **无障碍**：浅色/深色模式切换，遵循减弱动效偏好。

### 设计原则
1. 内容优先：用大字号数据、留白和色彩强调核心信息。
2. 一致性：所有图标采用单色实心剪影风格；所有卡片统一圆角与阴影。
3. 反馈即时：按钮、列表项提供按压缩放；操作后有 Toast 反馈。
4. 克制用色：除主色与强调色外，界面以中性灰阶为主。

---

## 2. 色彩系统

### 语义色板（动态主题）

| Token | 浅色模式 | 深色模式 | 用途 |
|-------|---------|---------|------|
| `bg` | `#F5F7F5` | `#0A0A0A` | 页面背景 |
| `card` | `#FFFFFF` | `#121212` | 卡片背景 |
| `surface` | `#FFFFFF` | `#1C1C1E` | 浮层/弹窗背景 |
| `elevated` | `#FFFFFF` | `#2C2C2E` | 提升层级卡片 |
| `primary` | `#0F3D2E` | `#34C759` | 主按钮、关键数据、选中态 |
| `primaryLight` | `#1B5E20` | `#66BB6A` | 辅助强调、次级数据 |
| `primarySoft` | `rgba(15,61,46,0.08)` | `rgba(52,199,89,0.15)` | 标签背景、选中项底色 |
| `accent` | `#FFB300` | `#FFB300` | 积分、高亮、成就 |
| `text` | `#1C1C1E` | `#F5F5F7` | 主文字 |
| `textSub` | `#6E6E73` | `#8E8E93` | 次级/说明文字 |
| `textInverse` | `#FFFFFF` | `#1C1C1E` | 主色按钮上的文字 |
| `divider` | `rgba(28,28,30,0.08)` | `rgba(245,245,247,0.10)` | 分割线 |
| `border` | `rgba(28,28,30,0.10)` | `rgba(245,245,247,0.15)` | 卡片/输入框边框 |
| `shadow` | `#E6ECE8` | `rgba(0,0,0,0.50)` | 卡片阴影 |
| `danger` | `#FF453A` | `#FF6961` | 删除、错误 |
| `success` | `#34C759` | `#34C759` | 成功、完成 |
| `chartBlue` | `#0A84FF` | `#64D2FF` | 图表-累计减排 |
| `chartOrange` | `#FF9F0A` | `#FFB340` | 图表-累计积分 |
| `chartPurple` | `#BF5AF2` | `#DAA5FF` | 图表-记录条数 |
| `chartTeal` | `#40C8E0` | `#6EE1FF` | 图表-餐饮类 |

### 原始色板

| Token | 色值 | 说明 |
|-------|------|------|
| `FOREST` | `#0F3D2E` | 品牌深林绿 |
| `FOREST_LIGHT` | `#1B5E20` | 深林绿亮部 |
| `MINT` | `#34C759` | 深色模式主色 |
| `MINT_SOFT` | `#66BB6A` | 深色模式辅助色 |
| `AMBER` | `#FFB300` | 品牌琥珀金（积分/成就） |
| `BG_LIGHT` | `#F5F7F5` | 浅色背景 |
| `BG_DARK` | `#0A0A0A` | 深色背景 |
| `DANGER` | `#FF453A` | 危险色 |
| `SUCCESS` | `#34C759` | 成功色 |

---

## 3. 字体系统

所有文字使用系统默认字体（HarmonyOS Sans / 系统中文），通过 `FontWeight` 与字号建立层级。

| Token | size | weight | lineHeight | 用途 |
|-------|------|--------|------------|------|
| `H1` | 32 | Bold | 40 | 启动页大标题 |
| `H2` | 24 | Bold | 32 | 页面标题 |
| `H3` | 20 | Medium | 28 | 弹窗/卡片标题 |
| `H4` | 17 | Medium | 24 | 小标题、数据标签 |
| `BODY` | 15 | Regular | 22 | 正文 |
| `BODY_MEDIUM` | 15 | Medium | 22 | 列表主文案 |
| `CAPTION` | 13 | Regular | 18 | 说明文字、单位 |
| `CAPTION_MEDIUM` | 13 | Medium | 18 | 小标题、分类标签 |
| `SMALL` | 11 | Regular | 16 | 辅助提示 |

### 数据展示规范
- 大数值：`24 Bold` + 品牌色/强调色，如「0.00 kg CO₂e」。
- 单位：`CAPTION` + `textSub`，紧跟数值下方。
- 标签：`CAPTION_MEDIUM` + `primarySoft` 背景。

---

## 4. 间距、圆角与阴影

### 间距 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `XS` | 4 | 图标与文字间距、紧凑内边距 |
| `SM` | 8 | 行内元素间距、小卡片内边距 |
| `MD` | 16 | 卡片内边距、模块间距 |
| `LG` | 24 | 弹窗内边距、大模块间距 |
| `XL` | 32 | 页面顶部安全区 |
| `XXL` | 48 | 启动页元素间距 |

### 圆角 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `SM` | 8 | 按钮、输入框、小标签 |
| `MD` | 16 | 卡片、列表项 |
| `LG` | 24 | 大卡片、弹窗 |
| `XL` | 32 | 启动页按钮 |

### 阴影

| Token | radius | offsetY | 用途 |
|-------|--------|---------|------|
| `soft` | 12 | 12 | 普通卡片 |
| `medium` | 20 | 20 | 弹窗/浮层 |

---

## 5. 动效

| Token | 值 | 用途 |
|-------|-----|------|
| `EASE` | `Curve.EaseOut` | 默认缓动 |
| `EASE_IN_OUT` | `Curve.EaseInOut` | 弹窗/切换 |
| `ENTER_DURATION` | 500ms | 页面进入动画 |
| `STAGGER` | 60ms | 列表 stagger |
| `PRESS_DURATION` | 120ms | 按压反馈 |

### 无障碍
- 读取 `AppStorage.get<boolean>('reduceMotion')`。
- 开启「减弱动效」时，所有动画 duration 置为 0。

---

## 6. 图标系统

### 设计规范
- **画布**：24×24 dp，viewBox `0 0 24 24`。
- **风格**：单色实心剪影（glyph），避免内部负形被 `fillColor` 错误填充。
- **着色**：代码中使用 `Image($r('app.media.ic_xxx')).fillColor(AppColor.PRIMARY)`，实现主题自适应。
- **安全区**：图标内容距边缘 ≥2dp，保证小尺寸可读。

### 图标清单

#### 导航图标
| 文件名 | 用途 | 所在位置 |
|--------|------|----------|
| `ic_nav_home.svg` | 首页 Tab | `pages/Index.ets` |
| `ic_nav_record.svg` | 记录 Tab | `pages/Index.ets` |
| `ic_nav_dashboard.svg` | 看板 Tab | `pages/Index.ets` |
| `ic_nav_rewards.svg` | 积分 Tab | `pages/Index.ets` |
| `ic_nav_knowledge.svg` | 科普 Tab | `pages/Index.ets` |

#### 行为类别图标
| 文件名 | 对应行为 key | 用途 |
|--------|--------------|------|
| `ic_walk.svg` | `walk` | 步行替代驾车 |
| `ic_bike.svg` | `bike` | 骑行替代驾车 |
| `ic_bus.svg` | `bus` | 公交替代驾车 |
| `ic_subway.svg` | `subway` | 地铁替代驾车 |
| `ic_power.svg` | `save_power` | 节约用电 |
| `ic_water.svg` | `save_water` | 节约用水 |
| `ic_paper.svg` | `recycle_paper` | 回收纸张 |
| `ic_recycle.svg` | `recycle_plastic` | 回收塑料 |
| `ic_metal.svg` | `recycle_metal` | 回收金属 |
| `ic_clothes.svg` | `recycle_clothes` | 旧衣回收 |
| `ic_clean_plate.svg` | `clean_plate` | 光盘行动 |
| `ic_chopsticks.svg` | `no_disposable` | 少用一次性餐具 |
| `ic_veg.svg` | `veg_meal` | 素食一餐 |

#### 成就徽章图标
| 文件名 | 对应 badge key | 含义 |
|--------|----------------|------|
| `ic_badge_seed.svg` | `b1` | 初识低碳 |
| `ic_badge_travel.svg` | `b2` | 绿色出行家 |
| `ic_badge_energy.svg` | `b3` | 节能小能手 |
| `ic_badge_recycle.svg` | `b4` | 回收先锋 |
| `ic_badge_meal.svg` | `b5` | 光盘行动派 |
| `ic_badge_master.svg` | `b6` | 低碳达人 |
| `ic_badge_neutral.svg` | `b7` | 碳中和先锋 |

#### 功能与权益图标
| 文件名 | 用途 | 所在位置 |
|--------|------|----------|
| `ic_ai_scan.svg` | AI 识图 | `view/RecordTab.ets` |
| `ic_leaf.svg` | 品牌 logo、分享卡片 | `pages/Splash.ets`、`view/HomeTab.ets` |
| `ic_tree.svg` | 植树证书、认养树 | `view/RewardsTab.ets` |
| `ic_medal.svg` | 低碳徽章·青铜 | `model/MallService.ets` |
| `ic_bag.svg` | 环保购物袋 | `model/MallService.ets` |
| `ic_certificate.svg` | 电子证书 | `model/MallService.ets` |

### 图标引用示例

```typescript
// 行为列表
import { behaviorIcon } from '../model/CarbonFactors';
Image(behaviorIcon(b.key))
  .width(24)
  .height(24)
  .fillColor(AppColor.PRIMARY);

// 权益商城
import { redeemIcon } from '../model/MallService';
Image(redeemIcon(item.id))
  .width(28)
  .height(28)
  .fillColor(AppColor.PRIMARY);
```

---

## 7. 应用图标

| 名称 | 文件 | 尺寸 | 说明 |
|------|------|------|------|
| 启动图标 | `entry/src/main/resources/base/media/app_icon.png` | 512×512 px | 深林绿渐变背景 + 白色叶子 |
| 启动页图标 | `entry/src/main/resources/base/media/startIcon.png` | 512×512 px | 启动窗口显示 |
| 品牌图标 | `ic_leaf.svg` | 24×24 dp | Splash、分享卡片、品牌露点 |

---

## 8. 页面 UI 规范

### 8.1 启动页（Splash）
- 背景：深林绿渐变（`#0F3D2E` → `#1B5E20`）。
- 居中：`ic_leaf`（白色）+ 应用名「CarbonLife」+ Slogan。
- 动效：元素淡入上滑 500ms；停留 1.5s 后跳转 `pages/Index`。

### 8.2 首页（HomeTab）
- 布局：纵向 Scroll + Column，模块间距 `MD`。
- 顶部标题：H2 + Caption 副标题。
- 数据卡片：2×2 网格（今日减排/今日积分；累计减排/累计种树）。
- 操作区：两个等宽按钮（主/次）。
- 家庭碳积分卡片：标题行 + 数据行 + 输入框 + 按钮组。
- 每日提醒卡片：Row + Toggle。
- 今日任务卡片：`TaskCard` 列表。
- 智能建议卡片：`ic_power` 图标 + 建议文案。
- 分享弹窗：`shareSheet`，白色卡片 + 深色遮罩。

### 8.3 记录页（RecordTab）
- AI 识图卡片：`ic_ai_scan` + 标题 + 描述 + 按钮。
- 类别选择器：横向 Pill 标签，选中态 `primarySoft` 背景 + `primary` 文字。
- 行为列表：左图标 + 名称/单位 + 右侧 Radio。
- 数量输入：步进器 + 居中输入框。
- 预计减排与积分：左主色文字 + 右强调色文字。
- 保存按钮：全宽主按钮。

### 8.4 看板页（DashboardTab）
- 顶部标题 + 日/周/月/年 分段选择器。
- 汇总行：累计减排（主色）/ 累计积分（强调色）/ 记录条数（蓝色）。
- 趋势卡片：折线图，主色线条，浅背景。
- 对比卡片：柱状图，分类色柱。

### 8.5 积分页（RewardsTab）
- 积分余额：大字号 `accent`。
- 植树证书卡片：`ic_tree` + 文案 + 棵树数据。
- 权益商城：`redeemIcon` + 名称/描述 + 兑换按钮。
- 今日任务：勾选圆圈 + 任务名/描述 + 积分。
- 低碳徽章：3 列网格，`BadgeItem`，未解锁降低透明度。

### 8.6 科普页（KnowledgeTab）
- 顶部标题 + 副标题。
- 折叠列表：标签（`CAPTION_MEDIUM` + `primarySoft` 背景）+ 标题 + 展开图标 + 摘要。

---

## 9. 通用组件规范

### AppCard
- 背景：`AppColor.CARD`
- 圆角：`AppRadius.MD`
- 内边距：默认 `AppSpacing.MD`，可传 `cardPadding`
- 阴影：`AppShadow.soft()`（可关闭）
- 动效：进入时淡入上滑，支持 `enterDelayIndex`

### AppButton
- 高度：默认 48，支持 `btnHeight`
- 圆角：`AppRadius.MD`
- 类型：
  - `primary`：主色背景 + 反色文字
  - `secondary`：主色浅背景 + 主色文字
  - `ghost`：透明背景 + 主色文字 + 主色边框
- 按压：缩放至 0.97，120ms

### BadgeItem
- 尺寸：宽度 30%，内边距 `MD`
- 圆角：`AppRadius.MD`
- 图标：32×32，解锁 `primary`，未解锁 `textSub` + 0.45 透明度
- 背景：解锁 `primarySoft`，未解锁 `card`

---

## 10. 主题集成

### 主题入口
- 文件：`entry/src/main/ets/common/Theme.ets`
- 动态 getter：`entry/src/main/ets/common/Constants.ets` 中的 `AppColor`

### 使用方式
```typescript
import { AppColor } from '../common/Constants';
import { AppSpacing, AppRadius, AppTypography } from '../common/Theme';

Text('今日减排')
  .fontSize(AppTypography.H4.size)
  .fontColor(AppColor.TEXT);

Column()
  .backgroundColor(AppColor.CARD)
  .borderRadius(AppRadius.MD)
  .padding(AppSpacing.MD);
```

### 深色模式
- 通过 `AppStorage.get<string>('colorMode')` 判断。
- 值为 `'dark'` 时，`Theme.current()` 返回深色色板。

### 减弱动效
- 通过 `AppStorage.get<boolean>('reduceMotion')` 判断。
- 开启后，所有进入/按压/stagger 动画 duration 置 0。

---

## 11. 资源目录

```
entry/src/main/resources/base/media/
├── app_icon.png          # 应用启动图标
├── startIcon.png         # 启动页图标
├── ic_leaf.svg           # 品牌叶子
├── ic_ai_scan.svg        # AI 识图
├── ic_nav_*.svg          # 5 个导航图标
├── ic_badge_*.svg        # 7 个徽章图标
├── ic_walk.svg           # 行为：步行
├── ic_bike.svg           # 行为：骑行
├── ic_bus.svg            # 行为：公交
├── ic_subway.svg         # 行为：地铁
├── ic_power.svg          # 行为：节电 / 建议灯泡
├── ic_water.svg          # 行为：节水
├── ic_paper.svg          # 行为：纸张回收
├── ic_recycle.svg        # 行为：塑料回收
├── ic_metal.svg          # 行为：金属回收
├── ic_clothes.svg        # 行为：旧衣回收
├── ic_clean_plate.svg    # 行为：光盘
├── ic_chopsticks.svg     # 行为：少用一次性餐具
├── ic_veg.svg            # 行为：素食
├── ic_tree.svg           # 植树证书 / 认养树
├── ic_medal.svg          # 青铜徽章
├── ic_bag.svg            # 环保购物袋
└── ic_certificate.svg    # 电子证书
```

---

## 12. 构建与验证

### 构建命令
```powershell
$env:DEVECO_SDK_HOME="C:\Program Files\Huawei\DevEco Studio\sdk"
$env:PATH="C:\Program Files\Huawei\DevEco Studio\jbr\bin;$env:PATH"
hvigorw.bat assembleApp --no-daemon
```

### 安装命令
```powershell
hdc app uninstall com.example.carbonlife
hdc app install entry\build\default\outputs\default\entry-default-unsigned.hap
hdc shell aa start -a EntryAbility -b com.example.carbonlife
```

### 验证清单
- [x] 启动页显示品牌叶子与名称
- [x] 底部 5 个导航图标正常渲染，选中态高亮
- [x] 记录页 4 个类别共 13 个行为图标正常渲染
- [x] AI 识图卡片显示 `ic_ai_scan`
- [x] 积分页权益商城 6 个图标正常渲染
- [x] 植树证书标题使用 `ic_tree`
- [x] 徽章网格 7 个徽章图标正常渲染
- [ ] 浅色/深色模式主题色正确切换（已修复颜色枚举比较，需真机/模拟器切主题验证）
- [ ] 减弱动效开关生效（当前默认 false，需接系统 accessibility 设置后验证）
- [x] 运行时申请 `ohos.permission.DISTRIBUTED_DATASYNC`
- [x] 家庭数据按 deviceId 聚合
