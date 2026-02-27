@echo off
echo ==========================================
echo  Building Umrah Guide APK
echo ==========================================
set PATH=C:\flutter\bin;%PATH%
cd /d "%~dp0"

echo Getting dependencies...
flutter pub get

echo.
echo Building APK...
flutter build apk --release

echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause
