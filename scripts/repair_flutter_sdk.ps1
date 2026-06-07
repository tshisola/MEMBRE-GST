# Repare le SDK Flutter (C:\flutter) — IFCM Lubumbashi
# Usage: powershell -ExecutionPolicy Bypass -File scripts\repair_flutter_sdk.ps1

$FlutterRoot = "C:\flutter"
$Dart = Join-Path $FlutterRoot "bin\cache\dart-sdk\bin\dart.exe"
$FlutterBat = Join-Path $FlutterRoot "bin\flutter.bat"

Write-Host "=== Reparation Flutter SDK ===" -ForegroundColor Cyan

if (-not (Test-Path $FlutterRoot)) {
    Write-Error "Flutter introuvable: $FlutterRoot"
    exit 1
}

# 1. Restaurer examples/ (cause du crash CLI)
if (-not (Test-Path (Join-Path $FlutterRoot "examples"))) {
    Write-Host "Restauration de examples/ via git..."
    Push-Location $FlutterRoot
    git restore examples 2>$null
    if (-not (Test-Path "examples")) { git checkout HEAD -- examples }
    Pop-Location
}

# 2. Reconstruire flutter_tools
Write-Host "Reconstruction de flutter_tools..."
Push-Location (Join-Path $FlutterRoot "packages\flutter_tools")
& $Dart pub get
Pop-Location

# 3. PATH session — priorite C:\flutter
$env:FLUTTER_ROOT = $FlutterRoot
$cleanPath = ($env:PATH -split ';' | Where-Object { $_ -and $_ -notmatch 'flutter' }) -join ';'
$env:PATH = "$FlutterRoot\bin;$FlutterRoot\bin\cache\dart-sdk\bin;$cleanPath"

Write-Host ""
& $FlutterBat --version
Write-Host ""
Write-Host "PATH corrige pour cette session. Pour le rendre permanent:" -ForegroundColor Yellow
Write-Host "  Panneau de config > Systeme > Variables d'environnement" -ForegroundColor Yellow
Write-Host "  Mettre C:\flutter\bin EN PREMIER dans Path" -ForegroundColor Yellow
Write-Host "  Supprimer C:\flutter_windows_3.41.1-stable\flutter\bin du Path" -ForegroundColor Yellow
