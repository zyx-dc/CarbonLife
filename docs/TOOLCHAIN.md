# 开发工具使用说明（DevEco Studio + 命令行）

> 面向：要在这台机器上改代码、打包、装机、看日志的人。
> 内容全部来自这个项目实际踩过的坑，不是抄官方文档。

---

## 一、环境要求

| 项 | 本机实际值 |
|---|---|
| IDE | DevEco Studio，安装在 `D:\DEStudio\DevEco Studio` |
| SDK | `D:\DEStudio\DevEco Studio\sdk`，HarmonyOS 7.0 / **API 26** |
| JDK | 随 IDE 自带：`D:\DEStudio\DevEco Studio\jbr` |
| 工程 target | `compatibleSdkVersion 26.0.0`（低于此版本的设备装不上） |
| CLI 工具 | `C:\Users\<用户>\AppData\Roaming\npm\devecocli.cmd` |
| hdc | `D:\DEStudio\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe` |

> 环境变量：跑单测前需要 `$env:DEVECO_SDK_HOME = "D:\DEStudio\DevEco Studio\sdk"`。

---

## 二、打开工程与设备连接

1. DevEco Studio → **File → Open** → 选 `CarbonLife` 目录（认 `build-profile.json5`）
2. 首次打开会 Sync，等右下角进度条结束
3. **真机连接**
   - 手机：设置 → 关于手机 → 连点 7 次「版本号」→ 开发者选项 → 打开「USB 调试」
   - 插数据线 → 手机弹「允许 USB 调试」→ 勾**始终允许** → 确定
   - 校验：`hdc list targets` 看到序列号即成功
4. **模拟器**：`devecocli emulator start "Mate 90 Pro"`

### 连不上的排查顺序

| 现象 | 原因 | 处理 |
|---|---|---|
| `No active devices` | 没插/没授权 | 看手机有没有弹窗；拔插一次 |
| `Unauthorized` | 调试授权没点 | 手机上点「允许」，或撤销授权后重插 |
| `[Fail] need connect-key` | 通道没建立（常见于锁屏） | 解锁保持亮屏，等 3–5 秒重试 |
| `[Fail] E000004 communication channel is being established` | hdc 服务在重建 | `hdc kill` → 等 2 秒 → `hdc start` → 等 10 秒 |
| `[Fail] E001005 Device not found` | 线掉了或 USB 模式是"仅充电" | 换 USB 模式为「传输文件」 |

---

## 三、构建

### 图形界面
`Build → Build Hap(s)/APP(s) → Build Hap(s)`

### 命令行（更常用）
```powershell
devecocli build                      # debug
devecocli build --build-mode release # release
devecocli build clean                # 清理
```
产物：`entry/build/default/outputs/default/entry-default-signed.hap`

> 构建成功但装机报签名不一致时，先看第四节。

---

## 四、签名（这个项目最容易卡的一环）

### 4.1 自动签名（真机调试用，最省事）
```powershell
devecocli signature generate --force
devecocli build
```
它会：生成本机密钥对 → 向 AGC 换一份 **debug profile** → 重写 `build-profile.json5` 的 `signingConfigs`。

**注意**：`build-profile.json5` 里会写入**加密后的**密码串。这个文件**不能提交**：
```powershell
git checkout -- build-profile.json5   # 提交前必做
```

### 4.2 发布证书（上架 / 全队统一用）

1. 生成密钥库与 CSR（一次性）：
```powershell
keytool -genkeypair -alias carbonlife -keyalg EC -groupname secp256r1 `
  -sigalg SHA256withECDSA -dname "CN=CarbonLife,OU=App,O=CarbonLife,L=Zhengzhou,ST=Henan,C=CN" `
  -validity 9125 -keystore carbonlife-release.p12 -storetype PKCS12 -storepass <密码> -keypass <密码>
keytool -certreq -alias carbonlife -keystore carbonlife-release.p12 -storepass <密码> -sigalg SHA256withECDSA -file carbonlife-release.csr
```
2. AGC → 证书 → 新建证书（**发布证书**）→ 上传 `.csr` → 下载 `.cer`
3. AGC → Profile → 新建（**发布**）→ 选刚建的证书 → 选应用 → 下载 `.p7b`
4. 出包：`powershell -ExecutionPolicy Bypass -File scripts\sign-release.ps1`

**为什么用脚本而不用 `devecocli build`**：hvigor 要求 `storePassword` 是 DevEco 加密后的 64 位串，明文会被拒：
```
00303116 Configuration Error: The length of the storePassword or keyPassword field ... is less than 32
```
脚本改走 SDK 自带的 `hap-sign-tool.jar`，认明文，也是 CI 的标准做法。

### 4.3 装不上的四种错

| 报错 | 含义 | 处理 |
|---|---|---|
| `9568322 signature verification failed due to not trusted app source` | **发布包不能直接 hdc 装** | 用调试签名；发布包只能走应用市场 |
| `install sign info inconsistent` | 新包和已装包的签名不同 | `hdc uninstall com.example.carbonlife` 再装 |
| `insufficient disk memory` | 模拟器 `/data` 满 | 清日志 `hilog -w stop && hilog -w clear`，或重建模拟器 |
| `compatible version` 相关 | 设备 API < 26 | 换设备；或下调 `compatibleSdkVersion`（会丢部分能力） |

---

## 五、安装、启动、看日志

```powershell
# 安装（-r 覆盖安装，保留数据）
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
hdc install -r -u <hap>          # 更彻底的覆盖
hdc uninstall com.example.carbonlife   # 清数据重装

# 启动 / 停止
hdc shell "aa start -b com.example.carbonlife -a EntryAbility"
hdc shell "aa force-stop com.example.carbonlife"

# 日志（本项目关注的 tag）
hdc shell "hilog -x" | Select-String "VisionService|RecordTab|FamilyService|CloudBackup|CarbonStore"
```

项目里的关键日志：

| 日志 | 含义 |
|---|---|
| `VisionService: decoded WxH` | 图片解码成功 |
| `VisionService: obj[i] label=.. score=..` | 检测候选（前 10 个），排查误判用 |
| `VisionService: objects=N` | 检测返回物体数 |
| `VisionService: detect failed at <step>` | 失败在 open / decode / detector-create / process |
| `CarbonStore: store ready; cloud backup enabled=` | 数据层与云开关状态 |
| `GetDefaultBucket ... 403` | 云存储鉴权失败（签名指纹不匹配） |

---

## 六、截图与 UI 自动化

```powershell
# 截图（真机只接受 .jpeg 后缀）
hdc shell "snapshot_display -f /data/local/tmp/a.jpeg"
hdc file recv /data/local/tmp/a.jpeg .\a.jpeg

# 用 devecocli 驱动 UI（坐标由 layout 给，不要手猜）
devecocli ui layout --device <序列号> --format json
devecocli ui click  --device <序列号> <x> <y>
devecocli ui fling  --device <序列号> x1 y1 x2 y2
devecocli ui screenshot --device <序列号> --path .\shot.png
```

> 坐标必须来自 `ui layout`。真机 1280×2800 和模拟器 1320×2232 完全不同，手写的坐标一定点错。

---

## 七、单测与静态检查

```powershell
$env:DEVECO_SDK_HOME = "D:\DEStudio\DevEco Studio\sdk"
& "D:\DEStudio\DevEco Studio\tools\hvigor\bin\hvigorw.bat" test --mode module -p module=entry@default -p product=default
devecocli check lint
```
结果看 `entry\.test\default\intermediates\test\coverage_data\coverage.log` 里的 `Tests run: N`。

---

## 八、提交前清单

- [ ] `git checkout -- build-profile.json5`（去掉签名密码）
- [ ] 仓库里没有 `.p12` / `.p7b` / `.cer`
- [ ] 没有编译产物（`build/`、`.hvigor/`、`oh_modules/`）
- [ ] `agconnect-services.json` 的 `client_secret` / `api_key` 已清空（或明确写进 README 说明）
- [ ] README 写清楚：需要在 AGC 自行下载配置、需要 API 26 设备

---

*对应提交 `d5d6776` · 2026-10-29*
