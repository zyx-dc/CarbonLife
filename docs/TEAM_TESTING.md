# CarbonLife 组内测试指南（模拟器 / 虚拟机）

> 面向组员：拿到本项目压缩包后，在自己电脑的 **HarmonyOS 模拟器**上把 App 跑起来并做回归测试。
> 只测，不改源码；发现问题按文末模板反馈。

---

## 1. 你需要什么

| 项 | 说明 |
|---|---|
| 操作系统 | Windows 10/11（脚本为 PowerShell） |
| DevEco Studio | 5.0 及以上，**HarmonyOS SDK API 26.0.0**（`compatibleSdkVersion: 26.0.0`） |
| 设备 | DevEco 自带模拟器（Device Manager → Local Emulator），如 `Mate 90 Pro`（手机）/ `MatePad Pro 13`（平板） |
| 华为账号 | 在 DevEco 里登录（用于自动生成调试签名）。首次 `Run` 时按提示操作即可 |
| 可选 | `devecocli`（命令行工具，装了更好用）；Node.js（Hvigor 构建需要，DevEco 自带） |

> 本仓库**不含**签名材料（`*.p12/*.p7b/*.cer`）。用 DevEco 打开工程后，`File → Project Structure → Signing Configs → 勾选 Automatically generate signature` 即可自动签名。

---

## 2. 方式 A：DevEco Studio（推荐，最省事）

1. 解压压缩包，用 DevEco Studio **Open** 打开工程根目录（含 `build-profile.json5` 的那层）。
2. 等待右下角 **Sync** 完成（会联网拉取 `@ohos/hypium` 等依赖；首次可能需要几分钟）。
3. `Device Manager` 启动一个手机模拟器（如 `Mate 90 Pro`）。
4. 顶部选择模块 `entry`，点击 **Run**（▶）。
5. 首次会提示生成签名，登录华为账号后继续；应用会自动安装并启动。

---

## 3. 方式 B：devecocli（命令行，装了就很快）

```powershell
$cli = "devecocli"   # 或 C:\Users\<你>\AppData\Roaming\npm\devecocli.cmd
& $cli emulator start "Mate 90 Pro"
& $cli run --device "Mate 90 Pro" --ability EntryAbility
# 只构建：
& $cli build
```

---

## 4. 方式 C：scripts/run.ps1（Hvigor 直连）

脚本会**自动探测 DevEco 安装路径**（探测不到就传 `-DevEco`）：

```powershell
# 构建 + 安装 + 启动（无签名配置时安装 unsigned，模拟器可用）
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -AllowUnsigned

# 仅构建
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -BuildOnly

# DevEco 装在非默认路径时：
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -DevEco "D:\Huawei\DevEco Studio" -AllowUnsigned
```

产物：`entry\build\default\outputs\default\entry-default-unsigned.hap`

---

## 5. 自动化测试

### 5.1 设备端 UI 冒烟（推荐，逐页断言）

```powershell
powershell -ExecutionPolicy Bypass -File scripts\ui-smoke.ps1 -Device "Mate 90 Pro"
```

预期结尾：`RESULT: 20 passed, 0 failed`。

### 5.2 单元测试（DateUtil / 排放因子 / 导入校验）

在 DevEco 中右键 `entry/src/test` 运行，或（装了 hvigor CLI）：

```powershell
hvigorw test --mode module -p module=entry@default -p product=default
```

---

## 6. 回归测试清单（手动）

| # | 验证项 | 预期 |
|---|---|---|
| 1 | 深色模式 | 系统切深色后 App 实时跟随（背景 `#0A0A0A`、主色薄荷绿） |
| 2 | 记录增删 | 记录页保存/删除后，今日列表与首页「今日减排/积分」实时更新 |
| 3 | 图表刷新 | 看板切 日/周/月/年、新增记录后折线/柱/饼图随之刷新 |
| 4 | 清空数据 | 看板「清空全部数据」后记录为空、积分不为负 |
| 5 | CSV 导出 | 含逗号/引号的备注不串列；中文不乱码（BOM） |
| 6 | 数据导入 | 导入 JSON/CSV/备份；**构造坏数据（缺字段/负数/超大积分）不应崩溃、不应污染数据** |
| 7 | 积分与商城 | 兑换后余额减少、兑换记录出现 |
| 8 | 家庭碳积分 | 生成家庭码后出现「家庭成员 1 人 · 我」（跨设备合并需两台同账号设备） |
| 9 | 大屏适配 | 平板模拟器上导航变左侧栏、看板多列 |

---

## 7. 已知限制（**不要误判为 bug**）

- **未签名构建**：命令行默认只产 unsigned HAP，模拟器可装；真机需签名构建（`scripts/build-signed.ps1`）。
- **云备份（AGC 云存储）**：需要**真机 + 已签名构建**，且 AGC 已开通云存储；模拟器/unsigned 会在云侧鉴权失败（日志 `sign error 1008200009`）。模拟器上点「备份到云」提示失败属预期。
- **分布式家庭同步**：跨设备合并需两台登录**同一华为账号**的设备；单模拟器只能验证本地侧。
- **AI 识图（CoreVisionKit）**：依赖图库/相机，模拟器可能无图可选 → 标记为环境受限。
- **减弱动效**：目前只有 App 内开关，尚未接系统无障碍设置。

---

## 8. 反馈模板（有问题请按这个格式回）

```
[PASS|FAIL|BLOCKED] #<清单编号> <验证项>
  设备/模拟器：<名称 + 系统版本>
  复现步骤：1) … 2) … 3) …
  期望：…
  实际：…
  证据：截图路径 / hilog 片段（过滤 CarbonLife）
  定位（可选）：file:line
```

三分类：**FAIL**（功能缺陷）/ **BLOCKED**（环境受限）/ **PASS**。
