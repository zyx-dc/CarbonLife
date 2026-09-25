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
const qaDir = path.join(root, "docs", "qa")
const outPath = path.join(root, "docs", "tasks", "design-doc", "CarbonLife-设计文档.docx")

const mime = {
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".png": "image/png",
}

let html = fs.readFileSync(htmlPath, "utf8")

// Inline `qa:NAME` image sources as base64 data URIs (portable, no external refs).
html = html.replace(/src="qa:([^"]+)"/g, (m, name) => {
  const file = path.join(qaDir, name)
  if (!fs.existsSync(file)) {
    console.warn("  missing image:", name)
    return 'src=""'
  }
  const b64 = fs.readFileSync(file).toString("base64")
  const ext = path.extname(name).toLowerCase()
  return `src="data:${mime[ext] || "image/jpeg"};base64,${b64}"`
})

const options = {
  footer: true,
  pageNumber: true,
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
