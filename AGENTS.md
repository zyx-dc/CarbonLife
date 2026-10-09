# CarbonLife — Agent 上下文（AGENTS.md）

任何 agent 进入本仓库前请先读本文件。

## 项目
- 路径：`C:\Users\39748\Documents\Default Project\CarbonLife`（以仓库根目录为准，避免写死用户名）
- 类型：HarmonyOS / OpenHarmony 原生应用（ArkTS + ArkUI 声明式 UI，stage 模型）
- 包名：`com.example.carbonlife` · 入口 Ability：`EntryAbility` · 启动流程 `pages/Splash` → `pages/Index`
- 目标 SDK：26.0.0（见 `build-profile.json5`）；`deviceTypes: phone, tablet`
- 权限：`ohos.permission.DISTRIBUTED_DATASYNC`（user_grant，运行时申请）、`ohos.permission.PUBLISH_AGENT_REMINDER`（system_grant）

## 目录结构
```
entry/src/main/ets/
├── common/       Constants.ets(AppColor/AppConst) · Theme.ets(tokens/AppMotion) · DateUtil.ets · Localize.ets
├── components/   AppCard · AppButton · Badge · TaskCard · AnimatedNumber · Chart(Canvas)
├── model/        CarbonStore · CarbonFactors · CarbonTypes · Rewards · FamilyService · MallService · ReminderService · VisionService · CloudBackup
├── pages/        Splash · Index(5 Tab)
└── view/         HomeTab · RecordTab · DashboardTab · RewardsTab · KnowledgeTab
scripts/run.ps1   构建(+可选安装启动)封装脚本
scripts/ui-smoke.ps1  设备端 UI 冒烟（devecocli ui 驱动，逐页断言）
ppt_tasks/        答辩 PPT 构建工程（pptx-designer Build Mode）
docs/tasks/ppt/   答辩 PPT / PDF / 讲稿要点
```

## 构建 / 部署（首选 devecocli）
```powershell
$cli = "C:\Users\39748\AppData\Roaming\npm\devecocli.cmd"
& $cli build                                            # 仅构建
& $cli run --device "Mate 90 Pro" --ability EntryAbility # 构建 + 安装 + 启动（--uninstall 先清数据）
& $cli ui screenshot --device "Mate 90 Pro" --path out.png
& $cli ui click --device "Mate 90 Pro" <x> <y>
& $cli ui layout  --device "Mate 90 Pro" --format json --mode simplified
& $cli log --device "Mate 90 Pro" --bundle-name com.example.carbonlife --tail 200
```
- 模拟器：`Mate 90 Pro`（`127.0.0.1:5555`，手机）、`MatePad Pro 13`（`127.0.0.1:5557`，平板）；`devecocli emulator start <name>` 启动。
- 也可用 `scripts/run.ps1 -AllowUnsigned` / `-BuildOnly`（Hvigor 路径）。
- `build-profile.json5` 的 `signingConfigs` 为空 → CLI 默认不产 signed hap；本机模拟器可直接安装 unsigned。真机 / 云备份端到端验证用 `scripts/build-signed.ps1`。
- 本机**未安装 hdc/DevEco Studio**，历史文档里的 `hdc shell ...` 命令仅作参考，请优先使用 `devecocli`。

## 设计规范（唯一真相）
- **`DESIGN.md`**：spec 合规（YAML design tokens + 9 章节），可被 AI 直接消费。改 UI 前先读它。
- 颜色/字号/间距/圆角一律引用 `AppColor.*` / `AppTypography.*` / `AppSpacing.*` / `AppRadius.*`，**禁止硬编码 hex/数值**。
- `DESIGN_SYSTEM.md` 已归档（DEPRECATED），仅历史参考。
- lint：`npx -y -p @google/design.md designmd lint DESIGN.md`（改动 tokens 后跑，应 0 error）。

## 构建 / 部署
```powershell
# 一键：构建 + 安装 + 启动（无签名配置时安装 unsigned HAP，模拟器可用）
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -AllowUnsigned

# 仅构建（不触设备）
powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -BuildOnly
```
- 产物（unsigned）：`entry\build\default\outputs\default\entry-default-unsigned.hap`
- `build-profile.json5` 的 `signingConfigs` 为空 → CLI **不产 signed hap**；但本机模拟器**可直接安装 unsigned**（已验证）。
- 故 `run.ps1` 默认（无 `-AllowUnsigned`/`-BuildOnly`）会因找不到 `*-signed.hap` 而退出 1；自动化请用 `-AllowUnsigned`。

## 设备 / 模拟器（历史 hdc 参考）
```powershell
# 本机未安装 hdc；以下为历史命令，仅在装了 DevEco Studio / SDK 的机器上可用
$hdc = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
& $hdc list targets
& $hdc install -r "entry\build\default\outputs\default\entry-default-unsigned.hap"
& $hdc shell aa start -a EntryAbility -b com.example.carbonlife
& $hdc shell snapshot_display -f /data/local/tmp/s.jpeg
& $hdc shell hilog | Select-String CarbonLife
```
> 日常开发与验证请用上文的 `devecocli`（build / run / ui / log），无需 hdc。

## 代码约定
- 数据层单例 `CarbonStore`；服务类均为 `Xxx.get()` 单例。UI 通过 `AppStorage` 的 `recordsVersion` / `familyVersion` 感知变更。
- 动效统一走 `AppMotion`（受 `reduceMotion` 控制）。
- 不要提交任何密钥/签名材料（`*.p12/*.p7b/*.cer` 位于 `~/.ohos/config`，不入库）；不要改 `signingConfigs`。
- 任何改动都必须能通过 `assembleHap`。

## 分离职责
- 写代码的 agent 不审自己的代码；审查 / 设备验证交 `code-reviewer` / `device-qa`。
- 设备验证流程见 `HANDOFF.md`（本轮）与设备 agent 定义：Claude Code 用 `.claude/agents/device-qa.md`，opencode 用 `.opencode/agent/device-qa.md`。
