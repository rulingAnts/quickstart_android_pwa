# PWA Architecture Documentation and Generation Prompts

**Date:** December 3, 2025  
**Project:** Wordlist Elicitation Tool PWA  
**Location:** `/old/www/`

---

## Table of Contents

1. [How the Old PWA Works](#how-the-old-pwa-works)
2. [Prompt A: Recreate Old App Verbatim](#prompt-a-recreate-old-app-verbatim)
3. [Prompt B: Regenerate with Improvements](#prompt-b-regenerate-with-improvements)
4. [Next Steps](#next-steps)

---

## How the Old PWA Works

### Stack and Structure

The PWA is a single-page application built with vanilla HTML/CSS/JavaScript:

- **`index.html`**: Hosts four screens (Home, Import, Elicitation, Export) and boots all scripts
- **`js/app.js`**: Main controller handling screen navigation, event wiring, and application flows
- **`js/storage.js`**: Wraps IndexedDB (entries, audio blobs, consent log) and localStorage for simple settings
- **`js/xml-parser.js`**: Parses tolerant "Dekereke-style" XML and generates XML on export
- **`js/audio-recorder.js`**: Records via MediaRecorder and converts to 16-bit PCM WAV via Web Audio API
- **`js/export.js`**: Bundles everything with JSZip (loaded from CDN) and triggers client-side download
- **`service-worker.js`**: Provides offline caching
- **`manifest.json`**: Describes the PWA metadata

### Data Model

**Entry** (stored in `entries` store with autoincrement `id`):
```javascript
{
  id: number,                    // Auto-generated
  reference: string,             // Padded to 4 digits if missing
  gloss: string,                 // Required
  localTranscription: string,    // User input
  audioFilename: string | null,  // Generated: ${reference}_${gloss}.wav
  pictureFilename: string,       // Optional, from XML
  recordedAt: string | null,     // ISO timestamp
  isCompleted: boolean           // true if transcription OR audio exists
}
```

**Audio blobs** (stored in `audio` store with `filename` as key):
```javascript
{
  filename: string,
  blob: Blob
}
```

**Consent records** (stored in `consent` with autoincrement `id`, indexed by `timestamp`):
```javascript
{
  id: number,
  timestamp: string,
  deviceId: string,
  type: string,
  response: string,
  verbalConsentFilename: string | null
}
```

### Screens and UX Flow

#### Home Screen
- **Stats Display**: Total entries, Completed (has transcription or audio), Remaining
- **Buttons**:
  - Import Wordlist (always enabled)
  - Start Elicitation (disabled until entries exist)
  - Export Data (disabled until entries exist)

#### Import Screen
- File input for XML selection
- Inline status messages (processing/success/error)
- **Flow**:
  1. Read file as text
  2. Parse with `xmlParser.parseWordlist()`
  3. Clear existing entries
  4. Add all new entries
  5. Return to home after 2 seconds on success

#### Elicitation Screen
- **Display**:
  - Reference number (4 digits)
  - Gloss (English word)
  - Optional picture (if provided in XML)
  - Text input for "Local Transcription"
  - Record/Stop toggle button
  - Play button (hidden until audio exists)
  - Previous/Next navigation with "X / N" counter
- **Flow**:
  - Transcription updates in-memory entry on input
  - Record captures audio and converts to WAV
  - Audio saved with filename: `${reference}_${gloss.replace(/\s+/g, '.')}.wav`
  - Navigation saves current entry before moving
  - Back button saves and returns to home

#### Export Screen
- **Stats**: Total entries, Completed, With Audio
- Export ZIP button
- Inline status messages
- **Output**: ZIP containing wordlist.xml, audio/, consent_log.json (if exists), metadata.json

### Import Flow

**`app.js` → `handleFileSelect()`**:
1. Reads file text
2. Calls `xmlParser.parseWordlist(text)`
3. Throws error if no entries found
4. Clears `entries` store
5. Adds each parsed entry (no sorting applied)
6. Reloads entries and updates Home stats

**`xml-parser.js` Parsing Strategy**:
- **Tolerant element detection**: Searches for Word/Entry/Item/word/entry/item/data_form; falls back to root children if none match
- **Field extraction per entry**:
  - `reference`: From Reference/Ref/Number/... variants, defaults to generated 4-digit number if missing
  - `gloss`: From Gloss/English/Word/... variants (required)
  - `pictureFilename`: From Picture/Image variants
  - Initializes: `localTranscription` = "", `audioFilename` = null, `recordedAt` = null, `isCompleted` = false

**Export XML format**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Wordlist>
  <Word>
    <Reference>0001</Reference>
    <Gloss>body</Gloss>
    <LocalTranscription>soma</LocalTranscription>
    <SoundFile>0001_body.wav</SoundFile>
    <Picture>images/body.jpg</Picture>
    <RecordedAt>2025-12-03T10:30:00.000Z</RecordedAt>
  </Word>
</Wordlist>
```

**Limitations**:
- No schema enforcement
- No numeric sorting of references
- No online import capability
- UTF-8 encoding only (no BOM)

### Elicitation Flow

**Entry Display**:
- Binds current entry values to DOM elements
- Toggles picture visibility based on presence
- Enables/disables Previous/Next based on bounds
- Shows Play button only if `audioFilename` exists

**Transcription**:
- Updates in-memory entry's `localTranscription` on input
- Saved on navigation or back action

**Recording Process**:

1. **Start** (`audioRecorder.startRecording()`):
   - Requests microphone with `getUserMedia`: mono, 44.1kHz, echo/noise suppression
   - Creates MediaRecorder with supported MIME type priority:
     - `audio/webm;codecs=opus`
     - `audio/webm`
     - `audio/ogg;codecs=opus`
     - `audio/mp4`
     - Default fallback
   - Collects data chunks
   - Updates UI to "recording" state

2. **Stop** (`audioRecorder.stopRecording()`):
   - Creates Blob from collected chunks
   - Attempts WAV conversion via Web Audio API:
     - Decodes audio data with `decodeAudioData()`
     - Converts to 16-bit PCM WAV format
     - Writes proper WAV header (RIFF, fmt, data chunks)
   - Falls back to original blob if conversion fails

3. **Save** (`saveAudio()`):
   - Generates filename: `${reference.padStart(4, '0')}_${gloss.replace(/\s+/g, '.')}.wav`
   - Stores blob in `audio` IndexedDB store
   - Updates entry with `audioFilename` and `recordedAt` timestamp
   - Marks entry as completed

**Completion Logic**:
```javascript
entry.isCompleted = (entry.localTranscription && entry.localTranscription.trim() !== '') 
                    || (entry.audioFilename !== null);
```

**Limitations**:
- No resume-last-position feature (always starts at index 0)
- Minimal filename sanitization (only spaces → dots)
- No validation of audio format support before recording

### Playback

**Flow**:
1. If current session has fresh audio blob → use that
2. Else load blob by filename from `audio` store
3. Create object URL and play via `new Audio(url)`
4. Revoke URL on playback end

### Export Flow

**`exportManager.exportData()` Process**:

1. **Setup**:
   - Lazy-loads JSZip from CDN: `https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js`
   - Creates new ZIP instance

2. **Content Generation**:
   - **wordlist.xml**: Generated from `xmlParser.generateXML(entries)` (UTF-8, no BOM)
   - **audio/**: Folder containing all audio blobs with stored filenames
   - **consent_log.json**: Only if consent records exist
     ```json
     {
       "generatedAt": "2025-12-03T10:30:00.000Z",
       "records": [...]
     }
     ```
   - **metadata.json**:
     ```json
     {
       "exportedAt": "2025-12-03T10:30:00.000Z",
       "appVersion": "1.0.0",
       "totalEntries": 200,
       "completedEntries": 45,
       "entriesWithAudio": 40,
       "entriesWithTranscription": 38
     }
     ```

3. **Compression**:
   - DEFLATE compression level 6
   - Generates blob asynchronously

4. **Download**:
   - Creates timestamped filename: `wordlist_export_YYYYMMDD_HHMMSS.zip`
   - Triggers download via anchor element
   - Revokes object URL after download

**Limitations**:
- No UTF-16 export capability
- No schema rename to `<phon_data>/<data_form>`
- No audio filename manifest

### Offline Behavior

**`service-worker.js` Strategy**:

- **Cache Name**: `wordlist-elicitation-v1`
- **Precached Assets**:
  - `/`, `/index.html`
  - `/css/styles.css`
  - `/js/app.js`, `/js/storage.js`, `/js/xml-parser.js`, `/js/audio-recorder.js`, `/js/export.js`
  - `/manifest.json`

- **Install Event**: Cache all static assets, call `skipWaiting()`
- **Activate Event**: Delete old caches, call `clients.claim()`
- **Fetch Strategy**:
  - Skip non-GET requests
  - Skip chrome-extension URLs
  - Cache-first: Return cached response if available
  - Network fallback: Fetch from network and cache 200 basic responses
  - Runtime caching of successfully fetched resources

- **Messages**: Listens for `SKIP_WAITING` command

**`manifest.json` Configuration**:
```json
{
  "name": "Wordlist Elicitation Tool",
  "short_name": "Wordlist",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#2196F3",
  "background_color": "#FAFAFA",
  "orientation": "portrait-primary",
  "icons": [72, 96, 128, 144, 152, 192, 384, 512],
  "permissions": ["microphone", "storage"]
}
```

**Limitations**:
- Uses absolute paths (may fail if served in subpath)
- No version/hash cache-busting of assets
- No explicit update prompt UI

### Feature Gaps vs. Later Specifications

The old app **does not include**:

1. **Audio**: No strict 16-bit WAV capability gate or browser compatibility detection
2. **Import**: 
   - No online import from URL
   - No UTF-16LE/BE decoding support
   - No schema enforcement or normalization
3. **Export**:
   - No UTF-16LE with BOM
   - No `<phon_data>/<data_form>` schema
   - No enforced audio filename rules
4. **UX**:
   - No numeric reference sorting
   - No "All Entries" panel for quick navigation
   - No restore last position feature
   - No update notification when new SW version available
5. **Quality**:
   - Minimal filename sanitization
   - No comprehensive error boundaries
   - No automated tests

---

## Prompt A: Recreate Old App Verbatim

Use this prompt to regenerate the exact PWA found in `old/www/`:

---

**Build a simple PWA named "Wordlist Elicitation Tool" as a vanilla HTML/CSS/JS single-page app. Use this structure and behaviors:**

### File Structure

```
www/
├── index.html
├── manifest.json
├── service-worker.js
├── css/
│   └── styles.css
├── js/
│   ├── app.js
│   ├── storage.js
│   ├── xml-parser.js
│   ├── audio-recorder.js
│   └── export.js
└── icons/
    └── [icon files: 72, 96, 128, 144, 152, 192, 384, 512]
```

### index.html

**Four screens** (only one `.screen.active` at a time):

1. **Home Screen**:
   - Header: "Wordlist Elicitation Tool"
   - Hero icon (book/document SVG)
   - Stats card with three values:
     - Total (SVG list icon)
     - Completed (SVG checkmark icon)
     - Remaining (SVG circle icon)
   - Three main buttons:
     - Import Wordlist (always enabled)
     - Start Elicitation (disabled until entries exist)
     - Export Data (disabled until entries exist)

2. **Import Screen**:
   - Back button → Home
   - Info box: "Select a Dekereke XML wordlist file to import..."
   - Hidden file input (accept=".xml")
   - "Select XML File" button triggers file input
   - Status message div (empty initially)

3. **Elicitation Screen**:
   - Back button → Home (saves current entry first)
   - Word card:
     - Reference number display (e.g., "0001")
     - Gloss display (e.g., "body")
     - Picture container (hidden by default, shown if pictureFilename exists)
     - Text input: "Local Transcription:" placeholder
     - Record button (large, circular, with microphone SVG)
       - Text toggles: "Record" / "Stop"
       - Class toggles: `.recording` when active
     - Play button (hidden initially, shown when audio exists)
     - Recording status message div
   - Navigation:
     - Previous button (disabled at first entry)
     - Counter: "X / N"
     - Next button (disabled at last entry)

4. **Export Screen**:
   - Back button → Home
   - Info box: "Export all collected data as a ZIP archive containing: XML, Audio (WAV), Consent log"
   - Stats display:
     - Total Entries: X
     - Completed: X
     - With Audio: X
   - "Export ZIP Archive" button
   - Status message div

**Script loading order** (at end of body):
```html
<script src="js/storage.js"></script>
<script src="js/xml-parser.js"></script>
<script src="js/audio-recorder.js"></script>
<script src="js/export.js"></script>
<script src="js/app.js"></script>
<script>
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('service-worker.js')
      .then(reg => console.log('Service Worker registered'))
      .catch(err => console.error('Service Worker registration failed:', err));
  }
</script>
```

### css/styles.css

Light, mobile-first design:
- Clean header with back button support
- Card-based layout for stats and word display
- Large, circular record button (80-100px diameter)
- `.recording` class: red background or pulsing animation
- Button states: disabled styling, hover effects
- Responsive grid for stats (3 columns)
- SVG icons: inline, sized appropriately

### manifest.json

```json
{
  "name": "Wordlist Elicitation Tool",
  "short_name": "Wordlist",
  "description": "Comparative Wordlist Elicitation Tool for linguistic fieldwork",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FAFAFA",
  "theme_color": "#2196F3",
  "orientation": "portrait-primary",
  "icons": [
    { "src": "icons/icon-72.png", "sizes": "72x72", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-96.png", "sizes": "96x96", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-128.png", "sizes": "128x128", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-144.png", "sizes": "144x144", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-152.png", "sizes": "152x152", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-384.png", "sizes": "384x384", "type": "image/png", "purpose": "any maskable" },
    { "src": "icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "any maskable" }
  ],
  "categories": ["education", "productivity", "utilities"],
  "permissions": ["microphone", "storage"]
}
```

### service-worker.js

```javascript
const CACHE_NAME = 'wordlist-elicitation-v1';
const urlsToCache = [
  '/', '/index.html', '/css/styles.css',
  '/js/app.js', '/js/storage.js', '/js/xml-parser.js',
  '/js/audio-recorder.js', '/js/export.js', '/manifest.json'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
      .catch(err => console.error('Cache failed:', err))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(names =>
      Promise.all(
        names.map(name => name !== CACHE_NAME ? caches.delete(name) : null)
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  if (event.request.url.startsWith('chrome-extension://')) return;

  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      
      return fetch(event.request.clone()).then(response => {
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }
        caches.open(CACHE_NAME).then(cache => 
          cache.put(event.request, response.clone())
        );
        return response;
      }).catch(err => { throw err; });
    })
  );
});

self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') self.skipWaiting();
});
```

### js/storage.js

```javascript
class StorageManager {
  constructor() {
    this.dbName = 'WordlistElicitationDB';
    this.dbVersion = 1;
    this.db = null;
  }

  async init() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.dbVersion);
      request.onerror = () => reject(request.error);
      request.onsuccess = () => {
        this.db = request.result;
        resolve(this.db);
      };
      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        
        if (!db.objectStoreNames.contains('entries')) {
          const store = db.createObjectStore('entries', { keyPath: 'id', autoIncrement: true });
          store.createIndex('reference', 'reference', { unique: false });
          store.createIndex('isCompleted', 'isCompleted', { unique: false });
        }
        
        if (!db.objectStoreNames.contains('consent')) {
          const store = db.createObjectStore('consent', { keyPath: 'id', autoIncrement: true });
          store.createIndex('timestamp', 'timestamp', { unique: false });
        }
        
        if (!db.objectStoreNames.contains('audio')) {
          db.createObjectStore('audio', { keyPath: 'filename' });
        }
      };
    });
  }

  // Entry CRUD
  async addEntry(entry) {
    const tx = this.db.transaction(['entries'], 'readwrite');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('entries').add(entry);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async getAllEntries() {
    const tx = this.db.transaction(['entries'], 'readonly');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('entries').getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async getEntry(id) {
    const tx = this.db.transaction(['entries'], 'readonly');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('entries').get(id);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async updateEntry(entry) {
    const tx = this.db.transaction(['entries'], 'readwrite');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('entries').put(entry);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async deleteAllEntries() {
    const tx = this.db.transaction(['entries'], 'readwrite');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('entries').clear();
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  async getTotalCount() {
    const entries = await this.getAllEntries();
    return entries.length;
  }

  async getCompletedCount() {
    const entries = await this.getAllEntries();
    return entries.filter(e => e.isCompleted).length;
  }

  // Audio operations
  async saveAudio(filename, blob) {
    const tx = this.db.transaction(['audio'], 'readwrite');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('audio').put({ filename, blob });
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  async getAudio(filename) {
    const tx = this.db.transaction(['audio'], 'readonly');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('audio').get(filename);
      req.onsuccess = () => resolve(req.result?.blob || null);
      req.onerror = () => reject(req.error);
    });
  }

  async getAllAudio() {
    const tx = this.db.transaction(['audio'], 'readonly');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('audio').getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // Consent operations
  async addConsentRecord(record) {
    const tx = this.db.transaction(['consent'], 'readwrite');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('consent').add(record);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  async getAllConsentRecords() {
    const tx = this.db.transaction(['consent'], 'readonly');
    return new Promise((resolve, reject) => {
      const req = tx.objectStore('consent').getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  // Settings (localStorage)
  setSetting(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
  }

  getSetting(key, defaultValue = null) {
    const val = localStorage.getItem(key);
    return val ? JSON.parse(val) : defaultValue;
  }
}

const storageManager = new StorageManager();
```

### js/xml-parser.js

```javascript
class XMLParser {
  parseWordlist(xmlString) {
    const parser = new DOMParser();
    const doc = parser.parseFromString(xmlString, 'text/xml');
    
    const err = doc.querySelector('parsererror');
    if (err) throw new Error('XML parse error: ' + err.textContent);
    
    const elements = this.findWordElements(doc);
    return elements.map((el, i) => this.parseWordElement(el, i)).filter(Boolean);
  }

  findWordElements(doc) {
    const names = ['Word', 'Entry', 'Item', 'word', 'entry', 'item', 'data_form'];
    for (const name of names) {
      const els = doc.getElementsByTagName(name);
      if (els.length > 0) return Array.from(els);
    }
    const root = doc.documentElement;
    return root?.children ? Array.from(root.children) : [];
  }

  parseWordElement(el, index) {
    const ref = this.getText(el, ['Reference', 'Ref', 'Number', 'reference', 'ref', 'number']);
    const gloss = this.getText(el, ['Gloss', 'English', 'Word', 'gloss', 'english', 'word']);
    const pic = this.getText(el, ['Picture', 'Image', 'picture', 'image']);
    
    if (!gloss) return null;
    
    return {
      reference: ref || String(index + 1).padStart(4, '0'),
      gloss,
      localTranscription: '',
      audioFilename: null,
      pictureFilename: pic || undefined,
      recordedAt: null,
      isCompleted: false
    };
  }

  getText(parent, names) {
    for (const name of names) {
      const el = parent.getElementsByTagName(name)[0];
      if (el?.textContent) return el.textContent.trim();
    }
    return '';
  }

  generateXML(entries) {
    let xml = '<?xml version="1.0" encoding="UTF-8"?>\n<Wordlist>\n';
    entries.forEach(e => {
      xml += '  <Word>\n';
      xml += `    <Reference>${this.esc(e.reference)}</Reference>\n`;
      xml += `    <Gloss>${this.esc(e.gloss)}</Gloss>\n`;
      if (e.localTranscription) 
        xml += `    <LocalTranscription>${this.esc(e.localTranscription)}</LocalTranscription>\n`;
      if (e.audioFilename) 
        xml += `    <SoundFile>${this.esc(e.audioFilename)}</SoundFile>\n`;
      if (e.pictureFilename) 
        xml += `    <Picture>${this.esc(e.pictureFilename)}</Picture>\n`;
      if (e.recordedAt) 
        xml += `    <RecordedAt>${this.esc(e.recordedAt)}</RecordedAt>\n`;
      xml += '  </Word>\n';
    });
    xml += '</Wordlist>';
    return xml;
  }

  esc(text) {
    if (!text) return '';
    return String(text)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}

const xmlParser = new XMLParser();
```

### js/audio-recorder.js

```javascript
class AudioRecorder {
  constructor() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.stream = null;
    this.isRecording = false;
  }

  async init() {
    this.stream = await navigator.mediaDevices.getUserMedia({
      audio: { channelCount: 1, sampleRate: 44100, echoCancellation: true, noiseSuppression: true }
    });
    return true;
  }

  async startRecording() {
    if (this.isRecording) return;
    if (!this.stream) await this.init();
    
    this.audioChunks = [];
    const mime = this.getSupportedMime();
    this.mediaRecorder = new MediaRecorder(this.stream, { mimeType: mime });
    
    this.mediaRecorder.ondataavailable = e => {
      if (e.data.size > 0) this.audioChunks.push(e.data);
    };
    
    this.mediaRecorder.start();
    this.isRecording = true;
  }

  async stopRecording() {
    return new Promise((resolve, reject) => {
      if (!this.isRecording || !this.mediaRecorder) {
        reject(new Error('Not recording'));
        return;
      }
      
      this.mediaRecorder.onstop = async () => {
        const blob = new Blob(this.audioChunks, { type: this.mediaRecorder.mimeType });
        this.isRecording = false;
        try {
          const wav = await this.convertToWav(blob);
          resolve(wav);
        } catch (err) {
          console.warn('WAV conversion failed:', err);
          resolve(blob);
        }
      };
      
      this.mediaRecorder.stop();
    });
  }

  getSupportedMime() {
    const types = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mp4'
    ];
    for (const t of types) {
      if (MediaRecorder.isTypeSupported(t)) return t;
    }
    return '';
  }

  async convertToWav(blob) {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const buf = await blob.arrayBuffer();
    const audio = await ctx.decodeAudioData(buf);
    const wavBuf = this.audioBufferToWav(audio);
    return new Blob([wavBuf], { type: 'audio/wav' });
  }

  audioBufferToWav(buffer) {
    const numCh = buffer.numberOfChannels;
    const rate = buffer.sampleRate;
    const data = this.interleave(buffer);
    const dataLen = data.length * 2;
    const totalLen = 44 + dataLen;
    const ab = new ArrayBuffer(totalLen);
    const view = new DataView(ab);
    
    this.writeStr(view, 0, 'RIFF');
    view.setUint32(4, 36 + dataLen, true);
    this.writeStr(view, 8, 'WAVE');
    this.writeStr(view, 12, 'fmt ');
    view.setUint32(16, 16, true);
    view.setUint16(20, 1, true);
    view.setUint16(22, numCh, true);
    view.setUint32(24, rate, true);
    view.setUint32(28, rate * numCh * 2, true);
    view.setUint16(32, numCh * 2, true);
    view.setUint16(34, 16, true);
    this.writeStr(view, 36, 'data');
    view.setUint32(40, dataLen, true);
    
    this.float16PCM(view, 44, data);
    return ab;
  }

  interleave(buf) {
    if (buf.numberOfChannels === 1) return buf.getChannelData(0);
    const len = buf.length;
    const result = new Float32Array(len * buf.numberOfChannels);
    for (let ch = 0; ch < buf.numberOfChannels; ch++) {
      const chData = buf.getChannelData(ch);
      for (let i = 0; i < len; i++) {
        result[i * buf.numberOfChannels + ch] = chData[i];
      }
    }
    return result;
  }

  writeStr(view, off, str) {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(off + i, str.charCodeAt(i));
    }
  }

  float16PCM(view, off, input) {
    for (let i = 0; i < input.length; i++, off += 2) {
      const s = Math.max(-1, Math.min(1, input[i]));
      view.setInt16(off, s < 0 ? s * 0x8000 : s * 0x7FFF, true);
    }
  }

  cleanup() {
    if (this.stream) {
      this.stream.getTracks().forEach(t => t.stop());
      this.stream = null;
    }
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.isRecording = false;
  }
}

const audioRecorder = new AudioRecorder();
```

### js/export.js

```javascript
class ExportManager {
  constructor() {
    this.zipUrl = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js';
    this.loaded = false;
  }

  async ensureJSZip() {
    if (this.loaded && typeof JSZip !== 'undefined') return;
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = this.zipUrl;
      script.onload = () => { this.loaded = true; resolve(); };
      script.onerror = () => reject(new Error('JSZip load failed'));
      document.head.appendChild(script);
    });
  }

  async exportData() {
    await this.ensureJSZip();
    const zip = new JSZip();
    
    const entries = await storageManager.getAllEntries();
    const audio = await storageManager.getAllAudio();
    const consent = await storageManager.getAllConsentRecords();
    
    zip.file('wordlist.xml', xmlParser.generateXML(entries));
    
    const audioFolder = zip.folder('audio');
    audio.forEach(a => {
      if (a.blob) audioFolder.file(a.filename, a.blob);
    });
    
    if (consent.length > 0) {
      zip.file('consent_log.json', this.genConsent(consent));
    }
    
    zip.file('metadata.json', this.genMeta(entries));
    
    const blob = await zip.generateAsync({ type: 'blob', compression: 'DEFLATE', compressionOptions: { level: 6 } });
    this.download(blob, this.genFilename());
  }

  genConsent(records) {
    return JSON.stringify({
      generatedAt: new Date().toISOString(),
      records: records.map(r => ({
        id: r.id,
        timestamp: r.timestamp,
        deviceId: r.deviceId,
        type: r.type,
        response: r.response,
        verbalConsentFilename: r.verbalConsentFilename || null
      }))
    }, null, 2);
  }

  genMeta(entries) {
    return JSON.stringify({
      exportedAt: new Date().toISOString(),
      appVersion: '1.0.0',
      totalEntries: entries.length,
      completedEntries: entries.filter(e => e.isCompleted).length,
      entriesWithAudio: entries.filter(e => e.audioFilename).length,
      entriesWithTranscription: entries.filter(e => e.localTranscription).length
    }, null, 2);
  }

  genFilename() {
    const now = new Date();
    const d = now.toISOString().split('T')[0].replace(/-/g, '');
    const t = now.toTimeString().split(' ')[0].replace(/:/g, '');
    return `wordlist_export_${d}_${t}.zip`;
  }

  download(blob, name) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  async getExportStats() {
    const entries = await storageManager.getAllEntries();
    return {
      total: entries.length,
      completed: entries.filter(e => e.isCompleted).length,
      withAudio: entries.filter(e => e.audioFilename).length
    };
  }
}

const exportManager = new ExportManager();
```

### js/app.js

```javascript
class WordlistApp {
  constructor() {
    this.currentScreen = 'home-screen';
    this.currentEntryIndex = 0;
    this.entries = [];
    this.currentAudioBlob = null;
  }

  async init() {
    try {
      await storageManager.init();
      await this.loadEntries();
      this.setupEventListeners();
      this.updateHomeScreen();
      console.log('App initialized');
    } catch (err) {
      console.error('Init failed:', err);
      alert('Failed to initialize: ' + err.message);
    }
  }

  setupEventListeners() {
    // Home
    document.getElementById('import-btn').addEventListener('click', () => this.showScreen('import-screen'));
    document.getElementById('elicitation-btn').addEventListener('click', () => this.showScreen('elicitation-screen'));
    document.getElementById('export-btn').addEventListener('click', () => this.showScreen('export-screen'));
    
    // Import
    document.getElementById('import-back-btn').addEventListener('click', () => this.showScreen('home-screen'));
    document.getElementById('select-file-btn').addEventListener('click', () => document.getElementById('file-input').click());
    document.getElementById('file-input').addEventListener('change', e => this.handleFileSelect(e));
    
    // Elicitation
    document.getElementById('elicitation-back-btn').addEventListener('click', () => this.saveAndGoHome());
    document.getElementById('prev-btn').addEventListener('click', () => this.navigateEntry(-1));
    document.getElementById('next-btn').addEventListener('click', () => this.navigateEntry(1));
    document.getElementById('record-btn').addEventListener('click', () => this.toggleRecording());
    document.getElementById('play-btn').addEventListener('click', () => this.playRecording());
    document.getElementById('transcription-input').addEventListener('input', e => this.updateTranscription(e.target.value));
    
    // Export
    document.getElementById('export-back-btn').addEventListener('click', () => this.showScreen('home-screen'));
    document.getElementById('export-data-btn').addEventListener('click', () => this.exportData());
  }

  showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    this.currentScreen = id;
    
    if (id === 'elicitation-screen') this.loadElicitationScreen();
    else if (id === 'export-screen') this.loadExportScreen();
    else if (id === 'home-screen') this.updateHomeScreen();
  }

  async loadEntries() {
    this.entries = await storageManager.getAllEntries();
    this.updateButtonStates();
  }

  updateButtonStates() {
    const has = this.entries.length > 0;
    document.getElementById('elicitation-btn').disabled = !has;
    document.getElementById('export-btn').disabled = !has;
  }

  async updateHomeScreen() {
    const total = await storageManager.getTotalCount();
    const completed = await storageManager.getCompletedCount();
    document.getElementById('total-count').textContent = total;
    document.getElementById('completed-count').textContent = completed;
    document.getElementById('remaining-count').textContent = total - completed;
    this.updateButtonStates();
  }

  async handleFileSelect(e) {
    const file = e.target.files[0];
    if (!file) return;
    
    const status = document.getElementById('import-status');
    status.textContent = 'Processing...';
    status.className = 'status-message info';
    
    try {
      const text = await file.text();
      const entries = xmlParser.parseWordlist(text);
      if (entries.length === 0) throw new Error('No entries found');
      
      await storageManager.deleteAllEntries();
      for (const e of entries) await storageManager.addEntry(e);
      await this.loadEntries();
      
      status.textContent = `Imported ${entries.length} entries!`;
      status.className = 'status-message success';
      setTimeout(() => this.showScreen('home-screen'), 2000);
    } catch (err) {
      console.error('Import failed:', err);
      status.textContent = 'Import failed: ' + err.message;
      status.className = 'status-message error';
    }
    
    e.target.value = '';
  }

  loadElicitationScreen() {
    if (this.entries.length === 0) {
      this.showScreen('home-screen');
      return;
    }
    if (this.currentEntryIndex >= this.entries.length) this.currentEntryIndex = 0;
    this.displayCurrentEntry();
  }

  displayCurrentEntry() {
    const e = this.entries[this.currentEntryIndex];
    if (!e) return;
    
    document.getElementById('word-reference').textContent = e.reference || '';
    document.getElementById('word-gloss').textContent = e.gloss || '';
    document.getElementById('transcription-input').value = e.localTranscription || '';
    
    const pic = document.getElementById('picture-container');
    if (e.pictureFilename) {
      pic.style.display = 'block';
      document.getElementById('word-picture').src = e.pictureFilename;
    } else {
      pic.style.display = 'none';
    }
    
    document.getElementById('word-counter').textContent = `${this.currentEntryIndex + 1} / ${this.entries.length}`;
    document.getElementById('prev-btn').disabled = this.currentEntryIndex === 0;
    document.getElementById('next-btn').disabled = this.currentEntryIndex === this.entries.length - 1;
    
    const play = document.getElementById('play-btn');
    play.style.display = e.audioFilename ? 'flex' : 'none';
    
    this.currentAudioBlob = null;
    this.updateRecordingStatus('');
  }

  async navigateEntry(dir) {
    await this.saveCurrentEntry();
    this.currentEntryIndex += dir;
    this.currentEntryIndex = Math.max(0, Math.min(this.currentEntryIndex, this.entries.length - 1));
    this.displayCurrentEntry();
  }

  async saveCurrentEntry() {
    const e = this.entries[this.currentEntryIndex];
    if (!e) return;
    const hasTrans = e.localTranscription && e.localTranscription.trim() !== '';
    const hasAudio = e.audioFilename !== null;
    e.isCompleted = hasTrans || hasAudio;
    await storageManager.updateEntry(e);
  }

  async saveAndGoHome() {
    await this.saveCurrentEntry();
    await this.loadEntries();
    this.showScreen('home-screen');
  }

  updateTranscription(val) {
    const e = this.entries[this.currentEntryIndex];
    if (e) e.localTranscription = val;
  }

  async toggleRecording() {
    const btn = document.getElementById('record-btn');
    const txt = document.getElementById('record-text');
    
    if (audioRecorder.isRecording) {
      try {
        this.currentAudioBlob = await audioRecorder.stopRecording();
        btn.classList.remove('recording');
        txt.textContent = 'Record';
        await this.saveAudio();
        this.updateRecordingStatus('Recording saved!', 'success');
        document.getElementById('play-btn').style.display = 'flex';
      } catch (err) {
        console.error('Stop failed:', err);
        this.updateRecordingStatus('Stop failed', 'error');
      }
    } else {
      try {
        await audioRecorder.startRecording();
        btn.classList.add('recording');
        txt.textContent = 'Stop';
        this.updateRecordingStatus('Recording...', 'info');
      } catch (err) {
        console.error('Start failed:', err);
        this.updateRecordingStatus('Microphone required', 'error');
      }
    }
  }

  async saveAudio() {
    if (!this.currentAudioBlob) return;
    const e = this.entries[this.currentEntryIndex];
    const name = `${e.reference.padStart(4, '0')}_${e.gloss.replace(/\s+/g, '.')}.wav`;
    await storageManager.saveAudio(name, this.currentAudioBlob);
    e.audioFilename = name;
    e.recordedAt = new Date().toISOString();
    await storageManager.updateEntry(e);
    this.entries[this.currentEntryIndex] = e;
  }

  async playRecording() {
    const e = this.entries[this.currentEntryIndex];
    let blob = this.currentAudioBlob;
    if (!blob && e.audioFilename) blob = await storageManager.getAudio(e.audioFilename);
    if (!blob) {
      this.updateRecordingStatus('No recording', 'error');
      return;
    }
    try {
      const url = URL.createObjectURL(blob);
      const audio = new Audio(url);
      audio.play();
      audio.onended = () => URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Play failed:', err);
      this.updateRecordingStatus('Playback failed', 'error');
    }
  }

  updateRecordingStatus(msg, type = '') {
    const el = document.getElementById('recording-status');
    el.textContent = msg;
    el.className = 'status-message';
    if (type) el.classList.add(type);
    if (msg) {
      setTimeout(() => {
        el.textContent = '';
        el.className = 'status-message';
      }, 3000);
    }
  }

  async loadExportScreen() {
    const stats = await exportManager.getExportStats();
    document.getElementById('export-total').textContent = stats.total;
    document.getElementById('export-completed').textContent = stats.completed;
    document.getElementById('export-audio').textContent = stats.withAudio;
  }

  async exportData() {
    const status = document.getElementById('export-status');
    const btn = document.getElementById('export-data-btn');
    status.textContent = 'Preparing export...';
    status.className = 'status-message info';
    btn.disabled = true;
    
    try {
      await exportManager.exportData();
      status.textContent = 'Export successful!';
      status.className = 'status-message success';
    } catch (err) {
      console.error('Export failed:', err);
      status.textContent = 'Export failed: ' + err.message;
      status.className = 'status-message error';
    } finally {
      btn.disabled = false;
    }
  }
}

const app = new WordlistApp();
document.addEventListener('DOMContentLoaded', () => app.init());
```

---

**This prompt generates the exact app found in `old/www/` with all behaviors preserved.**

---

## Prompt B (Android): Flutter Implementation with Improvements

Use this prompt to build the improved mobile app as a native Android application using Flutter/Dart under `mobile_app/`. Do not create or modify desktop/pywebview code here. Keep all changes scoped to the Flutter Android app.

---

**Build an enhanced "Wordlist Elicitation Tool" Android app in Flutter that mirrors Prompt A behaviors but implemented natively. Place the app under `mobile_app/` and avoid changing other folders.**

Scope guard: This section applies only to `mobile_app/`. Do not mix desktop (pywebview) or PWA concerns into Flutter code.

Repository paths note: All paths and commands in this prompt are relative to the online repository filesystem the GitHub coding agent operates on (not local machine paths).

### Project Layout

Create and/or modify the Flutter project at `mobile_app/` with this high-level structure:

```
mobile_app/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── import_screen.dart
│   │   ├── elicitation_screen.dart
│   │   └── export_screen.dart
│   ├── services/
│   │   ├── storage_service.dart
│   │   ├── xml_service.dart
│   │   ├── audio_service.dart
│   │   └── export_service.dart
│   ├── models/
│   │   ├── entry.dart
│   │   ├── consent_record.dart
│   │   └── audio_file.dart
│   ├── utils/
│   │   ├── filename.dart
│   │   └── encoding.dart
│   └── widgets/
├── android/
├── pubspec.yaml
└── README.md
```

Storage can be implemented with Hive or Isar. If using SQLite (`sqflite`), store audio file paths, not blobs.

### Service Stubs to Implement

Implement the following minimal services under `mobile_app/lib/` (stubs created in this repo):
- `services/audio_service.dart`: `checkWavSupport()`, `startRecording()`, `stopRecordingAndSave()`, `playRecording()`
- `services/xml_service.dart`: `parseWordlistFromSource()`, `generateXmlUtf16leWithBom()`
- `services/storage_service.dart`: `init()`, CRUD for `Entry`, metrics helpers
- `services/export_service.dart`: `buildZip()` using `archive`

Models and utils:
- `models/entry.dart`: core entry model
- `utils/filename.dart`: `slugifyGloss()`, `generateAudioFilename()`

### Enhanced Features

#### 1. Strict Audio Capability Detection (Flutter)

Requirement: Confirm device can capture mono 44.1kHz or 48kHz and write 16-bit PCM WAV. Block elicitation if unsupported.

Implementation (`lib/services/audio_service.dart`):
- `Future<AudioSupport> checkWavSupport()` records a short clip using `flutter_sound` or `record` set to WAV/PCM.
- Validate WAV header (RIFF, fmt PCM=1, bitsPerSample=16, correct sampleRate).
- On unsupported, show persistent banner in `elicitation_screen.dart` and disable record/play.

#### 2. UTF-16 Import/Export

Import (`lib/services/xml_service.dart`):
- `Future<List<Entry>> parseWordlistFromSource({required Uri source, required bool isUrl})`.
- If `isUrl`: fetch via `http`.
- Flexible, error-tolerant decoding: detect and handle UTF-8, UTF-16LE (with or without BOM), and UTF-16BE. If BOMs are duplicated or missing, auto-correct and proceed when safely possible; only hard-fail on irrecoverable decoding errors.
- Parse tolerant XML using Dart `xml` package.

Export (`lib/services/xml_service.dart`):
- `Uint8List generateXmlUtf16leWithBom(List<Entry> entries)` emitting `<phon_data>/<data_form>` schema.
- Encode as UTF-16LE bytes and prefix exactly one BOM (FF FE). Validate that `<?xml` follows BOM. Enforce strict export rules: exactly one BOM at start; reject/repair any condition that would violate this before writing the file.

#### 3. Reference Sorting and Schema Enforcement

Import normalization (`lib/services/xml_service.dart`):
- Parse `reference` as integer (strip non-digits), store padded `ref.padLeft(4, '0')`.
- Sort ascending by numeric reference.
- Enforce audio filename via `generateAudioFilename(reference, gloss)` in `lib/utils/filename.dart`.

#### 4. "All Entries" Panel

UI (`lib/screens/elicitation_screen.dart` + widgets):
- FAB opens a `ModalBottomSheet` or `DraggableScrollableSheet` listing entries with search.
- Tap row → jump to index and close panel.

Logic: Manage state via `ChangeNotifier` or Riverpod; filter in-memory.

#### 5. Resume Last Position

Storage (`lib/services/storage_service.dart`):
- Persist `lastEntryIndex` via `shared_preferences` or Hive.
- Restore with bounds on elicitation init.

#### 6. App Update Detection (Optional)

Use a simple stored app version and show a banner when version changes. Optional; can be skipped.

#### 7. Online Import UI

Import Screen (`lib/screens/import_screen.dart`):
- Two actions: File (`file_picker`) and URL.
- Validate URL; show loading state; use flexible decoding/import. Only clear existing entries after a successful parse; on failure, keep existing data and show error.

#### 8. Enhanced Progress Tracking

Metrics (`lib/services/storage_service.dart`):
- Provide: total, completed, withAudio, transcribed.

Home Screen: Show the four stats and optional progress bar.

#### 9. Audio Filename Enforcement

Utility (`lib/utils/filename.dart`):
```dart
String slugifyGloss(String gloss) {
  final lower = gloss.toLowerCase();
  final dotted = lower.replaceAll(RegExp(r"\s+"), '.');
  final cleaned = dotted.replaceAll(RegExp(r"[^a-z0-9._-]"), '');
  return cleaned.length > 64 ? cleaned.substring(0, 64) : cleaned;
}

String generateAudioFilename(String reference, String gloss) {
  final ref = reference.padLeft(4, '0');
  final slug = slugifyGloss(gloss);
  return '$ref\_${slug}.wav';
}
```

Use when saving audio.

#### 10. Packaging and Export

ZIP Export (`lib/services/export_service.dart`):
- Build ZIP using `archive` containing:
  - `wordlist.xml` (UTF-16LE + single BOM).
  - `audio/` WAV files.
  - `consent_log.json` (optional).
  - `metadata.json` with counts and app version.
- Save via `path_provider` + user action (e.g., `file_saver`).

### Edge Cases and Validation

**Import**:
- Malformed XML → show error, don't alter existing data
- Encoding issues → attempt auto-correction and tolerant decoding for UTF-8/16LE/16BE; warn user on adjustments; hard-fail only when unrecoverable
- Empty or invalid URL → validate before fetch
- Duplicate references → keep all, sort maintains order

**Audio**:
- Microphone permission denied → disable Record, show inline message
- WAV capture failure → show error and keep Record disabled
- No audio/transcription → entry not marked completed

**Export**:
- UTF-16LE BOM validation: first two bytes must be FF FE
- ZIP generation failure → clear error message, no partial download
- Empty entries list → disable export button

**Persistence**:
- Entries/audio/consent stored locally (Hive/Isar/sqflite) and survive app restarts.

### Success Criteria Checklist

- ✅ 16-bit WAV capability detected; unsupported devices blocked
- ✅ Import handles UTF-8/16LE/16BE with BOM detection
- ✅ Export produces UTF-16LE XML with single BOM
- ✅ Schema: `<phon_data>/<data_form>` on export
- ✅ References sorted numerically ascending
- ✅ Audio filenames follow slug rules, max 64 chars
- ✅ "All Entries" panel with search and jump
- ✅ Last position restored on elicitation resume
- ✅ Online import via URL and local file picker
- ✅ Progress shows: Total, Completed, With Audio, Transcribed
- ✅ Data persists across app restarts

### Minimal Unit Tests

Add tests under `mobile_app/test/` (stubs created):
- `filename_test.dart`: slugify and filename formatting
- `bom_test.dart`: UTF-16LE BOM prefix correctness
- `wav_header_test.dart`: 16‑bit PCM WAV header validation

Run tests inside the Flutter project:
```zsh
cd mobile_app
flutter test
```

---

## Clarifications and Potential Issues to Address

- Android permissions: Ensure `RECORD_AUDIO` in `AndroidManifest.xml`; save audio to app documents directory.
- Sample rate: Accept 44.1kHz or 48kHz; always 16-bit PCM.
- Encoding: Provide UTF-16 decoder with BOM handling; add tests.
- Large lists: Use isolates for XML parsing.
- Gradle cache: Keep existing no-configuration-cache flags; Flutter code should not depend on cache behavior.
- Tests: Add unit tests for slugify, ref sorting, BOM emission, WAV header.

---

**This prompt generates an improved PWA with all your specified enhancements while maintaining the core structure.**

---

## Next Steps

1. **Choose a prompt**:
   - **Prompt A**: Recreate exact old app for reference/archival
   - **Prompt B**: Build improved version with all enhancements

2. **Generate in this repo**:
   - Say "Apply Prompt A" or "Apply Prompt B" and I'll scaffold all files
   - Alternative: "Apply Prompt B but skip [feature X]" for selective implementation

3. **Side-by-side comparison**:
   - Say "Show me a diff between old and Prompt B features" for migration notes

4. **Surgical update**:
   - Say "Add only UTF-16 export to old app" for minimal changes

5. **Testing**:
   - After generation, say "Add basic tests for UTF-16 export and reference sorting"

---

**This document serves as a complete specification and regeneration guide for the Wordlist Elicitation Tool PWA.**

---

## Prompt B Extension: Desktop App (pywebview) Specification

Build a desktop version under `desktop_app/` using Python + pywebview, mirroring Prompt B functionality, with these constraints:

- **Architecture**: Single-process desktop app. HTML/JS UI rendered by pywebview; Python hosts all non-UI logic (storage, XML I/O, audio management, export). No client/server.
- **UI responsibilities (HTML/JS)**:
  - Render screens and components; manage DOM events.
  - Call Python APIs via pywebview’s `expose` bridge; avoid business logic in JS.
  - Keep JS minimal: UI state, input validation, event dispatch to Python.
- **Python responsibilities**:
  - Data model, IndexedDB alternative (SQLite recommended) with tables: entries, audio (blob or file path), consent.
  - Import (UTF‑8/16LE/16BE detection), normalization to stricter schema, numeric reference sorting.
  - Export ZIP with XML encoded as UTF‑16LE WITH SINGLE BOM.
    - Validate BOM correctness: ensure exactly one BOM precedes XML declaration. Reject/repair duplicates.
    - Implementation hint:
      - Use `codecs` or explicit bytes: `bom = b"\xFF\xFE"`; generate XML as UTF‑16LE bytes, then prefix bom once if not present.
      - Verify: `data.startswith(bom) and data[len(bom):].startswith(b"<?xml")`.
  - Audio recording/playback: Prefer platform-native libraries (e.g., `sounddevice`/`pyaudio` for capture, `wave` for 16‑bit PCM writing). Always store WAV 16‑bit PCM.
  - Filename enforcement: `${reference}_${slug(gloss)}.wav` with slug rules (lowercase, spaces→dots, strip non `[a-z0-9._-]`, max 64).
  - "All Entries" listing, resume last position, and progress metrics implemented in Python and surfaced to UI.
  - Update checks are optional for desktop.

### Desktop File Layout

```
desktop_app/
├── README.md
├── requirements.txt
├── main.py                 # pywebview bootstrap, API exposure
├── app/                    # Python app logic
│   ├── storage.py         # SQLite models and CRUD
│   ├── xml_io.py          # Import/export, UTF‑16LE BOM handling
│   ├── audio.py           # Recording/playback, WAV 16‑bit
│   ├── utils.py           # slugify, filename rules, encoding detection
│   └── export_zip.py      # JSZip alternative: Python zipfile
└── web/                   # UI
    ├── index.html         # Same screens as Prompt B
    ├── css/styles.css
    └── js/ui.js          # UI-only; calls window.pywebview.api.*
```

### pywebview API Surface (Python → JS)

- `load_entries() -> list[Entry]`
- `import_from_file(path: str) -> ImportSummary`
- `import_from_url(url: str) -> ImportSummary`
- `save_transcription(entry_id: int, text: str) -> bool`
- `start_recording(entry_id: int) -> bool`
- `stop_recording(entry_id: int) -> { filename: str }`
- `play_audio(entry_id: int) -> bool`
- `export_zip(dest_path: str) -> ExportSummary`
- `get_progress() -> { total, completed, withAudio, transcribed }`
- `list_all_entries(filter: str | None) -> list[EntrySummary]`
- `jump_to(reference_or_index: str | int) -> Entry`
- `get_last_position() -> int`
- `set_last_position(index: int) -> None`

### UTF‑16LE BOM Rules (Desktop)

- Always produce XML as UTF‑16LE WITH SINGLE BOM.
- Enforce exactly one BOM at file start; BOM must be the only bytes before `<?xml` declaration.
- Validation check before writing file:
  - `bom = b"\xFF\xFE"`
  - `xml_bytes = generate_xml_utf16le_bytes(entries)` (no BOM inside)
  - `final = bom + xml_bytes`
  - Assert: `final.startswith(bom) and final[len(bom):].startswith(b"<?xml")`

### Desktop Try-it Commands

```bash
# macOS (zsh)
python3 -m venv .venv
source .venv/bin/activate
pip install -r desktop_app/requirements.txt
python desktop_app/main.py
```

### requirements.txt (suggested)

```
pywebview>=4.4
sounddevice>=0.4; platform_system=="Darwin" or platform_system=="Linux"
PyAudio>=0.2; platform_system=="Windows"
numpy>=1.24
```

---

## Delegation Plan for GitHub Coding Agent

When ready, instruct the coding agent to:

- Create `desktop_app/` as specified above and implement Python-side logic focused on:
  - UTF‑16LE export with strict single BOM validation
  - SQLite storage for entries/audio/consent
  - 16‑bit WAV recording/playback
  - UI-only HTML/JS that calls Python APIs
- Leave any `mobile_app/` folder untouched.
- Do not modify existing PWA files under `www/` or `old/` unless explicitly requested.

Suggested issue title: "Implement desktop_app (pywebview) with UTF‑16LE BOM enforcement"

Key requirements for the agent:
- Follow the desktop layout and API surface exactly.
- Provide `README.md` with setup/run instructions and platform notes.
- Include minimal tests: BOM correctness, filename slugify, reference sorting.

---
