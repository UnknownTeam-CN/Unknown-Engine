@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1
color 0b
set "SCRIPT_DIR=%~dp0"

REM ============================================
REM  Unknown Engine Build Script
REM  (merged: build helper.bat + build-android.bat)
REM ============================================

:TOP_MENU
cls
echo ============================================
echo   Unknown Engine Build Script
echo ============================================
echo.
echo   1. Platform
echo   2. Dependencies
echo   3. Lime setup
echo   0. Exit
echo.
echo ============================================
set /p "TOP=Select [0-3]: "

if "!TOP!"=="1" goto PLATFORM_MENU
if "!TOP!"=="2" (
    set "RETURN=TOP_MENU"
    goto INSTALL_HAXE
)
if "!TOP!"=="3" goto LIMESETUP_MENU
if "!TOP!"=="0" exit /b 0
echo Invalid selection. Please enter 0-3.
echo.
goto TOP_MENU

REM ============================================
REM  1. Platform
REM ============================================
:PLATFORM_MENU
cls
echo ============================================
echo   Platform
echo ============================================
echo.
echo   1. Windows
echo   2. Android
echo   0. Back
echo.
echo ============================================
set /p "PF=Select [0-2]: "

if "!PF!"=="1" goto WINDOWS_MENU
if "!PF!"=="2" goto ANDROID_MAIN
if "!PF!"=="0" goto TOP_MENU
echo Invalid selection. Please enter 0-2.
echo.
goto PLATFORM_MENU

REM ---- Windows (from build helper.bat) ----
:WINDOWS_MENU
cls
echo ============================================
echo   Windows Build Helper    By PandamanAF
echo ============================================
echo.
echo   [1] Download Haxe Dependencies
echo   [2] Download MSVC (Visual Studio)
echo   [3] Build Options
echo   [0] Back
echo.
echo ============================================
choice /c 1230 /n /m "Select [1/2/3/0]: "
if errorlevel 4 goto PLATFORM_MENU
if errorlevel 3 goto BUILD_MENU
if errorlevel 2 goto INSTALL_MSVC
if errorlevel 1 (
    set "RETURN=WINDOWS_MENU"
    goto INSTALL_HAXE
)

:INSTALL_HAXE
if not defined RETURN set "RETURN=TOP_MENU"
cls
echo ============================================
echo       Download Haxe Dependencies
echo ============================================
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
goto !RETURN!

:INSTALL_MSVC
cls
echo ============================================
echo       Download MSVC (Visual Studio)
echo ============================================
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
goto WINDOWS_MENU

:BUILD_MENU
cls
echo ============================================
echo          Build Options
echo ============================================
echo.
echo   [1] x64 Release
echo   [2] x64 Debug
echo   [3] x32 Release
echo   [0] Back to Platform menu
echo.
echo ============================================
choice /c 1230 /n /m "Select [1/2/3/0]: "
if errorlevel 4 goto PLATFORM_MENU
if errorlevel 3 goto BUILD_X32
if errorlevel 2 goto BUILD_X64_DEBUG
if errorlevel 1 goto BUILD_X64

:BUILD_X64
cls
echo ============================================
echo       Build x64 Release
echo ============================================
echo.
pushd "%SCRIPT_DIR%.\."
echo BUILDING GAME
haxelib run lime build windows -release
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin
popd
goto WINDOWS_MENU

:BUILD_X64_DEBUG
cls
echo ============================================
echo       Build x64 Debug
echo ============================================
echo.
pushd "%SCRIPT_DIR%.\."
echo BUILDING GAME
haxelib run lime build windows -debug
echo.
echo done.
pause
pwd
explorer.exe export\debug\windows\bin
popd
goto WINDOWS_MENU

:BUILD_X32
cls
echo ============================================
echo       Build x32 Release
echo ============================================
echo.
pushd "%SCRIPT_DIR%.\."
echo BUILDING GAME
haxelib run lime build windows -32 -release -D 32bits -D HXCPP_M32
echo.
echo done.
pause
pwd
explorer.exe export\32bit\windows\bin
popd
goto WINDOWS_MENU

REM ============================================
REM  3. Lime setup
REM ============================================
:LIMESETUP_MENU
cls
echo ============================================
echo   Lime setup
echo ============================================
echo.
echo   1. Windows
echo   2. Android
echo   0. Back
echo.
echo ============================================
set /p "LS=Select [0-2]: "

if "!LS!"=="1" goto LIMESETUP_WINDOWS
if "!LS!"=="2" goto LIMESETUP_ANDROID
if "!LS!"=="0" goto TOP_MENU
echo Invalid selection. Please enter 0-2.
echo.
goto LIMESETUP_MENU

:LIMESETUP_WINDOWS
cls
echo ============================================
echo   Lime setup - Windows
echo ============================================
echo.
echo Running 'lime setup windows'...
echo.
haxelib run lime setup windows
echo.
echo Done!
pause
goto LIMESETUP_MENU

:LIMESETUP_ANDROID
cls
echo ============================================
echo   Lime setup - Android
echo ============================================
echo.
echo Running 'lime setup android'...
echo Follow the prompts to enter your JDK, SDK, and NDK paths.
echo.
lime setup android
echo.
echo Done!
pause
goto LIMESETUP_MENU

REM ============================================
REM  2. Android (from build-android.bat)
REM ============================================
:ANDROID_MAIN
echo ============================================
echo   Unknown Engine - Android Build
echo ============================================
echo --- Checking build environment ---

REM Check if lime is available
where lime >nul 2>&1
if errorlevel 1 (
    echo ERROR: lime not found in PATH.
    echo Please run the Haxe dependencies installer first.
    pause
    exit /b 1
)

set "SDK_OK=0"
set "NDK_OK=0"
set "JDK_OK=0"
set "SETUP_NEEDED=0"

REM --- Check JDK ---
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" (
        echo   [OK]  JAVA_HOME = %JAVA_HOME%
        set "JDK_OK=1"
    ) else (
        echo   [!!]  JAVA_HOME is set but java.exe not found
        echo        JAVA_HOME = %JAVA_HOME%
    )
)
if not "%JDK_OK%"=="1" (
    for /f "delims=" %%i in ('lime config JAVA_HOME 2^>nul') do set "LIME_JDK=%%i"
    if defined LIME_JDK (
        if exist "!LIME_JDK!\bin\java.exe" (
            echo   [OK]  JDK ^(lime config JAVA_HOME^) = !LIME_JDK!
            set "JDK_OK=1"
        )
    )
)
if not "%JDK_OK%"=="1" (
    where java >nul 2>&1
    if not errorlevel 1 (
        echo   [OK]  java found in PATH ^(JAVA_HOME not set^)
        set "JDK_OK=1"
    ) else (
        echo   [X]   JDK not found
        echo        Set JAVA_HOME or install JDK 17 ^(recommend Eclipse Temurin / Adoptium^)
    )
)

REM --- Check Android SDK via lime config (key: ANDROID_SDK) ---
for /f "delims=" %%i in ('lime config ANDROID_SDK 2^>nul') do set "LIME_SDK=%%i"
if defined LIME_SDK (
    if exist "!LIME_SDK!" (
        echo   [OK]  Android SDK = !LIME_SDK!
        set "SDK_OK=1"
    ) else (
        echo   [!!]  lime ANDROID_SDK path does not exist: !LIME_SDK!
    )
)
if not "%SDK_OK%"=="1" (
    if defined ANDROID_HOME (
        if exist "%ANDROID_HOME%" (
            echo   [OK]  Android SDK ^(ANDROID_HOME^) = %ANDROID_HOME%
            set "SDK_OK=1"
        )
    )
)
if not "%SDK_OK%"=="1" (
    if defined ANDROID_SDK_ROOT (
        if exist "%ANDROID_SDK_ROOT%" (
            echo   [OK]  Android SDK ^(ANDROID_SDK_ROOT^) = %ANDROID_SDK_ROOT%
            set "SDK_OK=1"
        )
    )
)
if not "%SDK_OK%"=="1" (
    echo   [X]   Android SDK not found
    echo        Install via Android Studio or command-line tools
    set "SETUP_NEEDED=1"
)

REM --- Check Android NDK via lime config (key: ANDROID_NDK_ROOT) ---
for /f "delims=" %%i in ('lime config ANDROID_NDK_ROOT 2^>nul') do set "LIME_NDK=%%i"
if defined LIME_NDK (
    if exist "!LIME_NDK!" (
        echo   [OK]  Android NDK = !LIME_NDK!
        set "NDK_OK=1"
    ) else (
        echo   [!!]  lime ANDROID_NDK_ROOT path does not exist: !LIME_NDK!
    )
)
if not "%NDK_OK%"=="1" (
    if defined ANDROID_NDK_HOME (
        if exist "%ANDROID_NDK_HOME%" (
            echo   [OK]  Android NDK ^(ANDROID_NDK_HOME^) = %ANDROID_NDK_HOME%
            set "NDK_OK=1"
        )
    )
)
if not "%NDK_OK%"=="1" (
    if defined ANDROID_NDK_ROOT (
        if exist "%ANDROID_NDK_ROOT%" (
            echo   [OK]  Android NDK ^(ANDROID_NDK_ROOT^) = %ANDROID_NDK_ROOT%
            set "NDK_OK=1"
        )
    )
)
if not "%NDK_OK%"=="1" (
    echo   [X]   Android NDK not found
    echo        Recommended: NDK r21e or later ^(r25c tested^)
    set "SETUP_NEEDED=1"
)

if not "%JDK_OK%"=="1" set "SETUP_NEEDED=1"

echo.

REM ============================================
REM  Interactive guided setup
REM ============================================
if "%SETUP_NEEDED%"=="1" (
    echo ============================================
    echo   BUILD ENVIRONMENT INCOMPLETE
    echo ============================================
    echo.
    echo Some required components are missing ^(marked [X] above^).
    echo.
    echo   What you need:
    echo     1. JDK 17           ^(https://adoptium.net/temurin/releases/^)
    echo     2. Android SDK      ^(via Android Studio or command-line tools^)
    echo     3. Android NDK      ^(r21e or later^)
    echo.
    echo   After installing them, run 'lime setup android' to configure paths.
    echo.

    :MENU
    echo ------------------------------------------
    echo   [1] Run 'lime setup android' now  ^(configure SDK/NDK/JDK paths^)
    echo   [2] Run setup\android.bat           ^(install haxelibs + lime setup^)
    echo   [3] Continue building anyway
    echo   [4] Back to Platform menu
    echo ------------------------------------------
    set /p "CHOICE=Select an option [1-4]: "

    if "!CHOICE!"=="1" (
        echo.
        echo Running lime setup android...
        echo Follow the prompts to enter your JDK, SDK, and NDK paths.
        echo.
        lime setup android
        echo.
        echo --- Re-checking environment ---
        goto RECHECK
    )
    if "!CHOICE!"=="2" (
        echo.
        call "%~dp0setup\android.bat"
        echo.
        echo --- Re-checking environment ---
        goto RECHECK
    )
    if "!CHOICE!"=="3" (
        echo.
        echo Continuing with build ^(this may fail if tools are missing^)...
        echo.
        goto SELECT_TYPE
    )
    if "!CHOICE!"=="4" goto PLATFORM_MENU
    echo Invalid choice. Please enter 1-4.
    echo.
    goto MENU
)

:RECHECK
set "SDK_OK=0"
set "NDK_OK=0"
set "JDK_OK=0"
set "LIME_SDK="
set "LIME_NDK="
set "LIME_JDK="

if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" set "JDK_OK=1"
)
if not "%JDK_OK%"=="1" (
    for /f "delims=" %%i in ('lime config JAVA_HOME 2^>nul') do set "LIME_JDK=%%i"
    if defined LIME_JDK if exist "!LIME_JDK!\bin\java.exe" set "JDK_OK=1"
)
if not "%JDK_OK%"=="1" (
    where java >nul 2>&1
    if not errorlevel 1 set "JDK_OK=1"
)

for /f "delims=" %%i in ('lime config ANDROID_SDK 2^>nul') do set "LIME_SDK=%%i"
if defined LIME_SDK if exist "!LIME_SDK!" set "SDK_OK=1"
if not "%SDK_OK%"=="1" if defined ANDROID_HOME if exist "%ANDROID_HOME%" set "SDK_OK=1"
if not "%SDK_OK%"=="1" if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%" set "SDK_OK=1"

for /f "delims=" %%i in ('lime config ANDROID_NDK_ROOT 2^>nul') do set "LIME_NDK=%%i"
if defined LIME_NDK if exist "!LIME_NDK!" set "NDK_OK=1"
if not "%NDK_OK%"=="1" if defined ANDROID_NDK_HOME if exist "%ANDROID_NDK_HOME%" set "NDK_OK=1"
if not "%NDK_OK%"=="1" if defined ANDROID_NDK_ROOT if exist "%ANDROID_NDK_ROOT%" set "NDK_OK=1"

echo.
echo --- Environment status ---
if "%JDK_OK%"=="1" (echo   JDK:  OK) else (echo   JDK:  MISSING)
if "%SDK_OK%"=="1" (echo   SDK:  OK) else (echo   SDK:  MISSING)
if "%NDK_OK%"=="1" (echo   NDK:  OK) else (echo   NDK:  MISSING)
echo.

if "%JDK_OK%%SDK_OK%%NDK_OK%"=="111" (
    echo All components detected.
    echo.
    goto SELECT_TYPE
)

echo Some components are still missing.
echo.
:MENU2
echo ------------------------------------------
echo   [1] Run 'lime setup android' again
echo   [2] Continue building anyway
echo   [3] Back to Platform menu
echo ------------------------------------------
set /p "CHOICE=Select an option [1-3]: "

if "!CHOICE!"=="1" (
    lime setup android
    goto RECHECK
)
if "!CHOICE!"=="2" (
    echo.
    echo Continuing with build ^(this may fail^)...
    echo.
    goto SELECT_TYPE
)
if "!CHOICE!"=="3" goto PLATFORM_MENU
echo Invalid choice.
goto MENU2

:SELECT_TYPE
echo ============================================
echo   Unknown Engine - Android Build
echo ============================================
echo.

echo   Select a build type:
echo ------------------------------------------
echo     [1] Release     - standard release build
echo     [2] Debug       - debug build with logs
echo     [3] Final       - optimized, no traces
echo     [4] Test        - release + run on device/emulator
echo     [5] Test Debug  - debug + run on device/emulator
echo     [6] Test Final  - final + run on device/emulator
echo     [7] Re-run lime setup android
echo     [0] Back
echo ------------------------------------------
set /p "BT=Select [0-7]: "

if "!BT!"=="1" set "BUILD_TYPE=release"
if "!BT!"=="2" set "BUILD_TYPE=debug"
if "!BT!"=="3" set "BUILD_TYPE=final"
if "!BT!"=="4" set "BUILD_TYPE=test"
if "!BT!"=="5" set "BUILD_TYPE=test-debug"
if "!BT!"=="6" set "BUILD_TYPE=test-final"
if "!BT!"=="7" goto RUN_SETUP
if "!BT!"=="0" goto PLATFORM_MENU
if not defined BUILD_TYPE (
    echo Invalid selection. Please enter 0-7.
    echo.
    goto SELECT_TYPE
)
goto TYPE_CONFIRMED

:RUN_SETUP
echo.
echo Re-running lime setup android...
echo Follow the prompts to enter your JDK, SDK, and NDK paths.
echo.
lime setup android
echo.
echo Setup finished. Returning to build menu...
echo.
goto SELECT_TYPE

:TYPE_CONFIRMED
echo   Build Type: %BUILD_TYPE%
echo ============================================
echo.

:BUILD
set "IS_TEST=0"
echo Starting build...
echo.

if /i "%BUILD_TYPE%"=="debug" (
    echo Building debug APK...
    lime build android -debug
) else if /i "%BUILD_TYPE%"=="final" (
    echo Building final APK - no traces, optimized...
    lime build android -final
) else if /i "%BUILD_TYPE%"=="test" (
    set "IS_TEST=1"
    echo Building release and running on device/emulator...
    lime test android -release
) else if /i "%BUILD_TYPE%"=="test-debug" (
    set "IS_TEST=1"
    echo Building debug and running on device/emulator...
    lime test android -debug
) else if /i "%BUILD_TYPE%"=="test-final" (
    set "IS_TEST=1"
    echo Building final and running on device/emulator...
    lime test android -final
) else (
    echo Building release APK...
    lime build android -release
)

if errorlevel 1 (
    echo.
    echo ============================================
    echo   BUILD FAILED
    echo ============================================
    echo.
    echo Common issues:
    echo   - Android SDK/NDK not configured: run 'lime setup android'
    echo   - JDK not found: install JDK 17 and set JAVA_HOME
    echo   - NDK version too old: use r21e or later
    echo   - Missing haxelibs: run the Haxe dependencies installer
    echo   - Gradle issues: try deleting export\release\android\bin\.gradle
    echo   - No device found ^(test mode^): connect a device or start an emulator
    echo.
) else (
    echo.
    echo ============================================
    if "!IS_TEST!"=="1" (
        echo   BUILD + RUN SUCCEEDED
    ) else (
        echo   BUILD SUCCEEDED
    )
    echo ============================================
    echo.
    echo APK location:
    echo   export\release\android\bin\app\build\outputs\apk\release\app-release.apk
    echo   ^(or debug/final depending on build type^)
    echo.
    if "!IS_TEST!"=="1" (
        echo The app was launched on your device/emulator automatically.
        echo.
    )
    echo To install manually on a connected device:
    echo   adb install -r export\release\android\bin\app\build\outputs\apk\release\app-release.apk
    echo.
)

pause
goto PLATFORM_MENU
