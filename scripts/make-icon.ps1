#requires -Version 5.1
<#
  make-icon.ps1 - generate CarbonLife app icon / start icon (issue #7)

  Brand colors (from DESIGN.md / Theme tokens):
    signal  #B6FF2E (lime, dark theme primary)
    leaf-on-light #3E8E1E (readable brand green)
    deep green background gradient #0E3A28 -> #082018
    splash background #F1F8E9

  Outputs (overwrites placeholders):
    AppScope/resources/base/media/app_icon.png                 1024 filled (launcher)
    entry/src/main/resources/base/media/app_icon.png           288  filled
    entry/src/main/resources/base/media/startIcon.png          288  transparent (splash)

  No text, no logos, nothing identifying. Pure ASCII.
#>
param(
  [int]$AppScopeSize = 1024,
  [int]$EntrySize = 288,
  [int]$StartSize = 288
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function New-LeafPath {
  param([single]$S)
  $top = New-Object System.Drawing.PointF ($S / 2), ($S * 0.20)
  $bottom = New-Object System.Drawing.PointF ($S / 2), ($S * 0.80)
  $w = $S * 0.22
  $h = $bottom.Y - $top.Y
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $r1 = New-Object System.Drawing.PointF ($top.X + $w), ($top.Y + $h * 0.28)
  $r2 = New-Object System.Drawing.PointF ($top.X + $w), ($top.Y + $h * 0.72)
  $l1 = New-Object System.Drawing.PointF ($top.X - $w), ($top.Y + $h * 0.72)
  $l2 = New-Object System.Drawing.PointF ($top.X - $w), ($top.Y + $h * 0.28)
  $path.AddBezier($top, $r1, $r2, $bottom)
  $path.AddBezier($bottom, $l1, $l2, $top)
  $path.CloseFigure()
  return $path
}

function New-Icon {
  param([int]$S, [string]$Out, [bool]$Filled)

  $bmp = New-Object System.Drawing.Bitmap $S, $S
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  if ($Filled) {
    $rect = New-Object System.Drawing.Rectangle 0, 0, $S, $S
    $c1 = [System.Drawing.ColorTranslator]::FromHtml("#0E3A28")
    $c2 = [System.Drawing.ColorTranslator]::FromHtml("#082018")
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 90
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
    $leafColor = [System.Drawing.ColorTranslator]::FromHtml("#B6FF2E")
    $veinColor = [System.Drawing.ColorTranslator]::FromHtml("#0E3A28")
  } else {
    $leafColor = [System.Drawing.ColorTranslator]::FromHtml("#3E8E1E")
    $veinColor = [System.Drawing.ColorTranslator]::FromHtml("#F1F8E9")
  }

  $leaf = New-LeafPath -S $S
  $leafBrush = New-Object System.Drawing.SolidBrush $leafColor
  $g.FillPath($leafBrush, $leaf)

  # central vein
  $veinPen = New-Object System.Drawing.Pen $veinColor, ($S * 0.018)
  $veinPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $veinPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $va = New-Object System.Drawing.PointF ($S / 2), ($S * 0.27)
  $vb = New-Object System.Drawing.PointF ($S / 2), ($S * 0.73)
  $g.DrawLine($veinPen, $va, $vb)

  $g.Dispose()
  $leafBrush.Dispose()
  $veinPen.Dispose()
  $leaf.Dispose()

  $dir = Split-Path $Out -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host ("wrote {0} ({1}x{1})" -f $Out, $S)
}

New-Icon -S $AppScopeSize -Out (Join-Path $root "AppScope\resources\base\media\app_icon.png") -Filled $true
New-Icon -S $EntrySize    -Out (Join-Path $root "entry\src\main\resources\base\media\app_icon.png") -Filled $true
New-Icon -S $StartSize    -Out (Join-Path $root "entry\src\main\resources\base\media\startIcon.png") -Filled $false

Write-Host "done."
