@echo off
echo ==========================================
echo  Umrah Guide - Flutter App Setup
echo ==========================================
echo.

:: Add Flutter to PATH for this session
set PATH=C:\flutter\bin;%PATH%

:: Check Flutter installation
flutter --version
if errorlevel 1 (
    echo ERROR: Flutter not found at C:\flutter
    echo Please ensure Flutter SDK is installed at C:\flutter
    pause
    exit /b 1
)

echo.
echo Getting dependencies...
cd /d "%~dp0"
flutter pub get

echo.
echo Checking devices...
flutter devices

echo.
echo ==========================================
echo  Run options:
echo   flutter run          - Run on connected device
echo   flutter build apk    - Build release APK
echo   flutter build apk --debug  - Build debug APK
echo ==========================================
echo.
pause
