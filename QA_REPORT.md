# CarbonLife 设备验收报告（device-qa）

> 日期：2026-09-22 · 设备：模拟器 `127.0.0.1:5555` · 基线：当前工作区（未提交）
> 方式：安装 unsigned HAP → 真机操作 → 截图 / dumpLayout / hilog / 持久化文件取证
> 仅验证，未修改任何源码。构建：`scripts/run.ps1 -BuildOnly` → BUILD SUCCESSFUL。
> 证据文件已统一归档至 `docs/qa/`（本报告内引用的文件名均相对该目录）。

## 结论一览

| # | 验证项 | 结果 |
|---|--------|------|
| 1 | 深色模式 | **PASS** |
| 2 | 分布式权限 | **FAIL** |
| 3 | 家庭聚合 | **BLOCKED** |
| 4 | 清空数据 | **PASS** |
| 5 | CSV 导出 | **PASS** |
| 6 | 图表刷新 | **FAIL**（(a) 通过，(b) 失败） |
| 7 | 记录增删 | **FAIL** |

**PASS 3 / FAIL 3 / BLOCKED 1**

> 注：本报告为 2026-09-22 基线。2026-10-01 复测显示 **#7 已修复**，#6(b)/#3 本地侧待复测——详见文末「2026-10-01 复测更新」。

---

## 详细结果

### [PASS] #1 深色模式
- 通过「设置 → 显示和亮度 → 深色」切换系统主题后，App 实时跟随。
- 证据：
  - 浅色：`qa_perm.jpeg`
  - 系统深色设置页：`qa_dark_settings.jpeg`
  - 深色 Home：`qa_dark_home.jpeg`（背景 `#0A0A0A`、卡片 `#121212`、主色变薄荷绿 `#34C759`、主按钮薄荷绿）
  - 深色科普页：`qa_dark_app.jpeg`
- 备注：验证结束后已把模拟器系统主题恢复为浅色（`qa_light2.jpeg`）。

### [FAIL] #2 分布式权限
- 复现：全新安装后冷启动，观察权限弹窗。
- 期望：首启弹出 `DISTRIBUTED_DATASYNC` 授权框。
- 实际：**没有弹窗**；`requestPermissionsFromUser` 抛错，App 继续运行（降级不崩）。
- 证据：`qa_hilog_evidence.txt`
  ```
  09-22 00:01:34.056 E A00000/CarbonLife: request permission failed: {"code":12100009}
  09-22 00:01:34.641 I A00000/CarbonLife: store ready
  ```
  `12100009`（SDK 定义）= *Common inner error. An error occurs when creating the pop-up window.*
- 定位（建议写代码 agent 复核）：`entry/src/main/ets/entryability/EntryAbility.ets:65` `requestDistributedPermission()`，在 `onWindowStageCreate` 内、`loadContent` 完成前就请求权限，窗口可能尚未就绪导致弹窗创建失败；也可能是模拟器本身不支持该弹窗。
- 降级表现：`PASS`（未崩溃，`store ready` 正常输出）。

### [BLOCKED] #3 家庭聚合
- 真实「两端加入同码合并」需两台登录同一华为账号的设备，单模拟器无法验证（HANDOFF 已预告）。
- 本地侧观察（供两机复测参考）：点「生成家庭码」后，输入框出现码（本地 `@State` 生效），但卡片右上角**仍显示「未加入」且不出现「家庭成员 1 人」列表** —— 与 #6/#7 的 UI 不刷新症状一致。
- 证据：`qa_family.jpeg`、`qa_layout.json`（同一时刻 dump 无「家庭成员」节点）。
- 建议：与 #7 的刷新问题一并排查后，再用两台设备复测。

### [PASS] #4 清空数据
- 预置：7 条记录（119 分）→ 兑换「低碳徽章·青铜」(-100) → 余额应为 19。
- 点「看板 → 数据管理 → 清空全部数据」，确认框文案为「确定要清空全部**碳记录、兑换记录**吗？」。
- 结果：持久化文件两项均清空，重启后「积分」页显示 `可用 0 / 累计获得 0 / 已兑换 0`，**非负数**。
- 证据：`qa_prefs9.bin`（`records=[]`、`redemptions=[]`）、`qa_after_clear.jpeg`。

### [PASS] #5 CSV 导出
- 步骤：新增一条备注含逗号的记录 → 看板「导出 CSV」。
- 结果：文件首 3 字节 `EF BB BF`（**BOM 生效**）；含逗号备注被正确加引号，列未串位。
- 证据：`qa_export.csv`
  ```
  <BOM>id,日期,类别,行为,数量,单位,减排量kgCO2e,积分,备注
  <uuid>,2026-09-22,出行,步行替代驾车,1,km,0.1700,17,"a,bca,bc %"
  ```
- 备注：含引号的备注因 CLI shell 引号转义限制未能直接输入；`csvField()` 对 `"` 的转义（`""`）为代码级确认。

### [FAIL] #6 图表刷新
- **(a) 周期切换：PASS** —— 点「日/周/月/年」，标题与坐标轴随周期变化（日→09-16..09-22；周→第1周..第6周；月→4月..9月），折线刷出新值。
  - 证据：`qa_dash_day.jpeg`、`qa_dash_week.jpeg`、`qa_dash_month.jpeg`
- **(b) 新增记录后刷新：FAIL** —— 新增记录后停留在看板，汇总仍为 `0.00 / 0 / 0`；重启后才变为 `0.17 / 17 / 1`。
  - 证据：新增后 dump（`0.00/0/0`）vs 重启后 `qa_dash_day.jpeg`（`0.17/17/1`）
- **(c) 0→终值增长动画**：未能用静态截图确认（无录屏），最终值渲染正常，不作结论。

### [FAIL] #7 记录增删
- 复现（干净对照，重装清数据）：
  1. 记录页点「保存记录」→ 出现 Toast「记录成功，减排 0.17 kg CO₂e」
  2. 持久化文件随即出现 1 条记录（`records=1`）
  3. 但「今日记录」仍显示「今天还没有记录」，回到首页「今日减排/积分」仍为 `0.00 / 0`
  4. 强制重启 App 后，首页与列表才显示 `0.17 / 17`
- 期望 vs 实际：保存/删除后列表与首页应实时同步；实际**不刷新，需重启**。
- 证据：`qa_saved.jpeg`（Toast）、`qa_prefs5.bin`（`records=1`）、保存后 dump 首页 `0.00`、重启后 dump `0.17`。
- 定位（建议写代码 agent 复核）：`CarbonStore.notify()`（`entry/src/main/ets/model/CarbonStore.ets:94`）通过 `AppStorage.setOrCreate('recordsVersion', v+1)` 通知，但各 Tab 的 `@StorageLink` 未见重渲染（同一现象：`onGenCode` 改的是本地 `@State`，界面能变；改的是 AppStorage 派生值，界面不变）。删除同理不刷新。

---

## 汇总

```
[PASS]    #1 深色模式
[FAIL]    #2 分布式权限      (证据: qa_hilog_evidence.txt, code 12100009)
[BLOCKED] #3 家庭聚合        (单模拟器无法验证双机同步)
[PASS]    #4 清空数据
[PASS]    #5 CSV 导出
[FAIL]    #6 图表刷新        ((a) 周期切换通过，(b) 新增后不刷新)
[FAIL]    #7 记录增删        (保存/删除后 UI 不刷新，需重启)
```

`PASS 3 / FAIL 3 / BLOCKED 1`

### 优先级建议
- **P1（功能不生效，且同源）**：#7、#6(b)、#3 本地侧 —— 均指向「`AppStorage` 通过 `setOrCreate` 变更未能触发 `@StorageLink` 重渲染」。这是本次最大问题，建议优先定位（`CarbonStore.notify()` / `FamilyService.notify()` 与各 Tab 绑定）。
- **P1**：#2 权限弹窗未出现（`12100009` 弹窗创建失败）——建议把权限请求改到 `loadContent` 回调之后 / 首次交互时触发，再在真机复测。
- **P2**：#6(c) 动画增长未取证，建议用录屏补充。

---

## 2026-10-01 复测更新（devecocli + 模拟器）

> 环境：DevEco Studio 26.0 · 模拟器 `Mate 90 Pro`（HarmonyOS 7.0.0 / API 26.0.0）· 工具 `devecocli 1.3.0-stable`
> 基线：`master@71ba968` · 命令：`devecocli build` / `devecocli run` / `devecocli ui screenshot`
> 方式：安装并启动 → 驱动 UI（点击/滑动）→ 截图取证

### 结论变化

| # | 验证项 | 9/22 基线 | 10/01 复测 |
|---|--------|-----------|-------------|
| 7 | 记录增删后 UI 刷新 | FAIL | **PASS** |
| 6 | 图表刷新 | FAIL(b) | **PASS** |
| 3 | 家庭聚合（本地侧） | BLOCKED | **PASS**（单机） |
| 2 | 分布式权限弹窗 | FAIL | 未复测（需真机） |

### [PASS] #7 记录增删实时刷新（原 FAIL）

复现（模拟器实机）：
1. 记录页基线：今日记录「今天还没有记录」，首页「今日减排」= `0.00`
2. 选择「步行替代驾车」1 km → 点「保存记录」
3. 观察记录页与首页

结果：
- 记录页「今日记录」**立即**出现 `步行替代驾车 1km · 0.17 kg · 删除`（**无需重启**）
- 首页「今日减排」**立即**变为 `0.17 kg CO₂e`、「今日积分」= `47`
- `47 = 17（记录）+ 30（今日任务：绿色出行 +20、坚持记录 +10）` → 任务奖励同步实时结算
- 证据：`devecocli ui screenshot` 截图（记录页保存后、首页保存后）

结论：原先「`AppStorage.setOrCreate` 变更未触发 `@StorageLink` 重渲染」的现象已消除。

### [PASS] #6(b) 图表刷新（原 FAIL(b)）

新增记录后切到「看板」：汇总「`0.17 kg` / `47 分` / `1 条`」与柱状图、饼图**立即**正确呈现，**无需重启**。

### [PASS] #3 家庭聚合（本地侧，原 BLOCKED）

首页「加入 / 管理家庭组」→「生成家庭码」：
- 状态由「未加入」变为「**等待对方**」
- 立即出现「**家庭成员 1 人** · 我 · `0.17 kg` · `47 分`」，家庭码 `271958843`

说明：**跨设备**聚合（两台设备同码合并为 2 人、减排/积分求和）仍需双机复测，且受 DDO 对象级覆盖限制（见 `docs/ROADMAP.md` #2）。

### 新发现并修复：积分口径不一致

- 现象：首页「今日积分」= `47`（记录 17 + 任务奖励 30），看板「今日积分」= `17`（仅记录）。
- 根因：`DashboardTab.refreshData()` 只累加 `recs[].points`，未计入 `taskRewards`。
- 修复：汇总积分改为「本周期记录积分 + 本周期任务奖励」，与 `CarbonStore.todayPoints()` 口径一致。复测看板显示 `47` ✅。

### 待复测

- **#2**：分布式权限弹窗需在**真机**（非模拟器）复测。
- **#3 跨设备**：两台同账号设备输入相同家庭码 → 家庭成员 = 2、家庭减排/积分 = 两者之和。

### 构建与静态检查
- `devecocli build` → `BUILD SUCCESSFUL`；ArkTS 告警由一批降至 5 条（均为 `getStringSync` 软废弃提示 + resource 调用可能抛异常）。
- `devecocli check lint`：3 → 1 条（剩余 `AppCard` 的「自定义组件」性能建议，属有意设计）。

---

## 2026-10-08 现状摘要（本轮口径）

> 本报告正文（9/22 与 10/01 两节）是**历史取证**，保留原样。以下是当前状态，便于快速判断。

| # | 验证项 | 当前状态 | 说明 |
|---|--------|---------|------|
| 1 | 深色模式 | **PASS** | 跟随系统 `colorMode`，冷启动与运行中均实时切换；本轮已重截深色首页 / 看板 |
| 2 | 分布式权限弹窗 | **BLOCKED（环境受限）** | `12100009` 已消除；模拟器不弹动态授权框，需真机复测 |
| 3 | 家庭聚合 | **本地 PASS / 跨设备待复测** | 单机家庭码 + 成员列表正常；跨设备并集受 DDO 对象级同步限制 |
| 4 | 清空数据 | **PASS** | — |
| 5 | CSV 导出 | **PASS** | 含 BOM 与 RFC 4180 转义 |
| 6 | 图表刷新 | **PASS** | 周期切换与新增记录均实时刷新；**类别占比已改为跟随所选周期**（本轮修复） |
| 7 | 记录增删 | **PASS** | 保存 / 删除后记录页与首页实时同步，无需重启 |
| 8 | 设备端 UI 冒烟 | **PASS 20/20** | `scripts/ui-smoke.ps1`（`devecocli ui` 驱动，逐页断言） |
| 9 | 云备份（AGC） | **可用（待签名构建端到端）** | `model/CloudBackup.ets` + AGC 云存储；模拟器为 unsigned 构建 |
| 10 | 平板多列 | **部分完成** | 数据看板已多列，其余 4 个 Tab 待补齐 |

**演示素材（2026-10 最新）**：仓库根目录 `screen3.jpeg` / `app_home_new.jpeg` / `app_record_new2.jpeg` /
`app_dashboard.jpeg` / `app_rewards_v4.jpeg` / `app_knowledge.jpeg`；答辩 PPT / PDF / 讲稿见 `docs/tasks/ppt/`。
