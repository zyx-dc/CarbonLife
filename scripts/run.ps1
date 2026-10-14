# Build the HAP, wait for a device, install and launch CarbonLife.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\run.ps1            # build + install + launch
#   powershell -ExecutionPolicy Bypass -File scripts\run.ps1 -BuildOnly # build only
#
# Before the first run, open the project in DevEco Studio once and enable
# File > Project Structure > Signing Configs > "Automatically generate
# signature" (needs a signed-in Huawei account), then build once there.
# After that this script produces and deploys a *signed* HAP.

param(
    [string]$Bundle = "com.example.carbonlife",
    [string]$Ability = "EntryAbility",
    [string]$DevEco = "",
    [switch]$BuildOnly,
    [switch]$AllowUnsigned
)

$ErrorActionPreference = "Stop"

# Auto-detect DevEco Studio (path differs per machine); override with -DevEco <path>.
if ([string]::IsNullOrEmpty($DevEco)) {
    $candidates = @(
        "C:\Program Files\Huawei\DevEco Studio",
        (Join-Path $env:ProgramFiles "Huawei\DevEco Studio"),
        (Join-Path $env:LOCALAPPDATA "Huawei\DevEco Studio"),
        (Join-Path $env:LOCALAPPDATA "Programs\Huawei\DevEco Studio")
    ) | Where-Object { $_ -and (Test-Path (Join-Path $_ "tools\hvigor\bin\hvigorw.bat")) }
    if ($candidates.Count -gt 0) { $DevEco = @($candidates)[0] }
}
if ([string]::IsNullOrEmpty($DevEco) -or -not (Test-Path (Join-Path $DevEco "tools\hvigor\bin\hvigorw.bat"))) {
    throw "DevEco Studio not found. Install it, or pass -DevEco 'C:\path\to\DevEco Studio'."
}
Write-Host "==> Using DevEco: $DevEco"
$env:DEVECO_SDK_HOME = "$DevEco\sdk"
$env:OHOS_BASE_SDK_HOME = "$DevEco\sdk"
$env:JAVA_HOME = "$DevEco\jbr"
$env:PATH = "$DevEco\jbr\bin;$DevEco\tools\node;" + $env:PATH

$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$hdc = "$DevEco\sdk\default\openharmony\toolchains\hdc.exe"
$hvigor = "$DevEco\tools\hvigor\bin\hvigorw.bat"

Write-Host "==> Building HAP ..."
Push-Location $Project
try {
    & $hvigor assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
    if ($LASTEXITCODE -ne 0) { throw "hvigor build failed ($LASTEXITCODE)" }
}
finally {
    Pop-Location
}

$hapDir = Join-Path $Project "entry\build\default\outputs\default"
$signed = Get-ChildItem $hapDir -Filter "*-signed.hap" -ErrorAction SilentlyContinue |
    Select-Object -First 1
$hap = $signed
if (-not $hap) {
    if (-not $AllowUnsigned) {
        Write-Warning "No *-signed.hap found."
        Write-Warning "Open DevEco Studio once, enable 'Automatically generate signature'"
        Write-Warning "(File > Project Structure > Signing Configs), then build again."
        Write-Warning "Or re-run with -AllowUnsigned to install the unsigned HAP (works on emulator)."
        $unsigned = Get-ChildItem $hapDir -Filter "*-unsigned.hap" -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($unsigned) { Write-Host "Unsigned artifact: $($unsigned.FullName)" }
        if ($BuildOnly) { return }
        exit 1
    }
    $hap = Get-ChildItem $hapDir -Filter "*-unsigned.hap" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $hap) {
        Write-Warning "No *-unsigned.hap found either; build may have failed."
        if ($BuildOnly) { return }
        exit 1
    }
    Write-Warning "Using UNSIGNED HAP (emulator only): $($hap.FullName)"
} else {
    Write-Host "Signed HAP: $($hap.FullName)"
}
if ($BuildOnly) { return }

Write-Host "==> Waiting for a device / emulator (up to 120s) ..."
$targets = @()
$deadline = (Get-Date).AddSeconds(120)
do {
    $targets = @(& $hdc list targets 2>$null | Where-Object { $_ -and $_ -notmatch "Empty" })
    if ($targets.Count -gt 0) { break }
    Start-Sleep -Seconds 2
} while ((Get-Date) -lt $deadline)
if ($targets.Count -eq 0) {
    throw "No device connected. Start an emulator or plug in a phone, then retry."
}
Write-Host "Targets: $($targets -join ', ')"

Write-Host "==> Installing ..."
& $hdc install -r $hap.FullName
if ($LASTEXITCODE -ne 0) { throw "hdc install failed ($LASTEXITCODE)" }

Write-Host "==> Launching $Bundle/$Ability ..."
& $hdc shell aa start -a $Ability -b $Bundle

Write-Host "Done."
