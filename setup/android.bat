@echo off
color 0b
cd ..
@echo on
echo ============================================
echo   Unknown Engine - Android Build Setup
echo ============================================
echo.
echo This script installs all required haxelibs for Android compilation.
echo Make sure you have already run setup/windows.bat first.
echo.
echo --- Installing Android-specific dependencies ---
echo.

REM Core libs (skip if already installed from windows.bat)
haxelib install lime 8.1.2 2>nul
haxelib install openfl 9.3.3 2>nul
haxelib install flixel 5.6.1 2>nul
haxelib install flixel-addons 3.2.2 2>nul
haxelib install hscript-iris 1.1.3 2>nul
haxelib install tjson 1.4.0 2>nul
haxelib set lime 8.1.2
haxelib set openfl 9.3.3

REM Git-based libs
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7

echo.
echo --- Android SDK/NDK Setup ---
echo.
echo Before building for Android, you need:
echo   1. JDK 17 (recommend Eclipse Temurin / Adoptium)
echo   2. Android SDK (install via Android Studio or command-line tools)
echo   3. Android NDK (r21e or later, recommended r25c)
echo.
echo After installing the above, run:
echo   lime setup android
echo This will prompt you for the paths to JDK, Android SDK, and NDK.
echo.
echo --- Verifying setup ---
echo.
lime setup android
echo.
echo ============================================
echo   Setup complete!
echo ============================================
echo.
echo To build the APK, run:
echo   build-android.bat release
echo.
pause
