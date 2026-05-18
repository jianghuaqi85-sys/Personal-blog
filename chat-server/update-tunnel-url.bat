@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo   隧道状态
echo ========================================
echo.
echo 命名隧道已配置固定域名
echo 域名: https://laojiang666.cn
echo.
echo 重启后域名不会改变，无需更新 URL。
echo.
echo 当前隧道 URL 已写入 .tunnel_url 文件
echo ========================================
echo.
echo https://laojiang666.cn > "%~dp0.tunnel_url"
echo 已更新 .tunnel_url 文件
echo.
pause
