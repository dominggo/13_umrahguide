@echo off
cd /d "%~dp0"

for /f "tokens=2 delims=: " %%v in ('findstr "^version:" pubspec.yaml') do set VERSION=%%v

echo ========================================
echo   PANDUAN UMRAH - BUILD TOOL
echo ========================================
echo.
echo   Version : %VERSION%
echo.
echo   [1] Debug   ^| "Panduan Umrah dev" ^| com.faeq.umrahmas.dev
echo   [2] Release ^| "Panduan Umrah"     ^| com.faeq.umrahmas
echo.
set /p CHOICE="Select [1/2]: "

if "%CHOICE%"=="1" goto debug
if "%CHOICE%"=="2" goto release
echo Invalid choice.
pause & exit /b

:debug
echo.
echo Building DEBUG APK...
call flutter build apk --debug
if %errorlevel%==0 echo. & echo Output: %~dp0build\app\outputs\flutter-apk\app-debug.apk
pause & exit /b

:release
echo.
echo Building RELEASE APK...
call flutter build apk --release
if %errorlevel%==0 echo. & echo Output: %~dp0build\app\outputs\flutter-apk\app-release.apk
pause & exit /b
