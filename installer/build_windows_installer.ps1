$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Pubspec = Join-Path $Root "pubspec.yaml"
$Iss = Join-Path $PSScriptRoot "orbitask.iss"

$versionLine = Get-Content $Pubspec | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
if (-not $versionLine -or $versionLine -notmatch '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+\d+)?\s*$') {
    throw "No se pudo leer una version valida desde pubspec.yaml"
}

$AppVersion = $Matches[1]

$Iscc = Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 7\ISCC.exe"
if (-not (Test-Path $Iscc)) {
    $cmd = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
    if ($cmd) {
        $Iscc = $cmd.Source
    } else {
        throw "No se encontro ISCC.exe de Inno Setup 7"
    }
}

Push-Location $Root
try {
    flutter build windows --release
    & $Iscc "/DMyAppVersion=$AppVersion" $Iss
    if ($LASTEXITCODE -ne 0) {
        throw "Inno Setup fallo con codigo $LASTEXITCODE"
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Instalador creado:"
Write-Host (Join-Path $PSScriptRoot "output\Orbitask-v$AppVersion-windows-setup.exe")
