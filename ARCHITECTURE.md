# Architecture Overview

This document provides a high-level overview of the Flutter app architecture.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer (Flutter)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │   Home   │  │  Import  │  │Elicitation│ │  Export  │    │
│  │  Screen  │  │  Screen  │  │  Screen   │ │  Screen  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│       │              │              │              │         │
└───────┼──────────────┼──────────────┼──────────────┼─────────┘
        │              │              │              │
        └──────────────┴──────────────┴──────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   State Management Layer                     │
│                     (Provider Pattern)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           WordlistProvider (ChangeNotifier)         │   │
│  │  • Current entry index                              │   │
│  │  • Entry list                                       │   │
│  │  • Progress tracking                                │   │
│  │  • Entry updates                                    │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Service Layer                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  Database  │  │    XML     │  │   Audio    │            │
│  │  Service   │  │  Service   │  │  Service   │            │
│  └────────────┘  └────────────┘  └────────────┘            │
│  ┌────────────┐                                             │
│  │   Export   │                                             │
│  │  Service   │                                             │
│  └────────────┘                                             │
└──────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                     Data Layer                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │   SQLite   │  │ File System│  │   Models   │            │
│  │  Database  │  │(Audio/XML) │  │            │            │
│  └────────────┘  └────────────┘  └────────────┘            │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Import Flow
```
User selects XML → XmlService → Parse XML → DatabaseService → SQLite
                                                    ↓
                                            WordlistProvider
                                                    ↓
                                              Update UI
```

### 2. Elicitation Flow
```
User records audio → AudioService → Save WAV file
User enters text   → UI Controller → WordlistProvider
                                           ↓
                                    DatabaseService
                                           ↓
                                        SQLite
```

### 3. Export Flow
```
ExportService → DatabaseService → Get all entries
              → AudioService    → Get audio files
              → XmlService      → Generate XML
              → Archive         → Create ZIP
              → File System     → Save/Share
```

## Component Responsibilities

### Models (`lib/models/`)
- **WordlistEntry**: Represents a single word in the wordlist
- **ConsentRecord**: Ethical consent information

**Characteristics**:
- Pure data structures
- No business logic
- Serialization methods (toMap/fromMap)

### Services (`lib/services/`)

#### DatabaseService
- SQLite database management
- CRUD operations for entries and consent
- Query utilities

#### XmlService
- Parse Dekereke XML format
- Generate XML exports
- Handle encoding (UTF-16 for Dekereke, UTF-8 for LIFT)

#### AudioService
- Audio recording (WAV format)
- Playback functionality
- File naming convention
- Permission handling

#### ExportService
- Aggregate data from database
- Package audio files
- Create consent logs
- Generate ZIP archives

### Providers (`lib/providers/`)

#### WordlistProvider
- Manages app state using ChangeNotifier
- Tracks current entry
- Handles navigation between entries
- Updates entry completion status
- Notifies UI of changes

### Screens (`lib/screens/`)

#### HomeScreen
- Entry point after app launch
- Display progress statistics
- Navigate to Import/Elicitation/Export

#### ImportScreen
- File picker integration
- XML validation and import
- Progress feedback

#### ElicitationScreen
- Display current word
- Audio recording controls
- IPA transcription input
- Navigation between entries

#### ExportScreen
- Summary statistics
- Export trigger
- Share functionality

## Key Design Patterns

### 1. Service Pattern
Encapsulates business logic and external integrations.

```dart
class SomeService {
  Future<Result> doSomething() async {
    // Business logic here
  }
}
```

### 2. Provider Pattern (State Management)
Manages and notifies UI of state changes.

```dart
class SomeProvider extends ChangeNotifier {
  void updateState() {
    // Update internal state
    notifyListeners(); // Trigger UI rebuild
  }
}
```

### 3. Repository Pattern (Database)
Abstracts data access layer.

```dart
class DatabaseService {
  Future<List<Entry>> getAll() async {
    // Database query
  }
}
```

## Dependencies Overview

### Core
- `flutter` - UI framework
- `provider` - State management

### Data & Storage
- `sqflite` - SQLite database
- `path_provider` - File system paths
- `xml` - XML parsing

### Media
- `record` - Audio recording
- `audioplayers` - Audio playback
- `permission_handler` - Permissions

### File Operations
- `file_picker` - File selection
- `archive` - ZIP creation
- `share_plus` - File sharing

### Localization
- `flutter_localizations` - Built-in localizations
- `intl` - Internationalization

## Database Schema

### wordlist_entries
```sql
CREATE TABLE wordlist_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reference TEXT NOT NULL,           -- e.g., "0001"
  gloss TEXT NOT NULL,               -- e.g., "body"
  local_transcription TEXT,          -- IPA transcription
  audio_filename TEXT,               -- e.g., "0001body.wav"
  picture_filename TEXT,             -- Optional image
  recorded_at TEXT,                  -- ISO 8601 timestamp
  is_completed INTEGER DEFAULT 0     -- Boolean (0 or 1)
)
```

### consent_records
```sql
CREATE TABLE consent_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,           -- ISO 8601 timestamp
  device_id TEXT NOT NULL,           -- Unique device identifier
  type TEXT NOT NULL,                -- "verbal" or "written"
  response TEXT NOT NULL,            -- "assent" or "decline"
  verbal_consent_filename TEXT       -- Optional audio file
)
```

## File Structure

### Runtime Files
```
Application Directory/
├── databases/
│   └── wordlist_elicitation.db    # SQLite database
├── audio/
│   ├── 0001body.wav               # Audio recordings
│   ├── 0002head.wav
│   └── ...
└── wordlist_export_TIMESTAMP.zip  # Export package
```

### Export Package Structure
```
wordlist_export_TIMESTAMP.zip
├── README.txt                      # Export metadata
├── wordlist_data.xml              # Dekereke XML
├── consent_log.json               # Consent records
└── audio/
    ├── 0001body.wav
    ├── 0002head.wav
    └── ...
```

## Security & Privacy

### Permissions (Android)
- `RECORD_AUDIO` - Required for audio recording
- `READ_EXTERNAL_STORAGE` - File access (Android < 13)
- `WRITE_EXTERNAL_STORAGE` - File storage (Android < 13)
- `READ_MEDIA_AUDIO` - Media access (Android 13+)

### Data Protection
- All data stored locally on device
- No automatic cloud sync (user-initiated export only)
- Consent records included in exports
- Separate licensing for code (AGPL-3.0) and data (CC BY-NC-SA 4.0)

## Future Architecture Considerations

### Phase 2 Additions

1. **Consent Module**
   - Dedicated consent screen
   - Verbal consent recording
   - Written consent display

2. **Image Module**
   - Image loading and caching
   - Picture display in elicitation

3. **Cloud Sync Module**
   - Optional cloud storage
   - Background sync
   - Conflict resolution

4. **Advanced Export**
   - LIFT XML format
   - Multiple export formats
   - Batch operations

## Testing Strategy

### Unit Tests
- Models: Serialization, validation
- Services: Business logic
- Utilities: Helper functions

### Widget Tests
- Screen rendering
- User interactions
- State updates

### Integration Tests
- Full user workflows
- Database operations
- File operations

## Performance Considerations

1. **Database Queries**: Use indexed columns for lookups
2. **Audio Files**: Stream large files, don't load entirely
3. **UI Updates**: Minimize rebuilds with proper Provider usage
4. **Memory**: Dispose controllers and streams properly

## Error Handling

### Levels
1. **Service Level**: Catch and log errors
2. **Provider Level**: Convert to user-friendly messages
3. **UI Level**: Display error dialogs/snackbars

### Example
```dart
try {
  await service.doSomething();
} catch (e) {
  print('Service error: $e');
  throw Exception('User-friendly message');
}
```

---

For implementation details, see:
- **DEVELOPMENT.md** - Development guide
- **FLUTTER_README.md** - Feature details
- **Source code** - In-line documentation
