#!/usr/bin/env zsh

# Launch selected Android emulator (if needed) and run Flutter app.
# Steps:
# 1) Prompt for emulator AVD name (interactive list if possible)
# 2) Check if it's already running via adb devices
# 3) Start emulator if not running
# 4) Wait for device to boot and then run `flutter run`

set -euo pipefail

APP_DIR="${APP_DIR:-/Users/Seth/GIT/Quickstart_Android/mobile_app}"
SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
EMULATOR_BIN="$SDK_ROOT/emulator/emulator"
ADB_BIN="$SDK_ROOT/platform-tools/adb"


command -v flutter >/dev/null 2>&1 || { echo "Error: flutter not found in PATH"; exit 1; }

if [[ ! -x "$EMULATOR_BIN" ]]; then
  echo "Error: emulator not found at $EMULATOR_BIN"
  exit 1
fi
if [[ ! -x "$ADB_BIN" ]]; then
  echo "Error: adb not found at $ADB_BIN"
  exit 1
fi

# List available AVDs
AVD_LIST=($("$EMULATOR_BIN" -list-avds))
if [[ ${#AVD_LIST[@]} -eq 0 ]]; then
  echo "No AVDs found. Please create one in Android Studio (AVD Manager)."
  exit 1
fi

echo "Available emulators:" 
for avd in $AVD_LIST; do
  echo "  - $avd"
done

# Prompt for AVD name
if [[ -z ${EMULATOR_AVD:-} ]]; then
  echo -n "Enter emulator AVD to use [default: ${AVD_LIST[1]}]: "
  read -r CHOICE
  if [[ -z "$CHOICE" ]]; then
    EMULATOR_AVD="${AVD_LIST[1]}"
  else
    EMULATOR_AVD="$CHOICE"
  fi
else
  echo "Using EMULATOR_AVD from env: $EMULATOR_AVD"
fi

# Start/refresh adb server
"$ADB_BIN" kill-server || true
"$ADB_BIN" start-server

# Check if any emulator device is running
RUNNING=$("$ADB_BIN" devices | awk '/emulator-/{print $1}')

if [[ -n "$RUNNING" ]]; then
  echo "Emulator already running: $RUNNING"
else
  echo "Starting emulator: $EMULATOR_AVD"
  # Start emulator in background
  nohup "$EMULATOR_BIN" -avd "$EMULATOR_AVD" >/dev/null 2>&1 &
fi

echo "Waiting for device to boot..."
"$ADB_BIN" wait-for-device

# Additional boot completion check (optional, tolerates devices without property)
BOOT_COMPLETE=0
for i in {1..30}; do
  boot_status=$("$ADB_BIN" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [[ "$boot_status" == "1" ]]; then
    BOOT_COMPLETE=1
    break
  fi
  sleep 2
done

if [[ $BOOT_COMPLETE -eq 1 ]]; then
  echo "Device boot completed."
else
  echo "Proceeding without sys.boot_completed confirmation (timeout)."
fi

echo "Preparing Flutter run (clearing Gradle config cache, disabling cache, setting JVM opens)..."

# Proactively clear Gradle configuration cache for this project to avoid Java 21 reflective access issues
rm -rf "$APP_DIR/.gradle/configuration-cache" || true
rm -rf "$APP_DIR/build/reports/configuration-cache" || true

cd "$APP_DIR"
flutter pub get

# Ensure Gradle runs without configuration cache and with required JVM opens for Java 21
export GRADLE_OPTS="--no-configuration-cache"
export JAVA_TOOL_OPTIONS="--add-opens=java.base/java.lang.ref=ALL-UNNAMED"

echo "Building debug APK via Gradle (no configuration cache)..."
pushd android >/dev/null
./gradlew :app:assembleDebug --stacktrace --no-configuration-cache
popd >/dev/null

APK_PATH="build/app/outputs/apk/debug/app-debug.apk"
if [[ ! -f "$APK_PATH" ]]; then
  echo "Error: APK not found at $APK_PATH"
  exit 1
fi

echo "Running Flutter with prebuilt APK: $APK_PATH"
flutter run --use-application-binary "$APK_PATH"
