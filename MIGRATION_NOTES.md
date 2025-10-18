# Migration from Flutter to PWA

This document explains the transformation from Flutter/Dart to Progressive Web App (PWA) and provides guidance for developers.

## Overview

The project was originally started with Flutter/Dart but has been transformed into a PWA for broader accessibility and easier deployment. The Flutter code remains in the repository for reference but is not actively maintained.

## Why PWA?

### Advantages over Flutter for this use case:

1. **No Compilation Required**: Works immediately in any browser
2. **Universal Compatibility**: Runs on any device with a modern browser
3. **Easier Deployment**: No app store approval needed
4. **Instant Updates**: Changes are immediately available to users
5. **Smaller Package Size**: No framework overhead
6. **Better Web Integration**: Native browser APIs for storage, audio, etc.
7. **TWA Support**: Can still be packaged as Android app

### Trade-offs:

- Requires modern browser with web API support
- Audio format limited to browser codecs (converted to WAV)
- File access through browser APIs only
- No native iOS app packaging (but can be installed as PWA)

## Architecture Comparison

### Flutter Implementation (Old)

```
lib/
├── main.dart              # Flutter app entry
├── models/                # Data models
│   ├── wordlist_entry.dart
│   └── consent_record.dart
├── providers/             # State management
│   └── wordlist_provider.dart
├── screens/               # UI screens
│   ├── home_screen.dart
│   ├── import_screen.dart
│   ├── elicitation_screen.dart
│   └── export_screen.dart
├── services/              # Business logic
│   ├── database_service.dart  # SQLite
│   ├── xml_service.dart
│   ├── audio_service.dart
│   └── export_service.dart
└── utils/
    └── logger.dart

Dependencies:
- provider (state management)
- sqflite (database)
- file_picker (file operations)
- record/audioplayers (audio)
- xml (parsing)
- archive (ZIP)
```

### PWA Implementation (Current)

```
www/
├── index.html             # Single HTML file with all screens
├── manifest.json          # PWA manifest
├── service-worker.js      # Offline support
├── css/
│   └── styles.css         # All styles
├── js/
│   ├── app.js             # Main application logic
│   ├── storage.js         # IndexedDB wrapper
│   ├── xml-parser.js      # XML import/export
│   ├── audio-recorder.js  # Web Audio API
│   └── export.js          # JSZip export
└── icons/
    └── icon.svg           # App icon

Dependencies:
- None (vanilla JavaScript)
- JSZip (loaded via CDN for export)
```

## Feature Mapping

| Feature | Flutter Implementation | PWA Implementation |
|---------|----------------------|-------------------|
| Data Storage | SQLite (sqflite) | IndexedDB |
| State Management | Provider | Vanilla JS with events |
| Audio Recording | record package | MediaRecorder API |
| Audio Playback | audioplayers package | HTML5 Audio |
| File Picker | file_picker package | File input API |
| XML Parsing | xml package | DOMParser |
| ZIP Export | archive package | JSZip |
| Offline Support | Native | Service Worker |
| Navigation | Navigator | Screen switching |

## Key Differences

### Data Storage

**Flutter (SQLite):**
```dart
Future<int> insertWordlistEntry(WordlistEntry entry) async {
  final db = await database;
  return await db.insert('wordlist_entries', entry.toMap());
}
```

**PWA (IndexedDB):**
```javascript
async addEntry(entry) {
  const transaction = this.db.transaction(['entries'], 'readwrite');
  const store = transaction.objectStore('entries');
  return new Promise((resolve, reject) => {
    const request = store.add(entry);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}
```

### Audio Recording

**Flutter:**
```dart
final record = Record();
await record.start(path: filePath);
// ... recording
await record.stop();
```

**PWA:**
```javascript
const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
const mediaRecorder = new MediaRecorder(stream);
mediaRecorder.start();
// ... recording
mediaRecorder.stop();
```

### UI Components

**Flutter (Widgets):**
```dart
ElevatedButton.icon(
  onPressed: onPressed,
  icon: Icon(Icons.mic, size: 32),
  label: Text('Start Elicitation'),
)
```

**PWA (HTML/CSS):**
```html
<button class="main-button" id="elicitation-btn">
  <svg><!-- microphone icon --></svg>
  <span>Start Elicitation</span>
</button>
```

## Development Workflow

### Flutter Approach
1. Edit Dart code
2. Hot reload in development
3. Build APK for Android
4. Test on emulator/device
5. Distribute APK

### PWA Approach
1. Edit HTML/CSS/JS
2. Refresh browser
3. Test in browser
4. Deploy to web server
5. Optionally create TWA for Android

## Testing

### Flutter Testing
```bash
flutter test
flutter build apk
flutter run -d emulator-5554
```

### PWA Testing
```bash
# Start local server
python3 -m http.server 8000

# Open in browser
open http://localhost:8000

# Test offline mode (DevTools → Application → Service Workers)
# Test on mobile (Chrome DevTools → Device Mode)
```

## Deployment

### Flutter
- Build APK/AAB
- Sign with keystore
- Upload to Play Store
- Wait for approval

### PWA
- Upload to web server
- Instant availability
- Optional: Package with TWA
- Publish to Play Store (optional)

## Performance

### Flutter
- ✅ Native performance
- ✅ Smooth animations
- ❌ Larger package size (~20-50MB)
- ❌ Platform-specific builds

### PWA
- ✅ Fast load times
- ✅ Small package size (~100KB)
- ✅ Works across platforms
- ⚠️ Requires modern browser

## Future Considerations

### If returning to Flutter:
1. The Flutter code in `lib/` serves as a reference
2. UI patterns and data models are similar
3. Business logic can be adapted
4. Consider Flutter web target for unified codebase

### Enhancing the PWA:
1. Add more localization support
2. Implement consent screen
3. Add cloud sync option
4. Generate PNG icons
5. Optimize service worker caching
6. Add progressive enhancement features

## Maintaining Both

If you want to maintain both versions:

1. Keep Flutter code in `lib/`, `android/`, etc.
2. Keep PWA code in `www/`
3. Share test data in `test_data/`
4. Document platform-specific features
5. Keep data formats compatible (XML, audio)

## Conclusion

The PWA implementation achieves feature parity with the Flutter version while offering easier deployment and broader accessibility. The Flutter code remains available as a reference for developers who prefer native mobile development.

For most use cases, the PWA is recommended due to its simplicity and universal compatibility.
