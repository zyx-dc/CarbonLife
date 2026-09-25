# 参赛材料去标识化检查报告

> 对应 issue：#17 参赛材料去标识化检查（移除学校/队伍/老师信息）
> 方式：`scripts/deidentify-check.ps1` 自动扫描 + 人工复核
> 范围：`docs/tasks/`（任务概述 md/html）+ `docs/tasks/dist/`（Word/PPT/视频 docx）+ 应用标识

## 结论

当前仓库内**未发现真实的**学校 / 学院 / 指导老师 / 队伍 / 实验室 等可识别信息。

| 类别 | 结果 | 说明 |
|---|---|---|
| 文本关键词 | 6 处命中（`team`） | 均为任务概述里的模板占位词「团队名」，**非实际信息**，可忽略 |
| 学校/学院/老师/实验室 | 0 | 无命中 |
| 邮箱 | 0 | 无 `*@*` 命中 |
| docx 文档属性 | 干净 | `creator=html-to-docx`、`lastModifiedBy=html-to-docx`、`Company`/`title` 为空 |
| 应用标识 | 通用 | `bundleName=com.example.carbonlife`、应用名 `CarbonLife`，无团队标识 |

复现命令：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\deidentify-check.ps1
```

## 阻塞项（尚无法完整核验）

最终提交物**尚未产出**，去标识化需在产出后重跑：

- [ ] 参赛设计方案 Word 文档（#13）
- [ ] 答辩 PPT 演示文稿（#15）
- [ ] 演示视频 mp4（#14）——画面/字幕/水印/片头片尾

## 提交前检查清单

- [ ] 运行 `scripts\deidentify-check.ps1`，结果为 `PASS`（或命中均为可忽略的模板占位词）
- [ ] 最终 `.docx` / `.pptx` 文档属性：**作者、公司、最后修改者** 已清空
      （Office：文件 → 信息 → 检查文档 → 检查并删除文档属性和个人信息）
- [ ] Word / PPT 封面：无团队名、成员名单、指导老师、院校
- [ ] 视频：无校园地标 / 门牌 / 校徽；片头片尾无团队名
- [ ] 应用界面截图：无团队标识（应用名 / bundleName / 水印）
- [ ] 由**非本人**复核确认（issue 验收要求）

## 额外提醒

- 若提交**源代码仓库 / 压缩包**，请移除 `.git` 目录——git 提交历史会暴露提交者姓名与邮箱
  （当前仓库历史作者为 `zyx-dc <3974841138@qq.com>`），属于可识别信息。
- 视频录制时避免出现校园地标、门牌号、桌面文件名 / 路径、聊天窗口中的真实姓名。
