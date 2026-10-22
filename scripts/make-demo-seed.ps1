# 生成"碳小树演示种子数据"（相对今天：昨天起往前 N 天，每天 M 条步行）
#
# 为什么需要它：树冠装饰（新叶/果实/花朵/青环）在阶段 >= 2（即累计成长值 >= 180）才显示，
# 而单日成长上限是 80 —— 干净设备当天怎么记录都看不到装饰。演示/验收时先导入本脚本生成的
# 种子数据，即可稳定复现「小树 + 偏向 + 新叶」。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File scripts\make-demo-seed.ps1 -Push
#   然后在 App：看板 → 本地数据管理 → 导入数据（CSV / JSON）→ 我的手机 → demo-seed.json
#
# 说明：导入是"按 id 去重合并"，建议先「看板 → 清空全部数据」再导入，避免和当天记录混在一起。

param(
    [int]$Days = 5,
    [int]$PerDay = 4,
    [string]$Out = "",
    [switch]$Push,
    [string]$Hdc = ""
)

$ErrorActionPreference = "Stop"

$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$stamp = (Get-Date).ToString("yyyyMMdd-HHmm")
if ([string]::IsNullOrEmpty($Out)) {
    # .hvigor 已在 .gitignore 中，生成物不会污染工作区
    $Out = Join-Path $project (".hvigor\demo-seed-" + $stamp + ".json")
}
$seedName = Split-Path -Leaf $Out
$outDir = Split-Path -Parent $Out
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$records = New-Object System.Collections.ArrayList
$today = (Get-Date).Date
for ($back = $Days; $back -ge 1; $back--) {
    $day = $today.AddDays(-$back).AddHours(12)
    for ($i = 0; $i -lt $PerDay; $i++) {
        $ts = [long]([DateTimeOffset]$day.AddMinutes($i)).ToUnixTimeMilliseconds()
        $rec = [ordered]@{
            id          = ("demo-{0}-{1}" -f $day.ToString("yyyyMMdd"), $i)
            behaviorKey = "walk"
            category    = "出行"
            name        = "步行替代驾车"
            amount      = 1
            unit        = "km"
            factor      = 0.17
            saved       = 0.17
            points      = 17
            timestamp   = $ts
            dateKey     = ""
            note        = ""
        }
        [void]$records.Add($rec)
    }
}
$json = ConvertTo-Json -InputObject @($records) -Depth 4
# 必须无 BOM：JSON 导入走 JSON.parse，带 BOM 会解析失败
[System.IO.File]::WriteAllText($Out, $json, (New-Object System.Text.UTF8Encoding($false)))

$rawPerDay = $PerDay * 10
$growth = 0
for ($s = 1; $s -le $Days; $s++) {
    $bonus = [Math]::Min(0.5, ($s - 1) * 0.05)
    $growth += [Math]::Min(80, [Math]::Round($rawPerDay * (1 + $bonus)))
}

Write-Host "Demo seed written: $Out"
Write-Host ("  records: {0} ({1}/day x {2} days, all 出行/步行)" -f $records.Count, $PerDay, $Days)
Write-Host ("  expected: growth {0}, stage {1}, streak {2}, variant 偏向绿色出行" -f `
        $growth, $(if ($growth -ge 180) { "小树(2)+" } else { "<小树(2)" }), $Days)

if ($Push) {
    $candidates = New-Object System.Collections.ArrayList
    if (-not [string]::IsNullOrEmpty($env:DEVECO_SDK_HOME)) {
        [void]$candidates.Add((Join-Path $env:DEVECO_SDK_HOME "default\openharmony\toolchains\hdc.exe"))
    }
    [void]$candidates.Add("D:\DEStudio\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe")
    [void]$candidates.Add("C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe")
    if (-not [string]::IsNullOrEmpty($Hdc)) { $candidates = @($Hdc) }
    $hdcExe = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if (-not $hdcExe) {
        Write-Warning "hdc not found; pass -Hdc <path>. Seed file is still available locally."
    } else {
        & $hdcExe file send $Out ("/storage/media/100/local/files/Docs/" + $seedName) | Out-Null
        Write-Host ("Pushed to device: 我的手机/" + $seedName + "（若选择器里看不到，返回上一级再进入即可刷新）")
    }
}

Write-Host ""
Write-Host ("下一步：看板 → 本地数据管理 → 导入数据（CSV / JSON）→ 我的手机 → " + $seedName)
