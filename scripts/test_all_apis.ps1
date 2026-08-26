# =========================================================
# MahalFlow Automated API Test & Model Validation Runner
# =========================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $ScriptDir "..\backend-go"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "🚀 Running MahalFlow Full Backend API Test Suite" -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Cyan

$GoExe = "C:\Program Files\Go\bin\go.exe"
if (-not (Test-Path $GoExe)) {
    $GoExe = "go"
}

Push-Location $BackendDir
try {
    & $GoExe run cmd/test-api/main.go
    $ExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

if ($ExitCode -eq 0) {
    Write-Host "`n✅ All API endpoints and response models are 100% verified!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Some API tests failed. See errors above." -ForegroundColor Red
}

exit $ExitCode
