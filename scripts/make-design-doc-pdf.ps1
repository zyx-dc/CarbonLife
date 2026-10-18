# Render the competition design document (docs/tasks/design-doc/*.docx) to PDF
# with headless LibreOffice.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\make-design-doc-pdf.ps1
#
# Notes:
#   - The .docx is produced by `node scripts/make-docx.cjs`; run that first.
#   - LibreOffice is auto-detected from the default install location, or pass
#     -SofficePath explicitly.
#   - The PDF is rendered into a scratch directory and then moved into place.
#     Converting straight onto an existing target file can fail on Windows with
#     "SfxBaseModel::impl_store ... failed: 0x11b (Io Abort 27)".
#   - The .docx file name is discovered from the directory, so this script stays
#     pure ASCII and does not hard-code any non-ASCII file name.
#
# Exit code: 0 = PDF written; 1 = failure.

#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Root,
    [string]$SofficePath,
    [string]$DocDir = "docs\tasks\design-doc"
)

$ErrorActionPreference = "Stop"

if (-not $Root) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

if (-not $SofficePath) {
    $candidates = @(
        (Join-Path $env:ProgramFiles "LibreOffice\program\soffice.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "LibreOffice\program\soffice.exe")
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { $SofficePath = $c; break }
    }
}
if (-not $SofficePath) {
    $cmd = Get-Command soffice -ErrorAction SilentlyContinue
    if ($cmd) { $SofficePath = $cmd.Source }
}
if (-not $SofficePath -or -not (Test-Path $SofficePath)) {
    Write-Host "ERROR: LibreOffice (soffice.exe) not found. Pass -SofficePath." -ForegroundColor Red
    exit 1
}

$dir = Join-Path $Root $DocDir
if (-not (Test-Path $dir)) {
    Write-Host ("ERROR: document directory not found: {0}" -f $dir) -ForegroundColor Red
    exit 1
}

$docx = Get-ChildItem -LiteralPath $dir -File -Filter *.docx | Select-Object -First 1
if (-not $docx) {
    Write-Host ("ERROR: no .docx found in {0} - run 'node scripts/make-docx.cjs' first." -f $dir) -ForegroundColor Red
    exit 1
}

$base = [System.IO.Path]::GetFileNameWithoutExtension($docx.Name)
$target = Join-Path $dir ($base + ".pdf")

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("design-doc-pdf-" + [System.IO.Path]::GetRandomFileName())
$profile = Join-Path ([System.IO.Path]::GetTempPath()) ("lo-profile-" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
New-Item -ItemType Directory -Force -Path $profile | Out-Null

try {
    $profileUrl = "file:///" + ($profile -replace '\\', '/')
    Write-Host ("LibreOffice : {0}" -f $SofficePath)
    Write-Host ("Input       : {0}" -f $docx.FullName)
    Write-Host ("Output      : {0}" -f $target)

    # soffice.exe is a GUI-subsystem launcher on Windows: it returns immediately and
    # spawns soffice.bin in the background, and it does not write to the console.
    # So poll for the produced file instead of trusting the process to have finished.
    # (It also emits a harmless "Could not find platform independent libraries"
    # notice to stderr; with $ErrorActionPreference = 'Stop' PowerShell would turn
    # that into a terminating NativeCommandError, so relax it for the call.)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $log = & $SofficePath "-env:UserInstallation=$profileUrl" --headless --norestore `
            --convert-to pdf --outdir $scratch $docx.FullName 2>&1
    } finally {
        $ErrorActionPreference = $prevEap
    }

    $produced = $null
    for ($i = 0; $i -lt 60; $i++) {
        $produced = Get-ChildItem -LiteralPath $scratch -File -Filter *.pdf -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($produced) { break }
        Start-Sleep -Milliseconds 500
    }

    if (-not $produced) {
        Write-Host "ERROR: LibreOffice produced no PDF within 30s." -ForegroundColor Red
        $log | ForEach-Object { Write-Host ("  " + $_) }
        exit 1
    }

    # A zero-byte file can appear before the writer finishes.
    if ($produced.Length -eq 0) {
        for ($i = 0; $i -lt 40; $i++) {
            Start-Sleep -Milliseconds 500
            $produced.Refresh()
            if ($produced.Length -gt 0) { break }
        }
    }

    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    Move-Item -LiteralPath $produced.FullName -Destination $target -Force

    Write-Host ("wrote {0} ({1} bytes)" -f $target, (Get-Item -LiteralPath $target).Length) -ForegroundColor Green
} finally {
    Remove-Item -Recurse -Force $scratch -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $profile -ErrorAction SilentlyContinue
}
