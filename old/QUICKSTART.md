# Quick Start Guide - Flutter Implementation

This is a quick reference for getting the Flutter app up and running.

## 📋 Prerequisites

- Flutter SDK 3.0.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or VS Code
- Android SDK (for Android development)
- Git

## 🚀 Quick Setup (5 minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/rulingAnts/Quickstart_Android.git
cd Quickstart_Android
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# On Android emulator or connected device
flutter run
```

That's it! The app should now be running.

## 📱 First Use

### Import a Wordlist

1. **Get sample data**:
   - Use the test file: `test_data/sample_wordlist.xml` (10 words)
   - Or download real data from: https://github.com/rulingAnts/QWOM_Data

2. **Import in app**:
   - Tap "Import Wordlist"
   - Select XML file
   - Wait for import to complete

### Start Elicitation

1. Tap "Start Elicitation"
2. For each word:
   - See the English word (gloss)
   - Tap microphone to record
   - Enter transcription
   - Tap "Save & Next"

### Export Data

1. Tap "Export Data"
2. Review statistics
3. Tap "Export as ZIP"
4. Share the file

## 🔍 Common Commands

```bash
# Install dependencies
flutter pub get

# Run app (debug mode)
flutter run

# Run tests
flutter test

# Build APK (release)
flutter build apk --release

# Check for issues
flutter doctor
flutter analyze

# Format code
flutter format .
```

## 📚 Documentation

- **Main README**: Project overview and goals
- **FLUTTER_README.md**: Flutter implementation details
- **DEVELOPMENT.md**: Comprehensive development guide
- **CONTRIBUTING.md**: How to contribute

## 🛠️ Troubleshooting

### "Flutter SDK not found"
```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"
```

### "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Gradle issues
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

## 📂 Project Structure

```
Quickstart_Android/
├── lib/                    # Main app code
│   ├── main.dart          # Entry point
│   ├── models/            # Data models
│   ├── providers/         # State management
│   ├── screens/           # UI screens
│   └── services/          # Business logic
├── test/                  # Tests
├── android/               # Android config
├── test_data/             # Sample XML for testing
└── pubspec.yaml           # Dependencies
```

## 🎯 Key Features

✅ XML import (Dekereke format)
✅ SQLite database storage
✅ Audio recording (WAV)
✅ IPA transcription input
✅ Progress tracking
✅ ZIP export with audio
✅ Consent logging structure
✅ Localization ready

## 🚧 Coming Soon

- Consent screen UI
- LIFT XML export
- Image display
- Cloud sync
- Custom fonts (Charis SIL)

## 🆘 Get Help

- **Issues**: https://github.com/rulingAnts/Quickstart_Android/issues
- **Discussions**: Open an issue with `question` label
- **Documentation**: See DEVELOPMENT.md

## 🤝 Contributing

Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

Code: AGPL-3.0 (see LICENSE)
Data: Separate CC BY-NC-SA 4.0 license

---

**Ready to build?** Run `flutter run` and start collecting linguistic data! 🌍📱
