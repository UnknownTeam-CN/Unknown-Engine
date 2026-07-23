@echo off
color 0a
set "PATH=C:\HaxeToolkit\haxe;C:\HaxeToolkit\neko;%PATH%"
set HAXEPATH=C:\HaxeToolkit\haxe\
set NEKO_INSTPATH=C:\HaxeToolkit\neko\
cd /d E:\interesting\FNF-PsychEngine-1.0.4
echo BUILDING GAME
haxelib run lime build windows -debug
echo.
echo done.
pause
