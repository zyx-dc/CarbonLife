#requires -Version 5.1
<#
  deidentify-check.ps1 - competition-material de-identification check (issue #17)

  Scans text files and Office (.docx/.pptx) metadata under the given paths and reports
  any residual identifying info: school / college / teacher / team / lab names,
  or document author/company metadata.

  Usage:
    powershell -ExecutionPolicy Bypass -File scripts\deidentify-check.ps1
    powershell -ExecutionPolicy Bypass -File scripts\deidentify-check.ps1 -Path docs\tasks\dist

  Exit code: 0 = no hits; 1 = review needed (human confirmation required).
  Report-only; modifies nothing. Keyword regexes use \u escapes to keep this
  file pure ASCII and safe to parse under Windows PowerShell 5.1.
#>
param(
  [string[]]$Path,
  [string]$Root
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
  $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
if (-not $Path -or $Path.Count -eq 0) {
  $Path = @("docs\tasks", "submission")
}

# Keywords (\u escaped, ASCII-safe):
#   school:  xue xiao / xue yuan / da xue
#   teacher: zhi dao lao shi / zhi dao jiao shi / lao shi
#   team:    tuan dui ming / dui wu / dui yuan / zhan dui
#   lab:     shi yan shi / ke ti zu / xiao hui / yuan xi
$patterns = [ordered]@{
  "school"  = "\u5b66\u6821|\u5b66\u9662|\u5927\u5b66"
  "teacher" = "\u6307\u5bfc\u8001\u5e08|\u6307\u5bfc\u6559\u5e08|\u8001\u5e08"
  "team"    = "\u56e2\u961f\u540d|\u961f\u4f0d|\u961f\u5458|\u6218\u961f"
  "lab"     = "\u5b9e\u9a8c\u5ba4|\u8bfe\u9898\u7ec4|\u6821\u5fbd|\u9662\u7cfb"
}

$textExt = @(".md", ".markdown", ".html", ".htm", ".txt", ".json", ".json5", ".ets", ".ts", ".js", ".xml", ".csv", ".yml", ".yaml")
$findings = New-Object System.Collections.Generic.List[string]

function Scan-TextFile {
  param([string]$File)
  $text = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
  $lines = $text -split "`r?`n"
  foreach ($k in $patterns.Keys) {
    $rx = [regex]$patterns[$k]
    for ($i = 0; $i -lt $lines.Length; $i++) {
      if ($rx.IsMatch($lines[$i])) {
        $findings.Add(("TEXT  [{0}] {1}:{2}  {3}" -f $k, $File, ($i + 1), $lines[$i].Trim()))
      }
    }
  }
}

function Scan-DocxMeta {
  param([string]$File)
  Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("deid_" + [System.IO.Path]::GetRandomFileName())
  try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($File, $tmp)
    foreach ($rel in @("docProps\core.xml", "docProps\app.xml")) {
      $p = Join-Path $tmp $rel
      if (-not (Test-Path $p)) { continue }
      $meta = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
      $creator = ([regex]::Match($meta, "<dc:creator>(.*?)</dc:creator>")).Groups[1].Value
      $lastmod = ([regex]::Match($meta, "<cp:lastModifiedBy>(.*?)</cp:lastModifiedBy>")).Groups[1].Value
      $company = ([regex]::Match($meta, "<Company>(.*?)</Company>")).Groups[1].Value
      $title   = ([regex]::Match($meta, "<dc:title>(.*?)</dc:title>")).Groups[1].Value
      # Allowed: generator tool, app name (not personal/team info), empty
      $allow = @("html-to-docx", "CarbonLife", "")
      if ($allow -notcontains $creator) { $findings.Add(("META  creator='{0}'  {1}" -f $creator, $File)) }
      if ($allow -notcontains $lastmod) { $findings.Add(("META  lastModifiedBy='{0}'  {1}" -f $lastmod, $File)) }
      if ($company -ne "") { $findings.Add(("META  Company='{0}'  {1}" -f $company, $File)) }
      # Title: allow empty, or titles starting with the project name
      if ($title -ne "" -and $title -notmatch "^CarbonLife") { $findings.Add(("META  title='{0}'  {1}" -f $title, $File)) }
    }
  } finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }
}

Write-Host "deidentify-check  root: $Root"
foreach ($rel in $Path) {
  $dir = Join-Path $Root $rel
  if (-not (Test-Path $dir)) {
    Write-Host ("  skip (missing): {0}" -f $rel)
    continue
  }
  Write-Host ("  scan: {0}" -f $rel)
  $files = Get-ChildItem -LiteralPath $dir -Recurse -File -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    $ext = $f.Extension.ToLower()
    if ($textExt -contains $ext) { Scan-TextFile -File $f.FullName }
    elseif ($ext -eq ".docx" -or $ext -eq ".pptx") { Scan-DocxMeta -File $f.FullName }
  }
}

Write-Host ""
if ($findings.Count -eq 0) {
  Write-Host "RESULT: PASS - no identifying-info hits."
  exit 0
} else {
  Write-Host ("RESULT: REVIEW - {0} hit(s); human confirmation required (template placeholders may be ignored):" -f $findings.Count)
  $findings | ForEach-Object { Write-Host ("  " + $_) }
  exit 1
}
