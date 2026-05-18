# 命名隧道使用固定域名，仅做状态监控
param(
    [string]$UrlPath = "C:\Users\86198\Desktop\个人博客\chat-server\.tunnel_url"
)

$domain = "https://laojiang666.cn"

# 写入固定域名
$domain | Out-File -FilePath $UrlPath -Encoding UTF8 -NoNewline

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "隧道状态" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "固定域名: $domain" -ForegroundColor Green
Write-Host ""

# 检查 cloudflared 是否运行
$process = Get-Process cloudflared -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "cloudflared 状态: 运行中 (PID: $($process.Id))" -ForegroundColor Green
} else {
    Write-Host "cloudflared 状态: 未运行" -ForegroundColor Yellow
}
