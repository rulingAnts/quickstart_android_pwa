# 📱 Flutter App Navigation Guide

## 🎯 Start Here

**New to this project?** → Read [QUICKSTART.md](QUICKSTART.md) (5-minute setup)

**Ready to develop?** → See [DEVELOPMENT.md](DEVELOPMENT.md) (complete guide)

**Want to contribute?** → Check [CONTRIBUTING.md](CONTRIBUTING.md)

## 📚 Documentation Map

```
┌─────────────────────────────────────────────────────────┐
│                    📖 Documentation                     │
└─────────────────────────────────────────────────────────┘

START HERE:
  ├─ QUICKSTART.md       ⚡ 5-minute setup guide
  └─ README.md           📋 Project overview & goals

DEVELOPMENT:
  ├─ DEVELOPMENT.md      🛠️  Complete development guide
  ├─ ARCHITECTURE.md     🏗️  System design & patterns
  └─ FLUTTER_README.md   📱 Flutter-specific details

CONTRIBUTING:
  ├─ CONTRIBUTING.md     🤝 How to contribute
  ├─ CHANGELOG.md        📝 Version history
  └─ SUMMARY.md          ✅ Implementation summary
```

## 🗂️ Code Organization

```
lib/
├─ 🎯 main.dart           App entry point
│
├─ 📦 models/             Data structures
│   ├─ wordlist_entry.dart
│   └─ consent_record.dart
│
├─ 🔄 providers/          State management
│   └─ wordlist_provider.dart
│
├─ 📱 screens/            UI screens
│   ├─ home_screen.dart
│   ├─ import_screen.dart
│   ├─ elicitation_screen.dart
│   └─ export_screen.dart
│
├─ ⚙️  services/          Business logic
│   ├─ database_service.dart
│   ├─ xml_service.dart
│   ├─ audio_service.dart
│   └─ export_service.dart
│
├─ 🎨 widgets/            Reusable components (ready)
└─ 🔧 utils/              Helpers & constants (ready)
```

## 🚦 Quick Commands

```bash
# Setup
flutter pub get              # Install dependencies

# Development
flutter run                  # Run app (debug mode)
flutter run --release        # Run app (release mode)

# Testing
flutter test                 # Run all tests
flutter analyze              # Check code quality
flutter format .             # Format code

# Building
flutter build apk            # Build Android APK
flutter build appbundle      # Build Android App Bundle
```

## 🎬 User Flow

```
┌─────────────┐
│  Home       │  → View progress statistics
│  Screen     │  → Choose action
└─────────────┘
       ↓
    ┌──┴───────────┐
    ↓              ↓              ↓
┌─────────┐  ┌─────────────┐  ┌──────────┐
│ Import  │  │ Elicitation │  │  Export  │
│ Screen  │  │   Screen    │  │  Screen  │
└─────────┘  └─────────────┘  └──────────┘
    ↓              ↓              ↓
  XML File    Record + Text    ZIP Archive
```

## 📁 Important Files

### Configuration
- `pubspec.yaml` - Dependencies & metadata
- `analysis_options.yaml` - Linting rules
- `.gitignore` - Git ignore patterns

### Android
- `android/app/src/main/AndroidManifest.xml` - Permissions
- `android/app/build.gradle` - Build config
- `android/app/src/main/kotlin/.../MainActivity.kt` - Entry point

### Testing
- `test/models_test.dart` - Unit tests
- `test_data/sample_wordlist.xml` - Sample data

## 🔍 Find What You Need

### "I want to..."

**...set up the project**
→ [QUICKSTART.md](QUICKSTART.md)

**...understand the architecture**
→ [ARCHITECTURE.md](ARCHITECTURE.md)

**...add a new feature**
→ [DEVELOPMENT.md](DEVELOPMENT.md) + [CONTRIBUTING.md](CONTRIBUTING.md)

**...fix a bug**
→ [CONTRIBUTING.md](CONTRIBUTING.md) (Bug reporting section)

**...understand the data flow**
→ [ARCHITECTURE.md](ARCHITECTURE.md) (Data Flow section)

**...add a new dependency**
→ [DEVELOPMENT.md](DEVELOPMENT.md) (Adding Dependencies)

**...write tests**
→ [DEVELOPMENT.md](DEVELOPMENT.md) (Testing section)

**...understand the XML format**
→ [FLUTTER_README.md](FLUTTER_README.md) (XML Format section)

**...deploy the app**
→ [DEVELOPMENT.md](DEVELOPMENT.md) (Building for Release)

**...understand licensing**
→ [README.md](README.md) (Licensing section)

## 🎓 Learning Path

### Beginner (New to Flutter)
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Install Flutter & dependencies
3. Run the app: `flutter run`
4. Explore `lib/screens/` to see UI
5. Check `lib/models/` for data structures

### Intermediate (Know Flutter)
1. Review [ARCHITECTURE.md](ARCHITECTURE.md)
2. Study service layer in `lib/services/`
3. Understand state management in `lib/providers/`
4. Read unit tests in `test/`
5. Build and test: `flutter build apk`

### Advanced (Ready to Contribute)
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Pick an issue from GitHub
3. Review [CHANGELOG.md](CHANGELOG.md) for roadmap
4. Fork, develop, test, PR
5. Check [DEVELOPMENT.md](DEVELOPMENT.md) for best practices

## 🏆 Feature Checklist

### ✅ Implemented (MVP)
- [x] XML import (Dekereke)
- [x] SQLite storage
- [x] Audio recording (WAV)
- [x] IPA transcription input
- [x] Progress tracking
- [x] ZIP export
- [x] Consent logging (structure)

### 🚧 In Progress / Planned
- [ ] Consent screen UI
- [ ] LIFT XML export
- [ ] Image display
- [ ] Cloud sync
- [ ] Custom fonts
- [ ] iOS support

See [CHANGELOG.md](CHANGELOG.md) for full roadmap.

## 🆘 Getting Help

### Issues
Open an issue on GitHub with:
- `question` label for questions
- `bug` label for bugs
- `enhancement` label for features

### Resources
- Flutter Docs: https://flutter.dev/docs
- Dart Language: https://dart.dev
- Project Discussions: GitHub Issues

## 📊 Project Stats

- **Dart Files**: 12
- **Lines of Code**: ~1,600
- **Documentation Files**: 8
- **Test Coverage**: Models tested
- **Platforms**: Android (iOS ready)
- **Dependencies**: 12 packages
- **License**: AGPL-3.0

## 🌟 Key Highlights

1. **Clean Architecture** - Separation of concerns
2. **Well-Documented** - 8 comprehensive docs
3. **Tested** - Unit tests included
4. **Accessible** - High-contrast, simple UI
5. **Ethical** - Consent logging built-in
6. **Offline-First** - No internet required
7. **Open Source** - AGPL-3.0 licensed

## 📞 Contact & Support

- **GitHub**: Open an issue
- **Email**: Check repository owner
- **Community**: GitHub Discussions (coming soon)

---

## Next Steps

1. ⚡ Quick start: [QUICKSTART.md](QUICKSTART.md)
2. 🛠️ Development: [DEVELOPMENT.md](DEVELOPMENT.md)
3. 🤝 Contribute: [CONTRIBUTING.md](CONTRIBUTING.md)
4. 📱 Deploy: Build and test the app!

Happy coding! 🚀
