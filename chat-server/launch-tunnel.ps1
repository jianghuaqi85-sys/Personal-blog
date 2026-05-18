# 智能启动 cloudflared 并捕获隧道 URL
param(
    [string]$CloudflaredPath = "D:\cloudflared.exe",
    [string]$LocalUrl = "http://localhost:8080",
    [string]$TunnelUrlPath = "C:\Users\86198\Desktop\个人博客\chat-server\.tunnel_url",
    [int]$TimeoutSeconds = 30
)

Write-Host "正在启动 Cloudflare Tunnel..." -ForegroundColor Cyan
Write-Host "本地地址: $LocalUrl" -ForegroundColor Gray
Write-Host ""

# 清空旧的 URL 文件
if (Test-Path $TunnelUrlPath) {
    Remove-Item $TunnelUrlPath -Force
}

# 启动 cloudflared 进程
Write-Host "启动 cloudflared..." -ForegroundColor Yellow

$process = Start-Process -FilePath $CloudflaredPath `
    -ArgumentList "--protocol http2 tunnel run gin-chat" `
    -PassThru `
    -RedirectStandardOutput "$env:TEMP\cloudflared_stdout.log" `
    -RedirectStandardError "$env:TEMP\cloudflared_stderr.log" `
    -WindowStyle Hidden

Write-Host "cloudflared 已启动 (PID: $($process.Id))" -ForegroundColor Gray

# 命名隧道使用固定域名
$tunnelUrl = "https://laojiang666.cn"
Write-Host "隧道已建立！" -ForegroundColor Green
Write-Host "公网地址: $tunnelUrl" -ForegroundColor Cyan

# 保存 URL 到文件
$tunnelUrl | Out-File -FilePath $TunnelUrlPath -Encoding UTF8 -NoNewline
Write-Host "URL 已保存到: $TunnelUrlPath" -ForegroundColor Gray
