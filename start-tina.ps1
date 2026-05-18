Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TinaCMS + Hugo Dev Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Blog:    http://localhost:1313" -ForegroundColor Green
Write-Host "  Admin:   http://localhost:4002" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

Set-Location $PSScriptRoot

# Stop existing processes
Write-Host ""
Write-Host "[1/2] Cleaning up..." -ForegroundColor Yellow
Stop-Process -Name hugo -Force -ErrorAction SilentlyContinue
Stop-Process -Name node -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start TinaCMS + Hugo
Write-Host "[2/2] Starting server..." -ForegroundColor Yellow
Start-Process -FilePath "cmd" -ArgumentList "/c", "npx tinacms dev --port 4002 --datalayer-port 9001 -c `"hugo server -D -p 1313`"" -WindowStyle Normal

# Wait and open browser
Start-Sleep -Seconds 10
Start-Process "http://localhost:4002"

Write-Host ""
Write-Host "Server started! Browser opened." -ForegroundColor Green
Write-Host "Close the TinaCMS window to stop." -ForegroundColor Yellow
Start-Sleep -Seconds 3
