# 命名隧道使用固定域名，无需自动更新 URL
param(
    [string]$TunnelUrlPath = "C:\Users\86198\Desktop\个人博客\chat-server\.tunnel_url"
)

$domain = "https://laojiang666.cn"

# 写入固定域名到 URL 文件
$domain | Out-File -FilePath $TunnelUrlPath -Encoding UTF8 -NoNewline

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "隧道 URL 监控器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "命名隧道已配置固定域名，无需自动更新。" -ForegroundColor Green
Write-Host "域名: $domain" -ForegroundColor Cyan
Write-Host ""
Write-Host "此脚本可安全关闭。" -ForegroundColor Gray
