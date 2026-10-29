# 评委让你"用开发工具跑一遍"怎么办

> 场景：评委说「打开工程我看看」「用开发工具跑一下」。
> 目标：**90 秒内让 App 在设备上跑起来**，并且能顺手打开代码讲两句。
> 前提：工程里 `signingConfigs` 是空的（提交版必须如此），所以**不能直接点 Run**。

---

## 零、上场前必须做的（不做就会当场卡住）

| 检查 | 怎么做 | 为什么 |
|---|---|---|
| DevEco 已打开工程并 Sync 完 | 提前 10 分钟开好，别现场等索引 | 首次 Sync 可能 2–3 分钟，评委等不了 |
| 设备/模拟器已连 | `hdc list targets` 有序列号 | 没设备 Run 会直接报错 |
| 华为账号已登录 DevEco | 右上角头像 | **自动签名需要账号**，没登录就签不了 |
| 手机已装过一版 | 桌面有图标 | 签名失败时的兜底：直接点图标演示 |

---

## 一、打开工程（30 秒）

1. **File → Open**
2. 选目录：`C:\Users\39748\Documents\Default Project\CarbonLife`（认 `build-profile.json5`）
3. 右下角进度条走完 → 左侧能看到 `entry / docs / scripts`

> 如果已经开着就不用重开，直接到第二步。

---

## 二、签名（关键，别跳过）

工程里的签名配置是空的，**直接 Run 会报 `signingConfigs is empty`**。

1. **File → Project Structure**（或右上角齿轮）
2. 左侧 **Project → Signing Configs**
3. 勾选 **Automatically generate signature**（自动生成签名）
4. 弹华为账号登录 → 登录后等它生成完 → **Apply / OK**

生成成功后 `build-profile.json5` 里会出现 `signingConfigs`，**这个文件不要提交**（演示完执行 `git checkout -- build-profile.json5`）。

---

## 三、跑起来（30 秒）

**方式 A：直接 Run（推荐，最像"开发"）**
1. 顶部设备下拉框选你的手机（`88X9K26520018645`）
2. 点绿色 ▶ **Run 'entry'**（或 Shift+F10）
3. 等 `Build` + `Install` + `Launch`，底部进度条走完 → 手机自动打开 App

**方式 B：只剩 hdc（Run 出问题时）**
```powershell
devecocli build
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap
hdc shell "aa start -b com.example.carbonlife -a EntryAbility"
```

**方式 C：兜底（设备/签名都出问题）**
直接点手机桌面上的 **CarbonLife** 图标。话术：

> 「构建和签名刚才已经跑过了，我直接用装好的这一版给您演示，代码我这边可以随时打开对照。」

---

## 四、边演示边切代码（这是加分项）

**别只跑 App，评委会怀疑"只会点按钮"。** 跑起来后切回 IDE，按这个顺序打开三个文件：

| 顺序 | 文件 | 一句话 |
|---|---|---|
| 1 | `entry/src/main/ets/model/Sapling.ets` | 「成长算法在这里，是个纯函数：`min(80, 记录×10 + 任务×15)`，上限作用在连签加成之后」 |
| 2 | `entry/src/main/ets/model/CarbonStore.ets` | 「数据层：preferences 持久化、导入校验、RFC 4180 解析，写完版本号 +1」 |
| 3 | `entry/src/main/ets/view/RecordTab.ets` | 「页面只调服务，不自己算减排——这是分层的意思」 |

**快捷键**：`Ctrl+P` 按文件名跳转，`Ctrl+F` 文件内搜索，`Ctrl+Shift+F` 全局搜索。

**能当场演示的两个"活的"证据**（评委最爱看）：
- 改 `Sapling.STAGE_GROWTH` 里的 `60` 成 `20` → 保存 → 重新 Run → 树提前变幼苗（**演示完记得改回来**）
- 打开底部 **Log** 面板，筛选 `CarbonStore`，指着 `store ready; cloud backup enabled=true` 说「这是数据层启动日志」

> ⚠️ 改代码演示有风险：改完必须能改回去。**没有把握就别改**，改成"打开文件讲"。

---

## 五、五种当场翻车与一句话应对

| 现象 | 真实原因 | 你该说的 |
|---|---|---|
| `signingConfigs is empty` | 工程签名被清空（提交要求） | 「源码包按提交要求清空了签名，我点一下自动签名即可」→ 走第二步 |
| 自动签名转圈失败 | 没登录/没网 | 「自动签名依赖账号，我直接用已构建好的包演示」→ 走方式 B/C |
| `Device not found` | USB 掉了 / 没授权 | 「我换根线/重新授权一下」→ 同时用方式 C 兜底 |
| Sync 卡住 | 首次索引 | 「索引还在跑，我先用装好的版本演示，一边等」 |
| Run 成功但 App 白屏 | 装的是旧包/进程残留 | 手机强杀 App 再开；或 `hdc shell "aa force-stop com.example.carbonlife"` |

---

## 六、时间控制

| 阶段 | 目标 |
|---|---|
| 打开工程 | 已提前开好（0 秒） |
| 签名 | ≤ 30 秒（提前做一次，现场就不用做） |
| Run | ≤ 30 秒 |
| 演示 App | 60–90 秒（见 `docs/DEFENSE.md` 第二节） |
| 切代码讲 | ≤ 60 秒（三个文件各一句） |

**超过 3 分钟还没跑起来，就别硬跑**——切到"打开代码讲"，比让评委干等强。

---

## 七、最稳的策略：把"能不能跑"变成"已经跑过"

上台前把这两句准备好：

> 「工程在我电脑上，构建产物和真机安装包都有。**要不要我现在重新构建一次给您看**？」

这句话把选择权交回评委：
- 他说"要" → 你有准备（走第二、三步）
- 他说"不用" → 你省下时间，直接演示 App + 讲代码

**主动提出，比被要求更好。**
