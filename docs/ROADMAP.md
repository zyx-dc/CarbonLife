# CarbonLife 后续技术方案（Roadmap）

> 面向剩余 open issues 的可执行技术设计：#2 家庭聚合、#5 云同步、#7 图标、#10 多语言。
> 每节含「现状 / 根因 / 方案 / 实施步骤 / 验收标准 / 风险」。
> 关联仓库：https://github.com/zyx-dc/CarbonLife/issues

---

## 1. #2 家庭碳积分跨设备聚合

### 现状
- `FamilyService` 使用 `@kit.ArkData` 的 `distributedDataObject`。
- 每台设备 `create(ctx, FamilyData{members: MemberData[]})`，再 `setSessionId(同一家庭码)`。
- 本机成员写入 `members` 数组（已改为整体赋值），`getSaved()/getPoints()` 对 `members` 求和。
- **2026-10-01 复测**：单机生成家庭码后状态由「未加入」→「等待对方」，并出现「家庭成员 1 人 · 我」；跨设备并集仍受限（下方根因），故本条保持 open。

### 根因
DistributedDataObject 的同步粒度是**对象级**（同名对象字段以 last-write-wins 覆盖），
**不是数组元素的并集**。两台设备各自的 `members` 会互相覆盖，导致「家庭聚合」实际只显示一台设备的数据。
此外 DDO 无法枚举组内其他设备创建的对象，因此「按 deviceId 汇聚成员」在 DDO 上不可行。

### 方案 A（推荐）：分布式 KV 存储
改用 `@ohos.data.distributedKVStore`：

```
key   = `member:${deviceId}`        // 每设备一条，天然按设备分键
value = JSON.stringify(MemberData)  // { deviceId, nickname, saved, points, updatedAt }
group = familySessionId             // 以家庭码作为 KVStore 组标识
```

- 写入：`pushLocal()` → `kvStore.put('member:' + localDeviceId, json)`。
- 读取：`kvStore.getEntries()` 前缀过滤 `member:` → 反序列化为 `MemberData[]`。
- 变更：`kvStore.on('dataChange', ...)` → 重新聚合 + `notify()`。
- 聚合：`getSaved()/getPoints()` 对全部 `member:*` 求和。

### 方案 B（备选，限制大）
仍用 DDO，但每设备一个扁平对象；需额外交换对端 deviceId 才能聚合，且无法枚举成员 → 不推荐。

### 实施步骤
1. 新增 `FamilyKvStore`（封装 DKV 的 open/put/getEntries/on）。
2. `FamilyService` 改为读写 KV；`MemberData` 序列化保持兼容。
3. 家庭码作为组名；`joinSession/leaveSession` 切换组并清理本地缓存。
4. 保留 `getMembers()/getSaved()/getPoints()/isLocal()` 接口不变，UI 无需改。

### 验收标准
- [ ] 两台登录**同一华为账号**的设备输入相同家庭码后，均显示「家庭成员 2 人」。
- [ ] 家庭减排/积分 = 两台设备之和。
- [ ] 离线编辑后恢复网络可自动合并（以 `updatedAt` 较新者为准）。
- [ ] 退出家庭组后不再显示其他成员。

### 风险
- DKV 分布式同步需同账号 + 可信组网；**模拟器可能不支持**，须双真机验证。
- 需申请/声明 `DISTRIBUTED_DATASYNC`（已声明）。

---

## 2. #5 数据云同步与备份

### 现状
- 数据仅存本地 `preferences`（`records` / `redemptions` / `task_rewards`）。
- 已支持导出/导入 CSV、JSON（手动备份）。

> **进度（2026-10 更新）**：
> - 阶段 1（已实施）：`CarbonStore.exportSnapshot()/importSnapshot()` —— 整包快照（`records` + `redemptions` + `taskRewards`，含 `version`/`updatedAt`）导出与去重合并恢复；看板「本地数据管理」新增「备份全部数据 / 从备份恢复」；导入 JSON 时自动识别快照对象。
> - 阶段 2（已实施）：`model/CloudBackup.ets` 接入 **AGC 云存储**（bucket `carbonlife-z58pd`，数据区中国）；`waitTask` 30s 超时；未启用时自动回退本地，本地备份始终可用。
> - 阶段 2 修复（2026-10-10）：补上 **`ohos.permission.INTERNET`**（`uploadFile`/`downloadFile` 的必需权限，缺失时返回 `201`）；`downloadFile` 增加 `overwrite:true`、失败路径补齐 `hilog` 错误码（`201`/`1008220001`/`1008220009`/`1008221001`），UI 区分「云备份不可用」与「云备份失败」。
> - 待办：冲突合并策略（`updatedAt` 取新 / 按 `record.id` 并集，当前为按 id 并集）与**签名构建下的端到端验证**（云存储需真机 + signed 构建，模拟器/unsigned 会在默认实例查询时报 `sign error 1008200009`）。


### 分阶段方案
**阶段 1（已完成）**：本地导出/导入，作为手动备份与迁移手段。

**阶段 2：云端备份（推荐先做）**
- 用华为 AGC（AppGallery Connect）**Cloud DB** 或**云存储**，按华为账号隔离。
- 备份对象：`records`、`redemptions`、`taskRewards`（整体 JSON 快照 + 版本号）。
- 入口：设置/看板「备份到云」「从云恢复」。
- 冲突：整包快照按 `updatedAt` 取新；或按 `record.id` 做并集合并。

**阶段 3：自动增量同步**
- 记录级 `updatedAt` + 软删除标记，双向增量合并。

### 实施步骤（阶段 2）
1. 接入 AGC SDK，完成应用注册与鉴权（`@kit.CloudFoundationKit` / Cloud DB）。
2. 定义 `BackupSnapshot { version, updatedAt, records, redemptions, taskRewards }`。
3. `BackupService.backup()/restore()`，失败时回退本地。
4. UI 增加备份/恢复按钮与状态提示。

### 验收标准
- [ ] 登录后可手动上传/下载快照。
- [ ] 换机后恢复历史记录与积分。
- [ ] 恢复前有二次确认；失败不破坏本地数据。

### 风险
- 需 AGC 项目与网络；**隐私合规**（需隐私政策说明与用户授权）。
- 数据量小，注意免费额度与限流。

---

## 3. #7 正式应用图标与启动图

### 现状（2026-10 更新：已完成）
`AppScope/resources/base/media/app_icon.png`、`entry/.../media/app_icon.png`、`startIcon.png` **已替换为品牌图标**（叶片 + 品牌深绿），并已在模拟器桌面、任务卡与启动页实机核对通过；`ic_walk.svg` 亦重绘为清晰的行走人形。历史「模板占位」描述作废。

### 规格
| 资源 | 位置 | 建议规格 |
|---|---|---|
| 应用图标（源） | `AppScope/resources/base/media/app_icon.png` | 1024×1024 PNG，直角，居中安全区 |
| 应用图标（entry） | `entry/src/main/resources/base/media/app_icon.png` | 216×216 / 288×288 PNG |
| 启动窗口图标 | `entry/.../media/startIcon.png` | 与图标一致 |
| 分层图标（可选） | `media/foreground.png` + `background.png` | HarmonyOS 自适应图标 |
| 启动背景色 | `resources/base/element/color.json` → `start_window_background` | 品牌深绿 `#0F3D2E` 或暖白 |

### 实施步骤
1. 设计 1024 源图（叶片 + 碳足迹意象，品牌深绿/薄荷绿）。
2. 导出各尺寸，替换上述文件（保持文件名）。
3. `module.json5` 的 `icon`/`startWindowIcon`/`startWindowBackground` 指向不变。
4. 深/浅色与多分辨率实机校验。

### 验收标准
- [ ] 桌面、任务卡、设置中图标清晰无锯齿。
- [ ] 冷启动过渡自然（图标→Splash）。
- [ ] 各分辨率（1x/2x/3x）显示正常。

### 风险
需设计素材（人力），无技术阻塞。

---

## 4. #10 多语言本地化（完整 i18n）

### 现状（2026-10 更新：基础已完成）
- `resources/base|en_US|zh_CN/element/string.json` 已承载界面文案；`common/Localize.ets` 的 `resolveStr()` 统一读取资源。
- 修复了一个真实 bug：`resolveStr()` 此前未把 `$r(id, ...args)` 的实参透传给 `getStringSync`，导致图表轴标签渲染成 `%s`；现已透传。
- 仍可继续完善：个别动态拼接文案可进一步改为占位符/资源键。

### 目标
主要界面文案从资源读取；英文环境下无中文残留。

### 资源键命名规范
```
{页面}_{组件}_{语义}     例：home_title、record_save_button、dashboard_export_csv
通用/复用：common_confirm、common_cancel、common_imported_count
```

### 实施步骤
1. 建立键表：以 `resources/base/element/string.json` 为唯一真相（中文）。
2. 逐 Tab 替换硬编码：`Text('数据看板')` → `Text($r('app.string.dashboard_title'))`。
3. 动态文案用占位符：`'已导入 %d 条记录'` → `$r('app.string.common_imported_count', n)`（或 `util.format`）。
4. 补 `en_US`（英文）与 `zh_CN`（中文，与 base 对齐）。
5. 验收：系统语言切英文，遍历 5 个 Tab 与弹窗无中文残留。

### 工作量评估
- 涉及 5 个 Tab + 6 个组件 + 4 个服务，约 **120–160 个字符串键**。
- 建议按 Tab 分批（每批一个 PR），便于回归。

### 验收标准
- [ ] 主要界面文案均来自 `app.string.*`。
- [ ] `en_US` 无中文、`zh_CN` 无英文残留。
- [ ] 切换语言后无需重启即生效。

### 风险
- 字符串拼接（如 `'差 ' + n + ' 分'`）需改用占位符，注意 ArkTS 资源格式化用法。
- 与正在进行的 UI 改动并发时易冲突，建议单独分支。

---

## 通用回归清单

每次改动后：
1. `powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -BuildOnly` → BUILD SUCCESSFUL。
2. `hvigorw test --mode module -p module=entry@default -p product=default` → 用例全绿。
3. 模拟器/真机：记录→首页实时刷新、看板周期切换、积分兑换、提醒时间、数据导入导出。
4. 深色模式切换无残留硬编码色值。

> 约定：数据层单例 `CarbonStore`；服务 `Xxx.get()` 单例；UI 通过 `AppStorage` 的
> `recordsVersion` / `familyVersion` 与 `changeListeners` 感知变更。改 UI 前先读 `DESIGN.md`。
