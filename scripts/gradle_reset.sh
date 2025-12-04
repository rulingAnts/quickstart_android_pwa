#!/usr/bin/env zsh

# Reset Gradle/Flutter build state for the mobile_app and attempt a debug build.
# Useful when Gradle cache or IDE state causes duplicate/phantom project errors.

set -euo pipefail

APP_DIR="${APP_DIR:-/Users/Seth/GIT/Quickstart_Android/mobile_app}"

cd "$APP_DIR"

echo "[gradle_reset] Flutter clean..."
flutter clean || true

echo "[gradle_reset] Removing Gradle and build dirs..."
rm -rf android/.gradle || true
rm -rf android/app/build || true
rm -rf build || true

echo "[gradle_reset] Re-fetching Dart deps..."
flutter pub get

echo "[gradle_reset] Stopping any Gradle daemons..."
pushd android >/dev/null
./gradlew --stop || true

echo "[gradle_reset] Assembling debug APK with stacktrace..."
./gradlew :app:assembleDebug --stacktrace
popd >/dev/null

echo "[gradle_reset] Done. You can now run: flutter run"
