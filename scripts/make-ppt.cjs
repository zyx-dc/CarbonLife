/*
 * make-ppt.cjs - generate CarbonLife defense deck (docs/tasks/ppt)
 * Requires: npm i pptxgenjs    Usage: node scripts/make-ppt.cjs
 */
const path = require("path")
const fs = require("fs")
const PptxGenJS = require("pptxgenjs")

const root = path.resolve(__dirname, "..")
const qa = (n) => path.join(root, "docs", "qa", n)
const outDir = path.join(root, "docs", "tasks", "ppt")
const out = path.join(outDir, "CarbonLife-答辩PPT.pptx")
fs.mkdirSync(outDir, { recursive: true })

const C = {
  deep: "0F3D2E",
  amber: "FFB300",
  lime: "B6FF2E",
  bg: "F5F7F5",
  text: "1C1C1E",
  sub: "5B6B60",
  white: "FFFFFF",
}
const FONT = "Microsoft YaHei"

const pptx = new PptxGenJS()
pptx.defineLayout({ name: "W16x9", width: 13.333, height: 7.5 })
pptx.layout = "W16x9"
pptx.author = "CarbonLife"
pptx.company = ""
pptx.title = "CarbonLife 碳足迹 · 答辩演示"

const W = 13.333
const H = 7.5

function bg(slide, color = C.bg) {
  slide.background = { color }
}

function header(slide, title) {
  slide.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: 1.0, fill: { color: C.deep } })
  slide.addShape(pptx.ShapeType.rect, { x: 0, y: 1.0, w: W, h: 0.06, fill: { color: C.amber } })
  slide.addText(title, { x: 0.5, y: 0.14, w: W - 1, h: 0.72, fontFace: FONT, fontSize: 26, bold: true, color: C.white, valign: "middle" })
}

function bullets(slide, items, opts = {}) {
  const runs = items.map((t) => ({ text: t, options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 10 } }))
  slide.addText(runs, Object.assign({ x: 0.7, y: 1.5, w: 7.0, h: 5.2, fontFace: FONT, fontSize: 18, color: C.text, valign: "top" }, opts))
}

function pic(slide, file, x, y, w, h) {
  try { slide.addImage({ path: qa(file), x, y, w, h, rounding: true, shadow: { type: "outer", blur: 8, offset: 2, angle: 45, color: "000000", opacity: 0.2 } }) }
  catch (e) { console.warn("img fail", file, e.message) }
}

// 1 cover
{
  const s = pptx.addSlide()
  bg(s, C.deep)
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 2.0, w: 0.18, h: 2.2, fill: { color: C.lime } })
  s.addText("CarbonLife 碳足迹", { x: 0.7, y: 2.0, w: 8, h: 1.0, fontFace: FONT, fontSize: 44, bold: true, color: C.white })
  s.addText("基于 HarmonyOS 的低碳生活记录与激励应用", { x: 0.75, y: 3.0, w: 8.5, h: 0.6, fontFace: FONT, fontSize: 20, color: C.lime })
  s.addText("记录每一次低碳行动，积少成多守护地球", { x: 0.75, y: 3.7, w: 8.5, h: 0.5, fontFace: FONT, fontSize: 15, color: "CFE6D8" })
  s.addText("按大赛要求已去标识化：不体现团队 / 成员 / 指导老师 / 院校信息", { x: 0.75, y: 6.5, w: 9, h: 0.4, fontFace: FONT, fontSize: 11, color: "8FB3A2" })
  pic(s, "screen3.jpeg", 9.3, 1.6, 3.4, 4.3)
}

// 2 pain & why
{
  const s = pptx.addSlide(); bg(s); header(s, "痛点与选题")
  bullets(s, [
    "国家「双碳」目标：碳达峰 · 碳中和，倡导全民绿色生活",
    "日常低碳行为「难记录、没反馈、难坚持」",
    "隐私顾虑：不愿把出行 / 生活数据上传第三方",
    "契机：HarmonyOS 端侧 AI、分布式数据、后台提醒等原生能力",
  ])
}

// 3 what we built
{
  const s = pptx.addSlide(); bg(s); header(s, "我们做了什么")
  s.addText([
    { text: "记录低碳行为", options: { bold: true, color: C.deep } },
    { text: "  →  ", options: { color: C.sub } },
    { text: "自动计算减排量与碳积分", options: { bold: true, color: C.deep } },
    { text: "  →  ", options: { color: C.sub } },
    { text: "激励与家庭共享", options: { bold: true, color: C.deep } },
  ], { x: 0.7, y: 1.7, w: 11.9, h: 1.0, fontFace: FONT, fontSize: 22, valign: "middle" })
  s.addText("一句话：把日常小行动，变成看得见的绿色成就。", { x: 0.7, y: 3.0, w: 11.9, h: 0.7, fontFace: FONT, fontSize: 20, color: C.amber, bold: true })
  pic(s, "app_home_new.jpeg", 4.6, 3.9, 4.1, 3.2)
}

// 4 target users
{
  const s = pptx.addSlide(); bg(s); header(s, "目标用户")
  bullets(s, [
    "关注环保与健康的家庭用户",
    "学生 / 上班族等通勤人群",
    "希望与家人共同参与低碳生活的群体",
  ])
}

// 5 feature overview
{
  const s = pptx.addSlide(); bg(s); header(s, "功能总览")
  const feats = ["低碳行为记录", "端侧 AI 识图", "数据看板与导出", "积分与荣誉", "家庭碳积分", "每日提醒", "双碳科普", "浅/深双主题"]
  const cols = 4, cw = 2.85, ch = 1.7, gx = 0.25, gy = 0.3
  const x0 = (W - (cols * cw + (cols - 1) * gx)) / 2
  feats.forEach((f, i) => {
    const r = Math.floor(i / cols), c = i % cols
    const x = x0 + c * (cw + gx), y = 1.7 + r * (ch + gy)
    s.addShape(pptx.ShapeType.roundRect, { x, y, w: cw, h: ch, rectRadius: 0.1, fill: { color: C.white }, line: { color: "D8E4DA", width: 1 } })
    s.addText(f, { x: x + 0.1, y: y + 0.1, w: cw - 0.2, h: ch - 0.2, fontFace: FONT, fontSize: 16, bold: true, color: C.deep, align: "center", valign: "middle" })
  })
}

// 6 highlight 1
{
  const s = pptx.addSlide(); bg(s); header(s, "亮点 1 · 13 种低碳行为")
  bullets(s, ["出行 / 节能 / 回收 / 餐饮 4 大类，共 13 种行为", "「活动量 × 排放因子」自动估算减排量与积分", "支持数量步进与备注，保存即写本机"], { w: 6.6 })
  pic(s, "app_record_new2.jpeg", 7.6, 1.5, 5.2, 4.6)
}

// 7 highlight 2
{
  const s = pptx.addSlide(); bg(s); header(s, "亮点 2 · 端侧 AI 识图")
  bullets(s, ["选一张照片，端侧识别物体", "自动推荐对应低碳行为并定位", "识别在本机完成，图片不出本机"], { w: 6.6 })
  pic(s, "app_food.jpeg", 7.6, 1.5, 5.2, 4.6)
}

// 8 highlight 3
{
  const s = pptx.addSlide(); bg(s); header(s, "亮点 3 · 数据看板")
  bullets(s, ["日 / 周 / 月 / 年 趋势聚合", "折线 · 柱状 · 类别饼图", "最近记录与 CSV / JSON 导出"], { w: 6.2 })
  pic(s, "qa_dash_week.jpeg", 6.9, 1.5, 3.0, 4.6)
  pic(s, "qa_dash_month.jpeg", 10.1, 1.5, 3.0, 4.6)
}

// 9 highlight 4
{
  const s = pptx.addSlide(); bg(s); header(s, "亮点 4 · 家庭碳积分")
  bullets(s, ["生成 / 加入家庭码", "同一华为账号多设备同步", "按成员展示，合并家庭减排与积分"], { w: 6.6 })
  pic(s, "app_home_new.jpeg", 7.6, 1.5, 5.2, 4.6)
}

// 10 highlight 5
{
  const s = pptx.addSlide(); bg(s); header(s, "亮点 5 · 积分与荣誉")
  bullets(s, ["碳积分累计与权益商城（模拟兑换码）", "低碳徽章 · 植树证书", "今日任务完成后自动发放积分"], { w: 6.2 })
  pic(s, "app_rewards_v4.jpeg", 6.9, 1.5, 3.0, 4.6)
  pic(s, "qa_redeem.jpeg", 10.1, 1.5, 3.0, 4.6)
}

// 11 design
{
  const s = pptx.addSlide(); bg(s); header(s, "设计与体验")
  bullets(s, ["配色：深林绿 + 暖白 + 琥珀金", "浅色 / 深色双主题，跟随系统切换", "颜色 / 字号 / 间距 / 圆角统一走设计 token"], { w: 6.2 })
  pic(s, "app_home_new.jpeg", 6.9, 1.5, 3.0, 4.6)
  pic(s, "qa_dark_home.jpeg", 10.1, 1.5, 3.0, 4.6)
}

// 12 tech
{
  const s = pptx.addSlide(); bg(s); header(s, "技术底座")
  bullets(s, [
    "HarmonyOS / OpenHarmony 原生：ArkTS + ArkUI 声明式 UI（Stage 模型，SDK 26.0.0）",
    "本机存储：Preferences；家庭：分布式数据对象",
    "端侧 AI：CoreVisionKit 物体检测；提醒：后台代理提醒",
  ])
}

// 13 privacy
{
  const s = pptx.addSlide(); bg(s); header(s, "隐私与安全")
  bullets(s, [
    "所有记录只存在本机，不上传云端",
    "家庭数据只在同一账号设备间同步，不经过第三方服务器",
    "AI 识图在本机完成，不上传图片",
  ])
  pic(s, "qa_perm.jpeg", 8.0, 1.6, 4.4, 3.9)
}

// 14 verification
{
  const s = pptx.addSlide(); bg(s); header(s, "验证与质量")
  bullets(s, [
    "内置「AI 设备验证 Agent + 验收清单」的只读验证流程",
    "模拟器逐条验收：深色模式 / 清空数据 / CSV 导出 / 记录增删刷新 / 图表刷新",
    "构建持续通过（assembleHap）；界面文案完成中英国际化",
  ])
}

// 15 outlook & thanks
{
  const s = pptx.addSlide(); bg(s, C.deep)
  s.addText("展望与致谢", { x: 0.7, y: 1.2, w: 11.9, h: 0.9, fontFace: FONT, fontSize: 30, bold: true, color: C.white })
  s.addText([
    { text: "对接真实城市碳普惠平台 API", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8 } },
    { text: "数据导入与云备份能力", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8 } },
    { text: "接入系统无障碍设置、平板多列布局", options: { bullet: { code: "2022" }, breakLine: true, paraSpaceAfter: 8 } },
  ], { x: 0.9, y: 2.4, w: 11.5, h: 3.0, fontFace: FONT, fontSize: 18, color: "EAF7DC" })
  s.addText("谢谢观看", { x: 0.9, y: 5.6, w: 11.5, h: 0.9, fontFace: FONT, fontSize: 26, bold: true, color: C.lime })
}

pptx.writeFile({ fileName: out }).then((f) => console.log("wrote", f)).catch((e) => { console.error(e); process.exit(1) })
