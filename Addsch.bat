@echo off
set "path1=%CD%\HideAcWp.vbs"  
echo %path1%                                 rem ����ֽ��·��
set "hour=1"                                    rem ÿСʱ��һ��
schtasks.exe /create /tn "AutoChangeWallpapertest" /tr %path1% /sc HOURLY /mo 1 /f
echo �����ɹ�������...
pause