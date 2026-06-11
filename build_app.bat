@echo off
chcp 65001 >nul
cd /d "c:\Users\Admin\Documents\GitHub\Parentpeak"

echo [BUILD] Cleaning Flutter...
call flutter clean

echo [BUILD] Getting dependencies offline...
call flutter pub get --offline

echo [BUILD] Building APK...
call flutter build apk --no-pub --release

if exist "build\app\outputs\apk\release\app-release.apk" (
    echo [SUCCESS] APK built successfully!
    echo [APK] Location: build\app\outputs\apk\release\app-release.apk
    pause
) else (
    echo [ERROR] APK build failed!
    pause
)
