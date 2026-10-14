# Build a *signed* HAP for real-device testing and copy it to dist\.
#
# Prerequisite (one time, in DevEco Studio):
#   Open the project -> File > Project Structure > Signing Configs ->
#   tick "Automatically generate signature" -> sign in with your Huawei
#   account -> Apply/OK. That writes the `signingConfigs` block (and the
#   product's `signingConfig` reference) into build-profile.json5, and
#   registers your device UDID in the debug profile.
#   (This project already has auto-signing material in ~/.ohos/config and a
#    Huawei debug profile with a device UDID, so DevEco should restore it.)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\build-signed.ps1
#
# Then install on the device:
#   hdc install -r dist\CarbonLife-1.0.0-signed.hap

param(
    [string]$Version = "1.0.0",
    [string]$BuildMode = "release",
    [string]$DevEco = ""
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
$hvigor = "$DevEco\tools\hvigor\bin\hvigorw.bat"
$hdc = "$DevEco\sdk\default\openharmony\toolchains\hdc.exe"

Write-Host "==> Building HAP ($BuildMode) ..."
Push-Location $Project
try {
    & $hvigor assembleHap --mode module -p product=default -p buildMode=$BuildMode --no-daemon
    if ($LASTEXITCODE -ne 0) { throw "hvigor build failed ($LASTEXITCODE)" }
}
finally {
    Pop-Location
}

$hapDir = Join-Path $Project "entry\build\default\outputs\default"
$signed = Get-ChildItem $hapDir -Filter "*-signed.hap" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $signed) {
    Write-Warning "No *-signed.hap produced."
    Write-Warning "Enable File > Project Structure > Signing Configs >"
    Write-Warning "'Automatically generate signature' in DevEco Studio, then re-run."
    $unsigned = Get-ChildItem $hapDir -Filter "*-unsigned.hap" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($unsigned) { Write-Host "Unsigned artifact (emulator only): $($unsigned.FullName)" }
    exit 1
}

$dist = Join-Path $Project "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$out = Join-Path $dist "CarbonLife-$Version-signed.hap"
Copy-Item $signed.FullName $out -Force

Write-Host ""
Write-Host "Signed HAP: $out"
Write-Host "Install:    & `"$hdc`" install -r `"$out`""
