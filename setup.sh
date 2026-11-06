#!/usr/bin/env bash
# Hifz Ustoz: Android/iOS papkalarini yaratadi va sozlaydi (macOS / Linux).
set -e
cd "$(dirname "$0")"
flutter create --org uz.hifzustoz --project-name hifz_ustoz --platforms android,ios .
cp android_patch/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
flutter pub get
echo ""
echo "Tayyor. Planshetni ulab:   flutter run"
echo "APK yig'ish:               flutter build apk --release"
