# Wordlist Elicitation Tool - Flutter Android App

A native Android application for linguistic fieldwork, implementing the Wordlist Elicitation Tool with enhanced features.

## Features

- **Import Wordlist**: Load XML wordlists from local files or URLs
  - Supports UTF-8, UTF-16LE, and UTF-16BE encodings
  - Auto-detects BOM and handles encoding issues gracefully
  - Normalizes reference numbers to 4-digit format
  - Sorts entries by numeric reference

- **Elicitation**: Record and transcribe words
  - 16-bit PCM WAV audio recording at 44.1kHz
  - Local transcription input
  - "All Entries" panel with search and jump functionality
  - Resumes from last position on app restart

- **Export**: Create ZIP archives with all data
  - UTF-16LE encoded XML with single BOM
  - Audio files in WAV format
  - Metadata JSON with statistics

## Project Structure

```
mobile_app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/
│   │   ├── home_screen.dart      # Home with stats and navigation
│   │   ├── import_screen.dart    # File/URL import
│   │   ├── elicitation_screen.dart # Recording and transcription
│   │   └── export_screen.dart    # ZIP export
│   ├── services/
│   │   ├── storage_service.dart  # Hive-based persistence
│   │   ├── xml_service.dart      # XML parsing and generation
│   │   ├── audio_service.dart    # Recording and playback
│   │   └── export_service.dart   # ZIP creation
│   ├── models/
│   │   ├── entry.dart           # Entry data model
│   │   └── entry.g.dart         # Hive adapter
│   └── utils/
│       ├── filename.dart        # Filename utilities
│       └── encoding.dart        # Encoding helpers
├── android/                   # Android configuration
├── test/                      # Unit tests
├── pubspec.yaml              # Dependencies
└── README.md                 # This file
```

## Setup

### Prerequisites

- Flutter SDK 3.9.2 or later
- Android Studio or VS Code with Flutter extensions
- Android device or emulator (API 21+)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/rulingAnts/quickstart_android_pwa.git
   cd quickstart_android_pwa/mobile_app
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Running Tests

```bash
cd mobile_app
flutter test
```

### Test Files

- `test/filename_test.dart` - Filename slugification and formatting
- `test/bom_test.dart` - UTF-16LE BOM prefix validation
- `test/wav_header_test.dart` - 16-bit PCM WAV header validation

## Dependencies

- **hive/hive_flutter**: Local database storage
- **path_provider**: App documents directory access
- **shared_preferences**: Simple key-value persistence
- **xml**: XML parsing
- **http**: URL fetching
- **file_picker**: File selection
- **record**: Audio recording
- **audioplayers**: Audio playback
- **permission_handler**: Microphone permissions
- **archive**: ZIP file creation

## Permissions

The app requires the following Android permissions:

- `RECORD_AUDIO` - For recording audio
- `INTERNET` - For URL-based import

## XML Schema

### Import (Flexible)

Accepts various XML formats with tolerant parsing:
- `<Word>`, `<Entry>`, `<Item>`, `<data_form>` elements
- Reference, Gloss, Picture fields with various naming conventions

### Export (Strict)

Exports using the `<phon_data>/<data_form>` schema:

```xml
<?xml version="1.0" encoding="UTF-16"?>
<phon_data>
  <data_form>
    <Reference>0001</Reference>
    <Gloss>body</Gloss>
    <LocalTranscription>soma</LocalTranscription>
    <SoundFile>0001_body.wav</SoundFile>
    <RecordedAt>2025-12-03T10:30:00.000Z</RecordedAt>
  </data_form>
</phon_data>
```

The XML is encoded as UTF-16LE with a single BOM (FF FE) prefix.

## Audio Format

- **Recording**: Mono, 44.1kHz, 16-bit PCM WAV
- **Filename**: `{reference}_{slugified_gloss}.wav`
  - Reference padded to 4 digits
  - Gloss slugified (lowercase, spaces to dots, max 64 chars)
  - Example: `0001_body.wav`

## License

MIT License
