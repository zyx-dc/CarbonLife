# 用发布证书出包（不依赖 DevEco 的密码加密，可直接在命令行/CI 里跑）#
# 为什么不用 hvigor 内置签名：hvigor 要求 storePassword 是 DevEco 加密后的 64 位串，
# 明文会被拒（"length ... less than 32"）。所以这里先编出未签名包，再用 SDK 自带的
# hap-sign-tool 签，密码只从本机 signing 目录读取，永远不写进仓库里的配置。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File scripts\sign-release.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\sign-release.ps1 -SigningDir "D:\keys"
#
# 前置：signing 目录下有
#   carbonlife-release.p12                 私钥
#   CarbonLifeReleaseCN.cer                发布证书（含链）
#   CarbonLifeReleaseProfileCNRelease.p7b  发布 Profile
#   password.txt                           内含 "keystore password: xxx"

param(
    [string]$SigningDir = "C:\Users\39748\Documents\CarbonLife-signing",
    [string]$HapDir = "",
    [string]$SdkRoot = "D:\DEStudio\DevEco Studio\sdk\default",
    [string]$JavaHome = "D:\DEStudio\DevEco Studio\jbr",
    [int]$CompatibleVersion = 26
)

$ErrorActionPreference = "Stop"
$project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrEmpty($HapDir)) {
    $HapDir = Join-Path $project "entry\build\default\outputs\default"
}

$p12 = Join-Path $SigningDir "carbonlife-release.p12"
$cer = Join-Path $SigningDir "CarbonLifeReleaseCN.cer"
$p7b = Join-Path $SigningDir "CarbonLifeReleaseProfileCNRelease.p7b"
$pwdFile = Join-Path $SigningDir "password.txt"
foreach ($f in @($p12, $cer, $p7b, $pwdFile)) {
    if (-not (Test-Path $f)) { throw "缺少签名材料：$f" }
}

$password = ((Get-Content $pwdFile -Encoding UTF8 | Select-String -Pattern "keystore password:").Line `
    -replace ".*keystore password:\s*", "").Trim()
if ($password.Length -lt 6) { throw "password.txt 里没读到有效密码" }

$java = Join-Path $JavaHome "bin\java.exe"
$jar = Join-Path $SdkRoot "openharmony\toolchains\lib\hap-sign-tool.jar"
foreach ($f in @($java, $jar)) {
    if (-not (Test-Path $f)) { throw "找不到：$f" }
}

Write-Host "== 1/3 编译（release，产出未签名包） ==" -ForegroundColor Cyan
Push-Location $project
try {
    # hvigor 会在 SignHap 阶段因明文密码失败，但未签名包已经产出，这里只校验产物
    & "C:\Users\39748\AppData\Roaming\npm\devecocli.cmd" build --build-mode release 2>&1 |
        Select-String -Pattern "BUILD SUCCESSFUL|BUILD FAILED|Error Message" | Select-Object -Last 3
} finally {
    Pop-Location
}

$unsigned = Join-Path $HapDir "entry-default-unsigned.hap"
if (-not (Test-Path $unsigned)) {
    throw "没有找到未签名包：$unsigned`n（hvigor 连编译都没过时才会走到这里，先修编译错误）"
}

Write-Host "== 2/3 签名 ==" -ForegroundColor Cyan
$signed = Join-Path $HapDir "entry-default-release-signed.hap"
& $java -jar $jar sign-app `
    -mode localSign `
    -keyAlias carbonlife `
    -keyPwd $password `
    -appCertFile $cer `
    -profileFile $p7b `
    -inFile $unsigned `
    -signAlg SHA256withECDSA `
    -keystoreFile $p12 `
    -keystorePwd $password `
    -outFile $signed `
    -compatibleVersion $CompatibleVersion 2>&1 | Select-Object -Last 3

Write-Host "== 3/3 验签 ==" -ForegroundColor Cyan
& $java -jar $jar verify-app -inFile $signed `
    -outCertChain (Join-Path $env:TEMP "verify-chain.cer") `
    -outProfile (Join-Path $env:TEMP "verify-profile.p7b") 2>&1 | Select-Object -Last 2

$item = Get-Item $signed
Write-Host ""
Write-Host ("发布签名包：" + $item.FullName) -ForegroundColor Green
Write-Host ("大小：" + [math]::Round($item.Length / 1MB, 2) + " MB")
Write-Host "装机：hdc install -r `"$($item.FullName)`""
