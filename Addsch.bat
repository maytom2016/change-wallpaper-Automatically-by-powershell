@echo off
set "path1=%CD%\HideAcWp.vbs"  
echo %path1%                                 rem 换壁纸的路径
set "hour=1"                                    rem 每小时换一次
schtasks.exe /create /tn "AutoChangeWallpapertest" /tr %path1% /sc HOURLY /mo 1 /f
echo 创建成功，请检查...
pause