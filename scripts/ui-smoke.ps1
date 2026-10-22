# UI 冒烟测试（设备端，稳健版）
#
# 用 `devecocli ui` 驱动真机/模拟器：
#   1) 断言底部导航 5 个 Tab 均存在（应用外壳渲染正常）
#   2) 逐个点击 Tab，断言切换后界面仍渲染（布局非空）且导航栏仍在
# 任一断言失败即退出码 1，可接进 CI。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File scripts\ui-smoke.ps1 -Device "Mate 90 Pro"
#
# 说明：与 hypium 的 ohosTest 不同，本脚本走 CLI（hdc/uitest 封装），
# 不依赖 DevEco 测试运行器，契合本仓库的命令行工作流。

param(
  [string]$Device = "",
  [string]$Cli = "devecocli.cmd"
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$NAV = @("首页", "记录", "看板", "积分", "科普")

function Invoke-Cli {
  param([string[]]$CliArgs)
  $all = @()
  $all += $CliArgs
  if ($Device -ne "") { $all += @("--device", $Device) }
  return (& $Cli @all 2>$null)
}

function Get-Layout {
  return ((Invoke-Cli @("ui", "layout", "--format", "json", "--mode", "simplified")) -join "`n")
}

function Find-Center {
  param([string]$Raw, [string]$Text)
  $i = $Raw.IndexOf($Text)
  if ($i -lt 0) { return $null }
  $seg = $Raw.Substring($i, [Math]::Min(220, $Raw.Length - $i))
  $j = $seg.IndexOf('"bounds"')
  if ($j -lt 0) { return $null }
  $nums = [regex]::Matches($seg.Substring($j), '-?\d+') | ForEach-Object { [int]$_.Value }
  if ($nums.Count -lt 4) { return $null }
  return @{ x = [int](($nums[0] + $nums[2]) / 2); y = [int](($nums[1] + $nums[3]) / 2) }
}

$script:pass = 0
$script:fail = 0
function Assert-Result {
  param([string]$Name, [bool]$Ok)
  if ($Ok) { Write-Host ("  [PASS] " + $Name); $script:pass++ }
  else { Write-Host ("  [FAIL] " + $Name); $script:fail++ }
}

$target = if ($Device -eq "") { "(default device)" } else { $Device }
Write-Host ("UI smoke - device: " + $target)

# 0) 确保 App 在前台：布局里找不到底部导航就先拉起一次（--skip-build 复用已安装产物）
$raw = Get-Layout
if (-not ($raw.Contains("首页") -and $raw.Contains("科普"))) {
  Write-Host "  app not in foreground; launching..."
  Invoke-Cli @("run", "--ability", "EntryAbility", "--skip-build") | Out-Null
  Start-Sleep -Seconds 8
  $raw = Get-Layout
}

# 1) 应用外壳：底部导航 5 个 Tab 均存在
foreach ($t in $NAV) {
  Assert-Result ("nav '" + $t + "' present") ($raw.Contains($t))
}

# 2) 逐个 Tab：点击后布局仍渲染，且导航栏仍在
foreach ($t in $NAV) {
  $c = Find-Center -Raw $raw -Text $t
  Assert-Result ("tab '" + $t + "' is tappable") ($c -ne $null)
  if ($c -eq $null) { continue }
  Invoke-Cli @("ui", "click", $c.x.ToString(), $c.y.ToString()) | Out-Null
  Start-Sleep -Milliseconds 1200
  $raw = Get-Layout
  Assert-Result ("'" + $t + "' renders (layout non-empty)") ($raw.Length -gt 1500)
  Assert-Result ("'" + $t + "' keeps bottom nav") ($raw.Contains("首页") -and $raw.Contains("科普"))
}

Write-Host ""
Write-Host ("RESULT: {0} passed, {1} failed" -f $script:pass, $script:fail)
if ($script:fail -gt 0) { exit 1 } else { exit 0 }
