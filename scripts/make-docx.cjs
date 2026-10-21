/*
 * make-docx.cjs - render docs/tasks/design-doc/design-doc.html to .docx
 *
 * Requires: npm i html-to-docx   (resolved via local node_modules or NODE_PATH)
 * Usage:    node scripts/make-docx.cjs
 */
const fs = require("fs")
const path = require("path")
const HTMLtoDOCX = require("html-to-docx")

const root = path.resolve(__dirname, "..")
const htmlPath = path.join(root, "docs", "tasks", "design-doc", "design-doc.html")
const outPath = path.join(root, "docs", "tasks", "design-doc", "CarbonLife-设计文档.docx")

// Two image sources are supported in the HTML:
//   shot:NAME  -> docs/shots/NAME        (current UI, tracked in git, reproducible build)
//   qa:NAME    -> docs/qa/NAME           (2026-09 historical QA evidence, NOT tracked)
// Prefer `shot:` - docs/qa is an untracked archive and its screenshots are from the
// 2026-09 UI, which the task notes say should no longer be used for the submission.
const imageRoots = {
  shot: path.join(root, "docs", "shots"),
  qa: path.join(root, "docs", "qa"),
}

const mime = {
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".png": "image/png",
}

let html = fs.readFileSync(htmlPath, "utf8")
let missing = 0

// Inline `<prefix>:NAME` image sources as base64 data URIs (portable, no external refs).
html = html.replace(/src="(shot|qa):([^"]+)"/g, (m, prefix, name) => {
  const file = path.join(imageRoots[prefix], name)
  if (!fs.existsSync(file)) {
    console.warn("  missing image:", prefix + ":" + name)
    missing++
    return 'src=""'
  }
  const b64 = fs.readFileSync(file).toString("base64")
  const ext = path.extname(name).toLowerCase()
  return `src="data:${mime[ext] || "image/jpeg"};base64,${b64}"`
})

if (missing > 0) {
  // A silent empty src would ship a document with blank figures - fail loudly instead.
  console.error(`docx render aborted: ${missing} image(s) not found`)
  process.exit(1)
}

const options = {
  footer: true,
  pageNumber: true,
  // A4 (twip): html-to-docx defaults to Letter + Times New Roman and ignores the
  // CSS font-family, which is why the PDF came out 21.59x27.94 cm with 等线/Times.
  pageSize: { width: 11906, height: 16838 },
  margins: { top: 1417, bottom: 1417, left: 1417, right: 1417 }, // 2.5 cm
  font: "Microsoft YaHei",
  fontSize: 22,                                                // 11 pt (half-points)
  table: { row: { cantSplit: true } },
}

HTMLtoDOCX(html, null, options)
  .then((buffer) => {
    fs.mkdirSync(path.dirname(outPath), { recursive: true })
    fs.writeFileSync(outPath, buffer)
    console.log("wrote", outPath, "(" + buffer.length + " bytes)")
  })
  .catch((err) => {
    console.error("docx render failed:", err)
    process.exit(1)
  })
