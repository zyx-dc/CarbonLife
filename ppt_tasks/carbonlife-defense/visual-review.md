# Visual review

## Render record

- PPTX: `output/CarbonLife-答辩PPT.pptx` (15 slides, 16:9)
- PDF:  `output/rendered/CarbonLife-答辩PPT.pdf`
- PNG:  `output/rendered/slide01.png … slide15.png` (1280×720)
- Renderer: LibreOffice + Poppler（PowerPoint COM 未安装，自动回退）
- Theme: `carbonlife-day-paper`（浅色统一，日光纸感）。全篇无深色页；实机截图统一浅色版。
- 版本 2（依用户意见修订）：移除暗色封面/致谢，实机演示全部改为浅色版。
- Package: pptx-designer 1.0.0b11

## Gate 1 — 视觉观感

PASS。全篇为一套系统：统一眉标 + 大标题 + 信号条；深色封面/收尾与浅色内容形成节奏；真实 App 截图为视觉锚点；页面结构随叙事变化（卡片 / 流程 / 对照 / 分层栈 / 结果对照），非同一模板重复。

首次渲染发现问题并已修订：

- 亮点页右侧手机截图溢出页面底部（裁切）→ 改为 contain-fit（按原比例缩放），并加卡片底衬。
- 亮点页左栏卡片大面积留白 → 改为「编号 + 标题 + 说明」行式排版填满。
- `muted` 语义色解析为次级文字色（偏深橄榄）导致底纹/内框对比偏低 → 底纹改用浅色 `#EAEFE7`。
- 功能总览页底部空 → 增加闭环小结条。

## Gate 2 — 缺陷与交付风险

| ID | Level | 结果 | 证据 |
|---|---|---|---|
| R1 | MUST | PASS | 15 页，16:9，中文 |
| R2 | MUST | PASS | 封面/内容/收尾均为暖白日光纸感；实机截图为浅色版；同一绿色语义系统 |
| R3 | MUST | PASS | 6 张真实 App 截图（记录 / 记录页 AI 卡片 / 看板 / 家庭 / 积分 / 首页 · 科普），按原比例 contain，全部为**当前 UI** 浅色版；素材为 `assets/` 内 1200px 高分图（见「版本 3」） |
| R4 | MUST | PASS | slide 5「8 大功能」2×4 卡片 |
| R5 | MUST | PASS | 无编造指标；封面/文档属性无团队/成员/院校信息 |
| R6 | MUST | PASS | 减弱动效、平板多列、真实碳普惠 API、云备份仅出现在 slide 15 |
| R7 | SHOULD | PASS | 正文 ≥14pt，眉标/页脚 10–11pt；无溢出/重叠/裁切 |
| R8 | SHOULD | PASS | 统一边距/字体/圆角/色彩角色，页面结构有变化 |
| R9 | SHOULD | PASS | 每页 speaker notes + `CarbonLife-答辩PPT-讲稿要点.md` |
| R10 | NICE | PASS | slide 14 引用 QA_REPORT.md 的真实复测结论 |

## 版本 3 — 2026-10-09（截图更新为当前 UI，构建可复现）

- 问题：slide 6 / 7 / 11 原先引用 `docs/qa/*.jpeg`（2026-09 **旧版 UI**：蓝色对勾、旧卡片），
  且 `docs/qa/` 未入库 → 演示与「更新」目标不符，构建也不可复现。
- 处理：
  1. 在模拟器上按**当前 UI** 重截截图（含记录页 AI 卡片），裁掉系统状态栏，输出 1200px 宽 JPEG 到 `assets/`；
  2. `IMG` 全部指向 `assets/*.jpg`，不再依赖 `docs/qa/`；
  3. `phone()` 由 `cover_image()` 改为直接 `add_picture()` 嵌入原图 —— contain-fit 后的框与原图同比例，
     避免 `cover_image` 的 PNG 重编码，PPTX 体积由 8.1MB 回到 **1.8MB**。
- 复核：重新渲染 15 页 PNG + 缩略图，slide 6 / 7 / 11 均已是当前 UI，其余页无回归。
- 交付：`docs/tasks/ppt/CarbonLife-答辩PPT.pptx`（1.8MB）+ `.pdf` + `讲稿要点.md`。

## 结论

两处「MUST/SHOULD」问题（截图裁切、低对比底纹）已修订并重新渲染复核。当前 15 页均通过。用户为最终视觉方向的确认者。
