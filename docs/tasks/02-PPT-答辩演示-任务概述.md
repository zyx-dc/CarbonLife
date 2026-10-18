# 任务概述 · PPT 组：制作《CarbonLife 碳足迹》答辩 PPT

> 给非技术同学看的任务说明。你要做的是把项目「讲清楚、讲好看」，不需要懂代码。
>
> **状态（2026-10-08）**：✅ 已交付——`docs/tasks/ppt/CarbonLife-答辩PPT.pptx`（15 页）、同目录 `.pdf` 与 `讲稿要点.md`。
> 本文件保留为**任务说明与验收标准**；重制流程见下方「6.1 PPT 构建方式」。

---

## 1. 这个 App 是什么（一句话背景）

**CarbonLife（碳足迹）** 是一款跑在**鸿蒙手机**上的低碳生活记录 App：用户记录步行、骑行、公交、省电、回收、光盘等低碳行为，App 自动算出**减排量**和**碳积分**，积分能换权益、拿徽章、种树，还能和家人共享「家庭碳积分」。

- 关键词：**双碳目标 · HarmonyOS 原生 · 端侧 AI · 无云隐私 · 家庭共享**。
- 快速了解请看仓库根目录 `README.md`。

## 2. 你的交付物

| 项 | 要求 |
|---|---|
| 文件名 | `CarbonLife-答辩PPT.pptx` |
| 篇幅 | **12–15 页**，对应 **5–8 分钟**讲解 |
| 比例 | 16:9，风格干净，字大、图大、留白多 |
| 配套 | 另附一页「讲稿要点」（每页 2–3 句口头词） |

## 3. 逐页大纲（照着做即可）

| 页 | 标题 | 内容要点 |
|---|---|---|
| 1 | 封面 | 项目名 CarbonLife 碳足迹 + 一句话定位 + 团队/成员 |
| 2 | 痛点与选题 | 双碳背景 + 日常低碳行为「难记录、没反馈、难坚持」 |
| 3 | 我们做了什么 | 一句话产品：记录低碳行为 → 算减排和积分 → 激励与家庭共享 |
| 4 | 目标用户 | 关注环保的普通家庭 / 学生 / 上班族 |
| 5 | 功能总览 | 一张图罗列 8 大功能（见下第 4 节，用图标卡片排版） |
| 6 | 亮点 1：13 种低碳行为 | 出行/节能/回收/餐饮四类，自动算减排与积分 |
| 7 | 亮点 2：端侧 AI 识图 | 拍照自动推荐低碳行为，图片不出本机 |
| 8 | 亮点 3：数据看板 | 日/周/月/年图表 + CSV/JSON 导出 |
| 9 | 亮点 4：家庭碳积分 | 家庭码 + 跨设备聚合 + 成员列表 |
| 10 | 亮点 5：积分荣誉体系 | 积分、商城兑换、徽章、植树证书、今日任务 |
| 11 | 设计与体验 | 深林绿 + 暖白 + 琥珀金；浅/深双主题（放对比截图） |
| 12 | 技术底座 | HarmonyOS / ArkTS / ArkUI 声明式 UI；本机存储、端侧 AI、权限 |
| 13 | 隐私与安全 | 数据不上云、家庭同步不经过第三方、识图不出本机 |
| 14 | 验证与质量 | 真机/模拟器逐条验收（引用 `HANDOFF.md` 的验收清单） |
| 15 | 展望与致谢 | 后续路线图（对接真实碳普惠平台 / 数据导入 / 平板适配）+ 谢谢 |

## 4. 功能总览（第 5 页用）

低碳行为记录 · 端侧 AI 识图 · 数据看板与导出 · 积分与荣誉 · 家庭碳积分 · 每日提醒 · 双碳科普 · 浅色/深色主题。

## 5. 视觉规范（让 PPT 和 App 长得像一家人）

> **口径说明**：设计唯一真相是 `DESIGN.md`（`DESIGN_SYSTEM.md` 已归档 DEPRECATED，仅历史参考）。
> App 的浅色主题为「日光纸感」：暖白底 + 墨绿主色，青柠只作信号填充；深色主题为「夜行荧光」。

答辩 PPT 采用**浅色主题**，主色板如下（与 App 浅色主题同源）：

| 用途 | 颜色 |
|---|---|
| 主色（标题条/重点） | 品牌深绿 `#0F3D2E`（App 图标资产同色） |
| 强调色（积分/成就） | 暖琥珀 `#E8A317` |
| 页面背景 | 暖白 `#F5F7F5`（= App 浅色主题底色） |
| 正文文字 | `#14201A` |

> 说明：App 界面内的强调色是电青 `#3DE0C8`（深色）/ `#0B7261`（浅色）；答辩演示材料为保证远距离投影可读性改用暖琥珀，属有意为之，不是 App 内的原始色值。

- 字体：微软雅黑 / 思源黑体，标题加粗。
- 一页一个观点，**不要堆文字**；数字要大、要醒目。

## 6. 素材在哪

| 内容 | 位置 |
|---|---|
| 功能/卖点文字 | `README.md` |
| 配色与视觉规范 | `DESIGN.md` |
| 验收结论 | `HANDOFF.md`、`QA_REPORT.md` |
| **成品 PPT / PDF / 讲稿** | `docs/tasks/ppt/` |
| **PPT 构建工程（脚本 + 素材）** | `ppt_tasks/carbonlife-defense/` |

**推荐截图**（最新一轮已统一重截并放在仓库根目录，480px、JPEG）：
- 启动页 `screen3.jpeg`
- 首页 `app_home_new.jpeg`
- 记录页 `app_record_new2.jpeg`（含端侧 AI 识图卡片）
- 看板 `app_dashboard.jpeg`（日周期，汇总 + 趋势 + 类别占比）
- 积分 `app_rewards_v4.jpeg`
- 科普 `app_knowledge.jpeg`

> 上述截图对应 2026-10 最新 UI（墨绿选中态、吸底保存、商城可达性、看板口径修正等）。
> 历史取证截图仍在 `docs/qa/`，仅作归档，**不建议**再用于答辩演示。

### 6.1 PPT 构建方式（可复现）

答辩 PPT 使用 `ppt-design-skill`（`pptx-designer`）的 Build Mode 生成，不是一个手工文件：

```powershell
# 1) 生成 .pptx（输出到 ppt_tasks/carbonlife-defense/output/）
python ppt_tasks\carbonlife-defense\build_deck.py
# 2) 渲染 PDF + 逐页 PNG 用于视觉复核
powershell -ExecutionPolicy Bypass -File "<ppt-design-skill>\scripts\render_pptx.ps1" `
  -InFile ppt_tasks\carbonlife-defense\output\CarbonLife-答辩PPT.pptx `
  -OutDir ppt_tasks\carbonlife-defense\output\rendered
# 3) 缩略图总览（可选）
python ppt_tasks\carbonlife-defense\contact_sheet.py
```

生成后把 `output/CarbonLife-答辩PPT.pptx` 与 `output/rendered/CarbonLife-答辩PPT.pdf`
复制到 `docs/tasks/ppt/`（交付目录），`output/CarbonLife-答辩PPT-讲稿要点.md` → `docs/tasks/ppt/讲稿要点.md`。

- 设计方向与 token：见 `ppt_tasks/carbonlife-defense/theme-lock.yaml`、`visual-direction.md`（浅色统一「日光纸感」，全篇无深色页）
- 截图素材：`ppt_tasks/carbonlife-defense/assets/*.jpg`（**当前 UI** 的 1200px 实机截图，已裁掉系统状态栏；构建不依赖未入库的 `docs/qa/`）
- 页级方案 / 复核记录：`page-plan.md`、`brief.md`、`visual-review.md`、`acceptance-contract.md`
- `output/` 为生成产物（已 gitignore），脚本 + 素材 + 任务记录入库即可复现


## 7. 硬性要求与红线

- **不许编造**：用户量、下载量、获奖、合作机构等一律不写；只讲真实功能。
- **未完成的能力**要如实标注：跨设备家庭聚合受 DDO 对象级同步限制仍在打磨；云备份需 AGC 环境与签名构建；「减弱动效」目前是 App 内开关、尚未接入系统无障碍。这些只能放「验证与质量」的「已知边界」或「展望」页，不能当作已完成宣传。
- 每页文字尽量 ≤ 40 字个正文行；演讲细节放进「讲稿要点」而不是 PPT 上。

## 8. 验收标准（做完自查）

- [ ] 页数 12–15，能在 5–8 分钟讲完
- [ ] 有一页清晰的「功能总览」
- [ ] 至少 5 张真实 App 截图，清晰不拉伸变形
- [ ] 配色统一走深林绿 / 琥珀金 / 暖白
- [ ] 未完成功能没有当作已完成宣传
- [ ] 附「讲稿要点」，导出 `.pptx` + `.pdf` 各一份

## 9. 建议时间线

| 阶段 | 产出 |
|---|---|
| 第 1 天 | 读 `README.md` + `DESIGN.md`，搭好母版和配色，写完整页标题 |
| 第 2 天 | 填功能页与亮点页（配截图） |
| 第 3 天 | 补技术、隐私、展望页，写讲稿要点 |
| 第 4 天 | 自查验收清单，试讲计时，交负责人复核 |

**有问题找谁**：功能细节与数据口径 → 问项目负责人，不要自己发挥。
