# 博客+聊天室 服务器部署脚本
# 以管理员身份运行 PowerShell 执行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  博客 + 聊天室 服务器部署" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 创建工作目录
$deployDir = "C:\deploy"
$blogDir = "$deployDir\blog"
$chatDir = "$deployDir\chat"

if (!(Test-Path $deployDir)) { New-Item -ItemType Directory -Path $deployDir | Out-Null }
if (!(Test-Path $blogDir)) { New-Item -ItemType Directory -Path $blogDir | Out-Null }
if (!(Test-Path $chatDir)) { New-Item -ItemType Directory -Path $chatDir | Out-Null }

# ===== 1. 安装 Hugo =====
Write-Host "[1/5] 安装 Hugo..." -ForegroundColor Yellow
$hugoExe = "C:\Hugo\hugo.exe"
if (!(Test-Path $hugoExe)) {
    $hugoUrl = "https://github.com/gohugoio/hugo/releases/download/v0.147.4/hugo_extended_0.147.4_windows-amd64.zip"
    $hugoZip = "$env:TEMP\hugo.zip"
    Write-Host "  下载 Hugo..."
    Invoke-WebRequest -Uri $hugoUrl -OutFile $hugoZip -UseBasicParsing
    Expand-Archive -Path $hugoZip -DestinationPath "C:\Hugo" -Force
    Remove-Item $hugoZip
    Write-Host "  Hugo 已安装到 C:\Hugo" -ForegroundColor Green
} else {
    Write-Host "  Hugo 已存在" -ForegroundColor Green
}

# ===== 2. 安装 Go =====
Write-Host "[2/5] 安装 Go..." -ForegroundColor Yellow
$goExe = "C:\Program Files\Go\bin\go.exe"
if (!(Test-Path $goExe)) {
    $goUrl = "https://go.dev/dl/go1.24.4.windows-amd64.msi"
    $goMsi = "$env:TEMP\go.msi"
    Write-Host "  下载 Go..."
    Invoke-WebRequest -Uri $goUrl -OutFile $goMsi -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$goMsi`" /quiet" -Wait
    Remove-Item $goMsi
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "  Go 已安装" -ForegroundColor Green
} else {
    Write-Host "  Go 已存在" -ForegroundColor Green
}

# ===== 3. 安装 cloudflared =====
Write-Host "[3/5] 安装 cloudflared..." -ForegroundColor Yellow
$cfExe = "C:\cloudflared\cloudflared.exe"
if (!(Test-Path $cfExe)) {
    $cfUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    if (!(Test-Path "C:\cloudflared")) { New-Item -ItemType Directory -Path "C:\cloudflared" | Out-Null }
    Write-Host "  下载 cloudflared..."
    Invoke-WebRequest -Uri $cfUrl -OutFile $cfExe -UseBasicParsing
    Write-Host "  cloudflared 已安装到 C:\cloudflared" -ForegroundColor Green
} else {
    Write-Host "  cloudflared 已存在" -ForegroundColor Green
}

# ===== 4. 提示上传文件 =====
Write-Host "[4/5] 上传文件..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  请在本地电脑上执行以下操作:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. 打开远程桌面的 '本地资源' 选项卡" -ForegroundColor White
Write-Host "  2. 点击 '更多' -> 勾选 C 盘" -ForegroundColor White
Write-Host "  3. 在远程服务器的文件管理器中访问:" -ForegroundColor White
Write-Host "     \\tsclient\C\Users\86198\Desktop\个人博客" -ForegroundColor Green
Write-Host "     \\tsclient\C\Users\86198\Desktop\GIn" -ForegroundColor Green
Write-Host "  4. 将这两个文件夹的内容分别复制到:" -ForegroundColor White
Write-Host "     C:\deploy\blog\" -ForegroundColor Green
Write-Host "     C:\deploy\chat\" -ForegroundColor Green
Write-Host ""
Write-Host "  复制完成后按回车继续..." -ForegroundColor Yellow
Read-Host

# ===== 5. 生成启动脚本 =====
Write-Host "[5/5] 生成启动脚本..." -ForegroundColor Yellow

$startBat = @"
@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo   博客 + 聊天室 启动脚本
echo ========================================
echo.

:: 停止旧进程
taskkill /IM hugo.exe /F >nul 2>&1
taskkill /IM cloudflared.exe /F >nul 2>&1
taskkill /IM api.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

:: 启动聊天室
echo [1/3] 启动聊天室 (端口 8080)...
cd /d "C:\deploy\chat"
start "ChatServer" cmd /k "api.exe"
timeout /t 3 /nobreak >nul

:: 启动 Hugo 博客
echo [2/3] 启动 Hugo 博客 (端口 1313)...
cd /d "C:\deploy\blog"
start "HugoBlog" cmd /k "C:\Hugo\hugo.exe server --port 1313 --bind 0.0.0.0 --baseURL http://laojiang666.cn --minify"
timeout /t 3 /nobreak >nul

:: 启动 Cloudflare Tunnel
echo [3/3] 启动 Cloudflare Tunnel...
start "CloudflareTunnel" cmd /k "C:\cloudflared\cloudflared.exe tunnel run gin-chat"
timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo   启动完成！
echo   博客:   https://laojiang666.cn
echo   聊天室: https://chat.laojiang666.cn
echo ========================================
pause
"@

Set-Content -Path "C:\deploy\start.bat" -Value $startBat -Encoding UTF8
Write-Host "  启动脚本已生成: C:\deploy\start.bat" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  部署准备完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  下一步:" -ForegroundColor Yellow
Write-Host "  1. 按提示上传博客和聊天室文件" -ForegroundColor White
Write-Host "  2. 双击 C:\deploy\start.bat 启动服务" -ForegroundColor White
Write-Host "  3. 运行 cloudflared tunnel login 登录 Cloudflare" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "按回车退出..." -ForegroundColor Gray
Read-Host
