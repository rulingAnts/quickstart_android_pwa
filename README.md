# Quickstart Android

## Developer Setup (Java 17 + Android/Flutter)
- Goal: Ensure all contributors build with Java 17 across macOS, Linux, and Windows. Gradle uses Java 17 via `org.gradle.java.home`, and VS Code terminals inherit the same version.

### Quick Start
- Flutter: Install Flutter SDK (3.x) and Android SDK/Studio.
- Java 17: Install Temurin or OpenJDK 17.
- Verify:
  - `java -version` shows a 17.x release (Temurin/OpenJDK).
  - `sdkmanager --list` works and shows installed Android packages.

### Project-Level Gradle JDK
- Gradle is forced to Java 17 via `mobile_app/android/gradle.properties`:
  - Set `org.gradle.java.home` to your local JDK 17 path.

Example paths:
- macOS (SDKMAN Temurin): `/Users/<you>/.sdkman/candidates/java/17.0.11-tem`
- macOS (Homebrew): `/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home`
- Linux (SDKMAN): `/home/<you>/.sdkman/candidates/java/17.0.11-tem`
- Windows (Adoptium): `C:\\Program Files\\Eclipse Adoptium\\jdk-17\\`

Edit `mobile_app/android/gradle.properties` and set:

```
org.gradle.java.home=<your JDK 17 absolute path>
org.gradle.jvmargs=-Xmx2g -Dkotlin.daemon.jvm.options=-Xmx1g
```

Notes:
- Do not put Gradle CLI flags (e.g., `--no-configuration-cache`) into JVM args.
- Avoid `JAVA_TOOL_OPTIONS` unless you know exactly why you need it.

### VS Code Terminal Environment (Optional)
- To make VS Code use Java 17 in integrated terminals:
  - Create or edit `.vscode/settings.json` with:

```
{
  "terminal.integrated.env.osx": {
    "JAVA_HOME": "/Users/<you>/.sdkman/candidates/java/17.0.11-tem",
    "PATH": "/Users/<you>/.sdkman/candidates/java/17.0.11-tem/bin:${env:PATH}"
  },
  "terminal.integrated.env.linux": {
    "JAVA_HOME": "/home/<you>/.sdkman/candidates/java/17.0.11-tem",
    "PATH": "/home/<you>/.sdkman/candidates/java/17.0.11-tem/bin:${env:PATH}"
  },
  "terminal.integrated.env.windows": {
    "JAVA_HOME": "C:\\Program Files\\Eclipse Adoptium\\jdk-17",
    "Path": "C:\\Program Files\\Eclipse Adoptium\\jdk-17\\bin;${env:Path}"
  }
}
```

### Helper Scripts
- We provide scripts under `scripts/` to help set Java 17 and validate the setup:
  - macOS/Linux: `scripts/setup_java17.sh`
  - Windows PowerShell: `scripts/setup_java17.ps1`

Run them from the repo root.

macOS/Linux:

```
bash scripts/setup_java17.sh
```

Windows (PowerShell):

```
PowerShell -ExecutionPolicy Bypass -File scripts/setup_java17.ps1
```

What they do:
- Detect common JDK 17 install locations.
- Prompt for your path if auto-detect fails.
- Update `mobile_app/android/gradle.properties` with `org.gradle.java.home`.
- Print verification commands.

### Build/Run
- Use the provided VS Code task: `Android: Build Debug (Java 17) + Run`.
- Or run manually:

```
pushd mobile_app
flutter pub get
flutter build apk --debug
flutter run
popd
```

If Gradle complains about JDK version, re-check `org.gradle.java.home` and your terminal `JAVA_HOME`.

### Troubleshooting
- Wrong Java version picked:
  - Ensure `org.gradle.java.home` points to 17.
  - Clear `JAVA_TOOL_OPTIONS` if set: `unset JAVA_TOOL_OPTIONS` (macOS/Linux) or `Remove-Item Env:JAVA_TOOL_OPTIONS` (Windows PowerShell).
- Configuration cache issues:
  - Temporarily disable via CLI: `./gradlew :app:assembleDebug --no-configuration-cache`.
- Android SDK not found:
  - Set `ANDROID_HOME`/`ANDROID_SDK_ROOT` and ensure required packages via `sdkmanager --list`.
