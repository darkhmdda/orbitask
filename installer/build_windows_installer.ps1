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

if (-not $env:SUPABASE_URL) {
    throw "Falta SUPABASE_URL"
}
if (-not $env:SUPABASE_PUBLISHABLE_KEY) {
    throw "Falta SUPABASE_PUBLISHABLE_KEY"
}
if (-not $env:SUPABASE_AUTH_REDIRECT_URL) {
    $env:SUPABASE_AUTH_REDIRECT_URL = "com.darkhmdda.orbitask://login-callback"
}

Push-Location $Root
try {
    flutter build windows --release `
        --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
        --dart-define=SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY `
        --dart-define=SUPABASE_AUTH_REDIRECT_URL=$env:SUPABASE_AUTH_REDIRECT_URL

    if ($LASTEXITCODE -ne 0) {
        throw "Flutter build fallo con codigo $LASTEXITCODE"
    }

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
