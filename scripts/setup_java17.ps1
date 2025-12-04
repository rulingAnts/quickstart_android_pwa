Param(
  [string]$JdkPath
)

# This script sets Gradle to use Java 17 by updating org.gradle.java.home in gradle.properties.
# If -JdkPath is omitted, it tries common locations and then prompts.

$RepoRoot = Split-Path $PSScriptRoot -Parent
$GradleProps = Join-Path $RepoRoot "mobile_app/android/gradle.properties"

function Test-And-Set([string]$Path) {
  if (Test-Path $Path) { return $Path } else { return $null }
}

$candidates = @(
  "C:\\Program Files\\Eclipse Adoptium\\jdk-17",
  "C:\\Program Files\\Java\\jdk-17"
)

$found = $null
if ($JdkPath) {
  if (Test-Path $JdkPath) { $found = $JdkPath }
}
if (-not $found) {
  foreach ($c in $candidates) {
    $p = Test-And-Set $c
    if ($p) { $found = $p; break }
  }
}

if (-not $found) {
  Write-Host "Couldn't auto-detect JDK 17."
  $found = Read-Host "Enter your JDK 17 absolute path (e.g., C:\\Program Files\\Eclipse Adoptium\\jdk-17)"
}

if (-not (Test-Path $found)) {
  Write-Error "Provided path does not exist: $found"
  exit 1
}

# Ensure gradle.properties exists
$dir = Split-Path $GradleProps -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
if (-not (Test-Path $GradleProps)) { New-Item -ItemType File -Force -Path $GradleProps | Out-Null }

# Update org.gradle.java.home
$content = Get-Content $GradleProps -Raw
if ($content -match "^org.gradle.java.home=") {
  $content = $content -replace "^org.gradle.java.home=.*", "org.gradle.java.home=$found"
} else {
  $content = "$content`norg.gradle.java.home=$found`n"
}

# Ensure jvmargs
if ($content -match "^org.gradle.jvmargs=") {
  $content = $content -replace "^org.gradle.jvmargs=.*", "org.gradle.jvmargs=-Xmx2g -Dkotlin.daemon.jvm.options=-Xmx1g"
} else {
  $content = "$content`norg.gradle.jvmargs=-Xmx2g -Dkotlin.daemon.jvm.options=-Xmx1g`n"
}

Set-Content -Path $GradleProps -Value $content

Write-Host "Updated $GradleProps"
Write-Host "Verify with:"
Write-Host "  java -version"
Write-Host "  $RepoRoot\mobile_app\android\gradlew -v | Select-String -Pattern 'JVM' -Context 0,1"
Write-Host "If VS Code terminals use a different Java, set JAVA_HOME/Path in .vscode/settings.json as documented in README."
