# CarbonLife 交接简报（给 device-qa / 审查 agent）

> 生成时间：2026-09-21 · 基线：当前工作区（未提交）
> 你的任务：**在模拟器上安装最新构建，逐条验证下列验收清单，产出带证据的报告。只验证，不改源码。**
>
> ⚠️ **本文档是 2026-09-21 那一轮的交接记录，第 1 节「本轮变更」已过期。**
> 验收清单（第 2 节）与命令仍可复用；**最新状态**请看 `QA_REPORT.md` 的「2026-10-08 现状摘要」、
> `README.md` 的路线图与 `DESIGN.md` 的 Known Gaps。当前设备验证首选 `devecocli`
> （`build` / `run` / `ui screenshot` / `ui layout` / `log`），本机未安装 hdc。

## 0. 先读
1. `AGENTS.md`（仓库上下文、构建/部署命令）
2. `DESIGN.md`（视觉唯一真相，含 `Known Gaps`）

## 1. 本轮变更（相对上一版）
| 文件 | 变更 |
|---|---|
| `entry/src/main/ets/entryability/EntryAbility.ets` | 深色模式判定改为 `COLOR_MODE_DARK`；新增 `requestDistributedPermission()` 运行时申请 `DISTRIBUTED_DATASYNC` |
| `entry/src/main/ets/model/FamilyService.ets` | 家庭数据改为 `members: MemberData[]`（按 `deviceId` 区分），`getSaved/getPoints` 聚合；导出 `MemberData`；新增 `isLocal()` |
| `entry/src/main/ets/view/HomeTab.ets` | 家庭卡片新增「家庭成员 (N 人)」列表（昵称 + 「我」标记 + 各自减排/积分） |
| `entry/src/main/ets/model/CarbonStore.ets` | `clearAll()` 连带清空兑换记录；`exportCsv()` 增加 RFC 4180 转义 + UTF-8 BOM |
| `entry/src/main/ets/components/Chart.ets` | 动画回调与 `reduceMotion` 分支显式 `this.draw()` |
| `entry/src/main/ets/pages/DashboardTab.ets` | 移除 `.id('dashboard_'+version)` 强制重建 hack；清空弹窗文案同步 |
| `DESIGN.md` | 新增：spec 合规设计规范（YAML tokens + 9 章节 + Known Gaps） |
| `DESIGN_SYSTEM.md` | 标记 DEPRECATED，指向 `DESIGN.md` |

## 2. 验收清单（逐条打勾 / 附证据）
| # | 验证项 | 预期 | 证据 |
|---|---|---|---|
| 1 | 深色模式 | 系统切深色后，App 背景变 `#0A0A0A`、卡片 `#121212`、主色变薄荷绿 `#34C759` | 截图（浅/深各一） |
| 2 | 分布式权限 | 首启弹出 `DISTRIBUTED_DATASYNC` 授权；拒绝后家庭功能降级但不崩 | 截图 + `hilog` |
| 3 | 家庭聚合 | 生成家庭码后家庭卡片出现「家庭成员 1 人 · 我」；两端加入同码后变 2 人，家庭减排/积分 = 两者之和 | 截图 |
| 4 | 清空数据 | 看板「清空全部数据」后：记录为空、积分余额为 **0**（不为负）、兑换记录清空 | 截图 |
| 5 | CSV 导出 | 含逗号/引号的备注不串列；Excel/WPS 打开中文不乱码（BOM 生效） | 导出文件 |
| 6 | 图表刷新 | 看板切「日/周/月/年」及新增记录后，折线/柱/饼图随之刷新，进入时数值由 0 增长 | 截图/录屏 |
| 7 | 记录增删 | 记录页保存/删除后，今日列表、首页「今日减排/积分」同步更新 | 截图 |

## 3. 环境与命令
见 `AGENTS.md`。最小闭环（一条命令完成构建+安装+启动）：
```powershell
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -AllowUnsigned
$hdc = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
& $hdc shell snapshot_display -f /data/local/tmp/s.jpeg; & $hdc file recv /data/local/tmp/s.jpeg .
```
`-AllowUnsigned` 在无签名配置时安装 unsigned HAP（本机模拟器已验证可用）；只构建用 `-BuildOnly`。

## 4. 已知限制（不要误判为 bug）
- **无签名配置**：CLI 仅产 unsigned hap；本机模拟器可安装，真机不可。
- **分布式同步**：需要两台设备登录同一华为账号；单模拟器无法完整验证 → 标「无法验证」而非「失败」。
- **AI 识图**（CoreVisionKit）：依赖图库/相机，模拟器可能无图可选 → 可标记为环境受限。
- **仍存在的缺口**（见 `DESIGN.md` Known Gaps）：`reduceMotion` 恒为 false（无开关）；平板未做多列。

## 5. 报告格式
```
[PASS|FAIL|BLOCKED] #<编号> <验证项>  (证据: 截图路径 / 日志片段)
  FAIL 需附：复现步骤 + 期望 vs 实际 + file:line（若能定位）
```
最后给一行总结：`PASS n / FAIL m / BLOCKED k`。
**只报告，不修改代码**；如需修复，交由写代码的 agent。
