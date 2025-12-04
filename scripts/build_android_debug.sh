#!/usr/bin/env zsh
set -e

# Prefer project-level Gradle JDK (org.gradle.java.home). Avoid overriding JAVA_HOME here.
# If you must override locally, uncomment the lines below and set to your JDK17 path.
# export JAVA_HOME="$('/usr/libexec/java_home' -v 17)"
# export PATH="$JAVA_HOME/bin:$PATH"

pushd mobile_app/android >/dev/null

echo "Cleaning Gradle build…"
./gradlew clean

echo "Assembling Debug APK (verifying Java 17; config cache disabled)…"
JVM_INFO=$(./gradlew -v | grep -i 'JVM' -A1 || true)
echo "$JVM_INFO"
./gradlew :app:assembleDebug --stacktrace --no-configuration-cache

APK_PATH="../build/app/outputs/apk/debug/app-debug.apk"
popd >/dev/null

echo "Running Flutter with prebuilt APK…"
pushd mobile_app >/dev/null
flutter run --use-application-binary "$APK_PATH"
popd >/dev/null

echo "Done."
