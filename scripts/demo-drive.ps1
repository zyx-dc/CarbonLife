# demo-drive.ps1 - drive the CarbonLife app through scripted taps for screen recording
#
# Coordinates are measured on EMA-AL00U (1280x2800). Re-measure if the UI changes:
#   hdc shell uitest dumpLayout -p /data/local/tmp/l.json
#   hdc file recv /data/local/tmp/l.json l.json
#
# The script only injects taps/swipes. It does NOT record - start the device's
# screen recorder (or OBS) first, then run this.
#
# Usage:
#   .\scripts\demo-drive.ps1 -Scene record
#   .\scripts\demo-drive.ps1 -Scene record -DryRun     # print steps, no taps
#   .\scripts\demo-drive.ps1 -List

param(
    [string]$Scene = 'record',
    [string]$Device = '',
    [switch]$DryRun,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

$HdcCandidates = @(
    'D:\DEStudio\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',
    'C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
)

function Get-Hdc {
    foreach ($p in $HdcCandidates) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command hdc -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'hdc not found. Install DevEco Studio or add hdc to PATH.'
}

$Hdc = Get-Hdc

function Get-Device {
    if ($Device) { return $Device }
    $targets = & $Hdc list targets 2>$null | Where-Object { $_ -match '^\S+$' } | Where-Object { $_ -ne '[Empty]' }
    if (-not $targets) { throw 'No device connected. Check USB debugging.' }
    return @($targets)[0]
}

function Invoke-Sh([string[]]$argv) {
    if ($DryRun) {
        Write-Host ("    [dry] hdc shell " + ($argv -join ' '))
        return
    }
    & $Hdc -t $script:Dev shell ($argv -join ' ') | Out-Null
}

function Tap($x, $y) {
    Write-Host "  tap $x,$y"
    Invoke-Sh @('uitest', 'uiInput', 'click', "$x", "$y")
    Start-Sleep -Milliseconds 900
}

function Swipe($x1, $y1, $x2, $y2, $ms) {
    Write-Host "  swipe $x1,$y1 -> $x2,$y2"
    Invoke-Sh @('uitest', 'uiInput', 'swipe', "$x1", "$y1", "$x2", "$y2", "$ms")
    Start-Sleep -Milliseconds 800
}

function Pause-Ms($ms, $why) {
    if ($why) { Write-Host "  wait $ms ms ($why)" }
    Start-Sleep -Milliseconds $ms
}

# ---- bottom tab bar (1280x2800) ----
$TabHome      = @(128, 2733)
$TabRecord    = @(384, 2733)
$TabDashboard = @(640, 2733)
$TabRewards   = @(896, 2733)
$TabKnow      = @(1152, 2733)

function Reset-Home {
    Write-Host '  reset -> home top'
    Tap $TabHome[0] $TabHome[1]
    Swipe 640 800 640 2200 200
    Swipe 640 800 640 2200 200
    Swipe 640 800 640 2200 200
    Pause-Ms 600 'settle'
}

function Start-App {
    Write-Host '  launch app'
    Invoke-Sh @('aa', 'force-stop', 'com.example.carbonlife')
    Start-Sleep -Milliseconds 600
    Invoke-Sh @('aa', 'start', '-b', 'com.example.carbonlife', '-a', 'EntryAbility')
    Pause-Ms 6000 'cold start + splash'
}

# ---------------- scenes ----------------

function Scene-HomeFull {
    Start-App
    Pause-Ms 1500 'hold on first frame'
    Swipe 640 900 640 1900 1200      # today / sapling
    Pause-Ms 1200 'hold'
    Swipe 640 900 640 1900 1200      # tasks
    Pause-Ms 1000 'hold'
    Swipe 640 900 640 1900 1200      # family card
    Pause-Ms 1000 'hold'
    Swipe 640 1200 640 1900 900      # bottom: reminder / tips
    Pause-Ms 2500 'hold at bottom'
}

function Scene-HomeTop {
    Start-App
    Pause-Ms 1500 'hold on first frame'
    Swipe 640 900 640 1900 1200
    Pause-Ms 1800 'hold'
    Swipe 640 900 640 1900 1200
    Pause-Ms 2500 'hold on family card'
}

function Scene-Record {
    Start-App
    Tap 341 1666                     # 去记录低碳行为
    Pause-Ms 1500 'record page in'
    Tap 385 1750                     # 行为：骑行替代驾车
    Pause-Ms 1200 'selection highlight'
    # 数量控件在首屏被底部固定条挡住，必须先上滑把它露出来
    Swipe 640 2000 640 1200 800
    Pause-Ms 1000 'quantity row revealed'
    Tap 1088 1700                    # 数量 +
    Tap 1088 1700
    Pause-Ms 1500 'quantity = 3 km'
    Tap 640 2461                     # 保存记录（固定在底部）
    Pause-Ms 2500 'back to home, numbers tick'
}

function Scene-Vision {
    Start-App
    Tap 341 1666                     # 去记录
    Pause-Ms 1200
    Tap 640 751                      # 拍照/选图
    Pause-Ms 1500 'system picker opens - pick a photo by hand now'
    Write-Host '  >>> HANDOFF: choose a photo in the system picker, then wait for the AI card'
    Pause-Ms 12000 'waiting for manual pick + on-device inference'
}

function Scene-Dashboard {
    Start-App
    Tap $TabDashboard[0] $TabDashboard[1]
    Pause-Ms 1500 'dashboard in'
    Tap 499 506                      # 周
    Pause-Ms 1200
    Tap 782 506                      # 月
    Pause-Ms 1500 'chart redraw'
    Tap 1066 506                     # 年
    Pause-Ms 1000
    Swipe 640 1900 640 700 700       # trend + pie
    Pause-Ms 900
    Swipe 640 1900 640 700 700
    Pause-Ms 900
    Swipe 640 1900 640 700 700       # recent records at bottom
    Pause-Ms 2500 'hold at bottom'
}

function Scene-Rewards {
    Start-App
    Tap $TabRewards[0] $TabRewards[1]
    Pause-Ms 1600 'balance card'
    Tap 1004 1692                    # 兑换（首屏可见，先兑换再下滑）
    Pause-Ms 2200 'confirm / toast'
    Swipe 640 2000 640 700 700
    Pause-Ms 900
    Swipe 640 2000 640 700 700
    Pause-Ms 900
    Swipe 640 2000 640 700 700       # badge wall at bottom
    Pause-Ms 2500 'hold on badge wall'
}

function Scene-Know {
    Start-App
    Tap $TabKnow[0] $TabKnow[1]
    Pause-Ms 1600 'knowledge in'
    Swipe 640 2000 640 700 800       # article list
    Pause-Ms 900
    Swipe 640 2000 640 700 800
    Pause-Ms 900
    Swipe 640 2000 640 500 600       # bottom: tips card
    Pause-Ms 900
    Swipe 640 2000 640 500 600
    Pause-Ms 2500 'hold on tips card'
}

function Scene-Family {
    Start-App
    Swipe 640 2200 640 700 700
    Pause-Ms 600
    Swipe 640 2200 640 700 700
    Pause-Ms 2500 'hold on family card - let numbers settle'
    Write-Host '  >>> Hold 4s so the other device shows the same values before you move on.'
    Pause-Ms 4000 'sync window'
}

function Scene-FamilyExit {
    Start-App
    Swipe 640 2200 640 700 700
    Pause-Ms 600
    Swipe 640 2200 640 700 700
    Pause-Ms 1200
    Tap 640 876                      # 加入 / 管理家庭组
    Pause-Ms 1500 'family editor expanded'
    Write-Host '  >>> HANDOFF: tap 退出家庭组 and confirm by hand, then hold 5s on the member list'
    Pause-Ms 8000 'manual exit + observe member count'
}

function Scene-Bill {
    Start-App
    Tap 939 1666                     # 生成成果卡片
    Pause-Ms 2500 'bill overlay in'
    Write-Host '  >>> HANDOFF: tap 导出/分享 by hand to show the system picker, then hold'
    Pause-Ms 9000 'manual export'
}

$Scenes = @(
    'home-full', 'home-top', 'record', 'vision', 'dashboard',
    'rewards', 'know', 'family', 'family-exit', 'bill'
)

if ($List) {
    Write-Host 'Scenes:'
    $Scenes | ForEach-Object { Write-Host "  $_" }
    return
}

if ($Scenes -notcontains $Scene) {
    throw "Unknown scene '$Scene'. Use -List to see options."
}

$script:Dev = Get-Device
Write-Host "hdc    : $Hdc"
Write-Host "device : $($script:Dev)"
Write-Host "scene  : $Scene"
if ($DryRun) { Write-Host 'mode   : DRY RUN (no taps injected)' }
Write-Host ''

switch ($Scene) {
    'home-full'   { Scene-HomeFull }
    'home-top'    { Scene-HomeTop }
    'record'      { Scene-Record }
    'vision'      { Scene-Vision }
    'dashboard'   { Scene-Dashboard }
    'rewards'     { Scene-Rewards }
    'know'        { Scene-Know }
    'family'      { Scene-Family }
    'family-exit' { Scene-FamilyExit }
    'bill'        { Scene-Bill }
}

Write-Host ''
Write-Host 'Scene done. Stop the recorder before running the next scene.'
