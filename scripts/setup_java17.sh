#!/usr/bin/env bash
set -euo pipefail

# This script helps configure Gradle to use Java 17 by setting org.gradle.java.home
# It tries to auto-detect common JDK 17 locations, otherwise prompts for a path.

REPO_ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
GRADLE_PROPERTIES="$REPO_ROOT_DIR/mobile_app/android/gradle.properties"

candidates=(
  "$HOME/.sdkman/candidates/java/17.0.11-tem"
  "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  "/usr/lib/jvm/java-17-openjdk"
)

found=""
for c in "${candidates[@]}"; do
  if [[ -d "$c" ]]; then
    found="$c"
    break
  fi
done

if [[ -z "$found" ]]; then
  echo "Couldn't auto-detect JDK 17."
  read -r -p "Enter your JDK 17 absolute path (e.g., /Users/you/.sdkman/candidates/java/17.0.11-tem): " found
fi

if [[ ! -d "$found" ]]; then
  echo "Provided path does not exist: $found" >&2
  exit 1
fi

# Ensure gradle.properties exists
mkdir -p "$(dirname "$GRADLE_PROPERTIES")"
if [[ ! -f "$GRADLE_PROPERTIES" ]]; then
  touch "$GRADLE_PROPERTIES"
fi

# Update org.gradle.java.home (replace or append)
if grep -q '^org.gradle.java.home=' "$GRADLE_PROPERTIES"; then
  sed -i.bak "s#^org.gradle.java.home=.*#org.gradle.java.home=$found#" "$GRADLE_PROPERTIES"
else
  printf "\norg.gradle.java.home=%s\n" "$found" >> "$GRADLE_PROPERTIES"
fi

# Ensure reasonable jvmargs
if grep -q '^org.gradle.jvmargs=' "$GRADLE_PROPERTIES"; then
  sed -i.bak "s#^org.gradle.jvmargs=.*#org.gradle.jvmargs=-Xmx2g -Dkotlin.daemon.jvm.options=-Xmx1g#" "$GRADLE_PROPERTIES"
else
  printf "org.gradle.jvmargs=-Xmx2g -Dkotlin.daemon.jvm.options=-Xmx1g\n" >> "$GRADLE_PROPERTIES"
fi

rm -f "$GRADLE_PROPERTIES.bak"

echo "Updated $GRADLE_PROPERTIES"

echo "Verify with:"
echo "  java -version"
echo "  "$REPO_ROOT_DIR"/mobile_app/android/gradlew -v | grep -i 'jvm' -A1 || true"
echo "If VS Code terminals use a different Java, set JAVA_HOME/PATH in .vscode/settings.json as documented in README."
