@echo off
:: 启动 Cloudflare Tunnel（命名隧道，绑定自定义域名）
set CLOUDFLARED=D:\cloudflared.exe

echo 启动 Cloudflare Tunnel...
echo 域名: laojiang666.cn
%CLOUDFLARED% --protocol http2 tunnel run gin-chat
