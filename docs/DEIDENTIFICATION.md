# 参赛材料去标识化检查报告

> 对应 issue：#17 参赛材料去标识化检查（移除学校/队伍/老师信息）
> 方式：`scripts/deidentify-check.ps1` 自动扫描 + 人工复核
> 范围：`docs/tasks/`（任务概述 md/html）+ `docs/tasks/dist/`（Word/PPT/视频 docx）+ `docs/tasks/ppt/`（.pptx）+ 应用标识
> 最近更新：2026-10-01

## 结论

当前仓库内**未发现真实的**学校 / 学院 / 指导老师 / 队伍 / 实验室 等可识别信息。

| 类别 | 结果 | 说明 |
|---|---|---|
| 文本关键词 | 5 处命中（team/teacher） | 均为任务概述/说明中的模板占位词（「团队名」「已去标识化，不体现团队…」等），**非实际信息**，可忽略 |
| 学校/学院/老师/实验室 | 0 | 无命中 |
| 邮箱 | 0 | 无 `*@*` 命中 |
| Office 文档属性（`.docx` + `.pptx`） | 干净 | `.docx`：`creator/lastModifiedBy=html-to-docx`；`.pptx`：`creator/lastModifiedBy=CarbonLife`（应用名，非个人）；`Company` 均为空；标题以项目名开头 |
| 应用标识 | 通用 | `bundleName=com.example.carbonlife`、应用名 `CarbonLife`，无团队标识 |

复现命令：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deidentify-check.ps1
```

> 说明：脚本现已覆盖 `.docx` 与 `.pptx` 的文档属性；脚本注释保持**纯 ASCII**，兼容 Windows PowerShell 5.1（无 BOM 时按 ANSI 解析）。

## 提交前检查清单

- [ ] 运行 `scripts\deidentify-check.ps1`，结果为 `PASS`（或命中均为可忽略的模板占位词）
- [ ] 最终 `.docx` / `.pptx` 文档属性：**作者、公司、最后修改者** 已清空
      （Office：文件 → 信息 → 检查文档 → 检查并删除文档属性和个人信息）
- [ ] Word / PPT 封面：无团队名、成员名单、指导老师、院校
- [ ] 视频（#14，待产出）：无校园地标 / 门牌 / 校徽；片头片尾无团队名
- [ ] 应用界面截图：无团队标识（应用名 / bundleName / 水印）
- [ ] 由**非本人**复核确认（issue 验收要求）

## 额外提醒

- 若提交**源代码仓库 / 压缩包**：
  - 优先做法：移除 `.git` 目录后再打包；
  - 本仓库 git 历史的作者邮箱已统一为 `zyx-dc@users.noreply.github.com`（2026-10-01 重写历史），不再包含个人邮箱。
- 视频录制时避免出现校园地标、门牌号、桌面文件名 / 路径、聊天窗口中的真实姓名。
