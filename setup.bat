@echo off
REM Hifz Ustoz: Android papkasini yaratadi va sozlaydi (Windows).
cd /d "%~dp0"
call flutter create --org uz.hifzustoz --project-name hifz_ustoz --platforms android .
copy /Y android_patch\AndroidManifest.xml android\app\src\main\AndroidManifest.xml
call flutter pub get
echo.
echo Tayyor. Planshetni ulab:   flutter run
echo APK yig%sish:              flutter build apk --release
pause
