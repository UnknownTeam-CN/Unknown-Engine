@echo off
chcp 65001 >nul 2>&1
color 0a
set "SCRIPT_DIR=%~dp0"

:MAIN_MENU
cls
echo ========================================
echo          UE Build Helper    By PandamanAF
echo ========================================
echo.
echo   [1] Download Haxe Dependencies
echo   [2] Download MSVC (Visual Studio)
echo   [3] Build Options
echo   [0] Exit
echo.
echo ========================================
choice /c 1230 /n /m "Select [1/2/3/0]: "
if errorlevel 4 goto EXIT
if errorlevel 3 goto BUILD_MENU
if errorlevel 2 goto INSTALL_MSVC
if errorlevel 1 goto INSTALL_HAXE

:INSTALL_HAXE
cls
echo ========================================
echo       Download Haxe Dependencies
echo ========================================
echo.
pushd "%SCRIPT_DIR%.."
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2
haxelib install openfl 9.3.3
haxelib install flixel 5.6.1
haxelib install flixel-addons 3.2.2
haxelib install flixel-tools 1.5.1
haxelib install hscript-iris 1.1.3
haxelib install tjson 1.4.0
haxelib install hxdiscord_rpc 1.2.4
haxelib install hxvlc 2.0.1 --skip-dependencies
haxelib set lime 8.1.2
haxelib set openfl 9.3.3
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
popd
echo.
echo Done!
pause
goto MAIN_MENU

:INSTALL_MSVC
cls
echo ========================================
echo       Download MSVC (Visual Studio)
echo ========================================
echo.
pushd "%SCRIPT_DIR%.."
echo Installing Microsoft Visual Studio Community (Dependency)
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
del vs_Community.exe
popd
echo.
echo Done!
pause
goto MAIN_MENU

:BUILD_MENU
cls
echo ========================================
echo          Build Options
echo ========================================
echo.
echo   [1] x64 Release
echo   [2] x64 Debug
echo   [3] x32 Release
echo   [0] Back to Main Menu
echo.
echo ========================================
choice /c 1230 /n /m "Select [1/2/3/0]: "
if errorlevel 4 goto MAIN_MENU
if errorlevel 3 goto BUILD_X32
if errorlevel 2 goto BUILD_X64_DEBUG
if errorlevel 1 goto BUILD_X64

:BUILD_X64
cls
echo ========================================
echo       Build x64 Release
echo ========================================
echo.
pushd "%SCRIPT_DIR%..\.."
echo BUILDING GAME
haxelib run lime build windows -release
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin
popd
goto END

:BUILD_X64_DEBUG
cls
echo ========================================
echo       Build x64 Debug
echo ========================================
echo.
pushd "%SCRIPT_DIR%..\.."
echo BUILDING GAME
haxelib run lime build windows -debug
echo.
echo done.
pause
pwd
explorer.exe export\debug\windows\bin
popd
goto END

:BUILD_X32
cls
echo ========================================
echo       Build x32 Release
echo ========================================
echo.
pushd "%SCRIPT_DIR%..\.."
echo BUILDING GAME
haxelib run lime build windows -32 -release -D 32bits -D HXCPP_M32
echo.
echo done.
pause
pwd
explorer.exe export\32bit\windows\bin
popd
goto END

:EXIT
exit /b

:END
exit /b
