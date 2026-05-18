# PowerShell script to push project to GitHub (PS5.1 compatible)

$ErrorActionPreference = "Stop"
$gitExe = (Get-Command git).Source

Write-Host "=== Undoing last commit (keep changes) ==="
& $gitExe reset --soft HEAD~1
if ($LASTEXITCODE -ne 0) { Write-Host "Reset failed!"; exit 1 }

Write-Host "=== Staging all files ==="
& $gitExe add -A

Write-Host "=== Committing ==="
& $gitExe commit -m "feat: initial project setup with blog, chat-server, and music API"

Write-Host "=== Pushing to GitHub ==="
& $gitExe push -u origin master

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== SUCCESS ==="
} else {
    Write-Host "=== FAILED ==="
    exit 1
}
