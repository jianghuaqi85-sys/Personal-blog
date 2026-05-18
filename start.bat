@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo   Blog + Chat Server Launcher
echo ========================================
echo.

set "BLOG_DIR=%~dp0"
set "CHAT_DIR=%~dp0chat-server"
set "HUGO=C:\Users\86198\AppData\Local\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe"
set "CLOUDFLARED=D:\cloudflared.exe"

echo [0/5] Cleaning up old processes...
taskkill /IM hugo.exe /F >nul 2>&1
taskkill /IM cloudflared.exe /F >nul 2>&1
taskkill /IM api.exe /F >nul 2>&1
taskkill /IM node.exe /F >nul 2>&1
timeout /t 2 /nobreak >nul

echo [1/5] Starting chat server (port 8080)...
cd /d "%CHAT_DIR%"
start "ChatServer" cmd /k "api.exe"
timeout /t 3 /nobreak >nul

echo [2/5] Starting NeteaseCloudMusicApi (port 3000)...
cd /d "%BLOG_DIR%netease-api"
start "NeteaseAPI" cmd /k "node server.js"
timeout /t 3 /nobreak >nul

echo [3/5] Starting Hugo blog (port 1313)...
cd /d "%BLOG_DIR%"
start "HugoBlog" cmd /k ""%HUGO%" server --port 1313 --bind 0.0.0.0 --baseURL http://laojiang666.cn"
timeout /t 3 /nobreak >nul

echo [4/5] Starting Cloudflare Tunnel...
start "CloudflareTunnel" cmd /k ""%CLOUDFLARED%" --protocol http2 tunnel run gin-chat"
timeout /t 5 /nobreak >nul

echo [5/5] Verifying services...
echo.

set "OK=0"
set "FAIL=0"

netstat -ano | findstr ":8080.*LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Chat Server          localhost:8080
    set /a OK+=1
) else (
    echo   [FAIL] Chat Server        not started
    set /a FAIL+=1
)

netstat -ano | findstr ":3000.*LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] NeteaseCloudMusicApi localhost:3000
    set /a OK+=1
) else (
    echo   [FAIL] NeteaseCloudMusicApi not started
    set /a FAIL+=1
)

netstat -ano | findstr ":1313.*LISTENING" >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Hugo Blog            localhost:1313
    set /a OK+=1
) else (
    echo   [FAIL] Hugo Blog          not started
    set /a FAIL+=1
)

tasklist | findstr "cloudflared.exe" >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Cloudflare Tunnel
    set /a OK+=1
) else (
    echo   [FAIL] Cloudflare Tunnel  not started
    set /a FAIL+=1
)

echo.
echo ========================================
if %FAIL%==0 (
    echo   All services started successfully!
) else (
    echo   %FAIL% service(s) failed to start
)
echo.
echo   Blog:    https://laojiang666.cn
echo   Music:   https://laojiang666.cn/music/
echo   MusicAPI: https://music-api.laojiang666.cn
echo   Chat:    https://chat.laojiang666.cn
echo   Chat UI: https://laojiang666.cn/chat/
echo ========================================
echo.
echo   Press any key to close this window
pause >nul
