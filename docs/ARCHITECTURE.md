# 架构细讲：五层、三条契约、两条路径

> 依据本仓库实际代码（`main@d5d6776`）。每一层的依赖关系都是脚本扫出来的，不是"设计文档里写的"。
> 用途：答辩时被问"你们怎么分层"，或者要改代码前先知道该动哪一层。

---

## 一、全景（依赖只允许向下）

```
┌─ L4 应用骨架 ─────────────────────────────────────────┐
│  entryability/EntryAbility    pages/Index   pages/Splash │
│  启动、权限申请、云与家庭初始化、装配 5 个 Tab            │
└───────────────────────┬──────────────────────────────┘
                        ↓
┌─ L3 页面 ─────────────────────────────────────────────┐
│  view/HomeTab  RecordTab  DashboardTab  RewardsTab  KnowledgeTab │
│  组装组件 + 处理交互 + 把用户动作翻译成 service 调用      │
└───────────────────────┬──────────────────────────────┘
                        ↓
┌─ L2 组件 ─────────────────────────────────────────────┐
│  AppCard AppButton TaskCard Badge RangeSlider          │
│  SaplingView AnimatedNumber + chart/{Line,Bar,Pie}     │
│  受控、无状态、只吃 props 与主题                         │
└───────────────────────┬──────────────────────────────┘
                        ↓
┌─ L1 服务 ─────────────────────────────────────────────┐
│  CarbonStore（唯一数据源）  CarbonFactors（因子表）      │
│  Sapling（成长算法·纯函数）  Rewards / MallService      │
│  VisionService（端侧识图）  FamilyService（分布式）      │
│  ReminderService（代理提醒） BackupService/CloudBackup  │
└───────────────────────┬──────────────────────────────┘
                        ↓
┌─ L0 基础 ─────────────────────────────────────────────┐
│  Constants（token/常量）  Theme（排版/动效）            │
│  DateUtil（日期）  Localize（本地化）                    │
└───────────────────────┬──────────────────────────────┘
                        ↓
              preferences（本机 JSON）
```

**实际依赖方向（脚本扫出来的）**

| 层 | 引用了谁 | 有没有越界 |
|---|---|---|
| `model/*`（12 个） | 只引 `common/*` 和同层 | ✅ **不引用任何 view / components** |
| `components/*`（11 个） | `common/*` + `CarbonTypes`（纯类型） | ✅ 不碰 `CarbonStore` |
| `view/*`（5 个） | `common` + `components` + `model` | ✅ 不互相引用 |
| `pages/Index` | 5 个 `view` | ✅ 只做装配 |
| `entryability` | `model`（Store/Auth/Family/Cloud） | ✅ 生命周期才碰服务 |

> 一个细节：`Badge` / `TaskCard` 引了 `model/CarbonTypes`。这是**纯类型文件**（没有逻辑、没有状态），组件依赖类型是允许的；组件依赖 `CarbonStore`（有状态）才是越界。

---

## 二、每层"不许做什么"

| 层 | 职责 | **禁止** | 违反的后果 |
|---|---|---|---|
| L0 基础 | 常量、主题、日期、文案 | 不持有业务数据 | 主题散落各处，深色模式改不动 |
| L1 服务 | 数据与规则 | **不 import 任何 UI** | 算法绑死界面，无法单测 |
| L2 组件 | 受控渲染 | 不直接读写存储 | 组件不可复用，改一处崩三处 |
| L3 页面 | 组装与交互 | 不自己算减排/成长 | 同一数字三处各算各的，迟早不一致 |
| L4 骨架 | 启动、权限、装配 | 不写业务规则 | 启动逻辑和业务纠缠 |

---

## 三、三条契约（这是整个架构的骨架）

### 契约 1：数据只从 `CarbonStore` 进出
页面不算减排、不算成长，只调服务。**一条记录的减排量只有一个计算点**：

```
saved  = amount × factor          // CarbonFactors 提供 factor
points = round(saved × 100)       // 统一折算
```

### 契约 2：写操作必须让版本号 +1
`CarbonStore` 内部 `versionCounter++` → `AppStorage.setOrCreate('recordsVersion', n)`。
四个 Tab 全部 `@StorageLink('recordsVersion')`，收到变化后各自重算。

### 契约 3：算法是纯函数
`Sapling.compute(stats, todayKey)` 的输入只有"每天几条记录、几个任务"，输出成长值。
不读 `AppStorage`、不碰 UI、不拿当前时间（`todayKey` 由调用方传）——所以能单测。

---

## 四、一条写路径（从点击到四个页面同时变）

```
① RecordTab 点击「保存记录」
      ↓ 拿到 behaviorKey + 数量
② CarbonFactors.find(key) → factor = 0.17
      ↓
③ saved = 3 × 0.17 = 0.51 ; points = 51
      ↓
④ CarbonStore.addRecord(record)
      ├─ this.records.push(record)
      ├─ persist()  → prefs.put('records', JSON.stringify(this.records))
      │                prefs.put('redemptions', ...) / put('task_rewards', ...)
      │                await prefs.flush()
      └─ versionCounter++ → AppStorage['recordsVersion']
      ↓
⑤ 四个 Tab 的 @StorageLink 触发
      ├─ HomeTab      重算今日减排/积分/成长值
      ├─ RecordTab    刷新「今日记录」列表
      ├─ DashboardTab 重算趋势与构成
      └─ RewardsTab   重算可用积分
      ↓
⑥ Sapling.of(store) → 按天聚合 → compute() → 成长值/阶段/连续天数
```

**关键点**：④ 是**唯一**的写入口；⑤ 之后每个页面都从 `CarbonStore` 重新取数，不缓存副本。

---

## 五、一条读路径（状态同步为什么用版本号）

```
写入方            CarbonStore.versionCounter++
                        ↓
共享内存          AppStorage['recordsVersion'] = 3
                        ↓
订阅方            @StorageLink('recordsVersion') version
                        ↓
页面              onVersionChange → 重新从 store 取数据 → 重算 → 重绘
```

**为什么不用 `@Observed`/`@ObjectLink` 或第三方状态库？**
- 数据量小（几千条上限）、页面少（5 个）
- 页面只需要一个"数据变了"的**信号**，不需要共享对象
- 代价是全量重算，实测完全够用；收益是没有"多处持有副本"导致的不一致

---

## 六、存储结构（本机 preferences）

单个 store：`carbon_life_store`

| 键 | 内容 | 形态 |
|---|---|---|
| `records` | 全部低碳记录 | JSON 数组 |
| `task_rewards` | 每日任务奖励（防重复结算） | JSON 数组 |
| `redemptions` | 兑换记录 | JSON 数组 |
| `family_session` / `family_name` / `family_device_id` | 家庭状态 | 字符串 |
| `reminder_id` / `reminder_hour` / `reminder_minute` | 提醒 | 字符串 |
| `backup_*` / 其他设置 | 开关与配置 | 字符串 |

启动流程：`EntryAbility` → `CarbonStore.init(context)` → `preferences.getPreferences` → 读 `records` 反序列化 → 页面可用。
`recordsVersion` 只在内存，重启归零；页面 `aboutToAppear` 会自己拉一次全量，所以不需要持久化版本号。

---

## 七、十个功能分别落在哪一层

| 功能 | 主要落点 |
|---|---|
| 13 种行为 / 4 类 | `model/CarbonFactors`（一张表） |
| 记录与保存 | `view/RecordTab` + `model/CarbonStore` |
| 数据看板 | `view/DashboardTab` + `components/chart/*` |
| 积分与兑换 | `model/Rewards` + `model/MallService` + `view/RewardsTab` |
| 碳小树 | `model/Sapling`（算法）+ `components/SaplingView`（渲染） |
| 碳账单 | `view/HomeTab`（快照 `componentSnapshot` → PNG） |
| 端侧识图 | `model/VisionService`（相机/相册 + Core Vision Kit） |
| 家庭碳积分 | `model/FamilyService`（distributedDataObject） |
| 每日提醒 | `model/ReminderService`（reminderAgentManager） |
| 备份与导入导出 | `model/BackupService` / `CloudBackup` / `CloudAuth` |

---

## 八、这套分层真的有用吗？（三个证据）

1. **识图 bug 只改了 L1**。`new visionBase.Request()` → 对象字面量，改的是 `model/VisionService.ets`，**UI 一行没动**，四个页面照常工作。如果识图逻辑写在 `RecordTab` 里，改完要重测整页交互。
2. **成长算法有 11 个单测**。因为 `Sapling` 是纯函数，测试不用起 UI、不用连设备，毫秒级跑完。
3. **换因子表不动业务代码**。接真实碳普惠平台时只改 `CarbonFactors` 那张表，`CarbonStore` 与所有页面都不受影响——这是分层的直接收益。

---

## 九、白板 30 秒画法

先画一条**竖线**（依赖方向），从上往下写四层：**页面 → 组件 → 服务 → 存储**，然后补三句话：

1. 「依赖只能向下，服务层不引用任何 UI」
2. 「数据只有一个出口：`CarbonStore`，写完版本号 +1，页面各自重算」
3. 「算法是纯函数，所以能单测」

被追问实现细节时，报文件路径：`model/CarbonStore.ets`、`model/Sapling.ets`、`model/VisionService.ets`。
