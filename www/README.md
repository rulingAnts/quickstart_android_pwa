# Wordlist Elicitation Tool - PWA

This is a Progressive Web App (PWA) implementation of the Comparative Wordlist Elicitation Tool for linguistic fieldwork.

## Features

- **PWA Capabilities**: Install on any device, works offline
- **Local Storage**: Uses IndexedDB for structured data storage (replaces SQLite)
- **Audio Recording**: Web Audio API for high-quality recordings
- **XML Import/Export**: Import Dekereke XML wordlists and export collected data
- **Responsive Design**: Works on mobile, tablet, and desktop
- **No Backend Required**: All data stored locally in the browser

## Getting Started

### Running Locally

1. Serve the `www` directory with any HTTP server:

```bash
# Using Python 3
cd www
python3 -m http.server 8000

# Using Node.js (http-server)
npx http-server www -p 8000

# Using PHP
cd www
php -S localhost:8000
```

2. Open your browser to `http://localhost:8000`

### Using the App

1. **Import a Wordlist**: Click "Import Wordlist" and select a Dekereke XML file
2. **Start Elicitation**: Click "Start Elicitation" to begin recording words
3. **Record Audio**: Click the red microphone button to record, click again to stop
4. **Navigate**: Use Previous/Next buttons to move between words
5. **Export Data**: Click "Export Data" to download a ZIP file with all your work

## Data Storage

The PWA uses browser storage:
- **IndexedDB**: Stores wordlist entries, audio recordings, and consent records
- **localStorage**: Stores app settings and preferences

All data is stored locally on the device. Users can clear it via browser settings.

## Converting to TWA (Trusted Web Activity)

To package this PWA as an Android app using TWA:

1. Install Bubblewrap CLI:
```bash
npm install -g @bubblewrap/cli
```

2. Initialize TWA project:
```bash
bubblewrap init --manifest https://your-domain.com/manifest.json
```

3. Build the Android app:
```bash
bubblewrap build
```

4. The APK will be generated in the project directory

See the [Bubblewrap documentation](https://github.com/GoogleChromeLabs/bubblewrap) for more details.

## File Structure

```
www/
├── index.html          # Main HTML file
├── manifest.json       # PWA manifest
├── service-worker.js   # Service worker for offline support
├── css/
│   └── styles.css      # Application styles
├── js/
│   ├── app.js          # Main application logic
│   ├── storage.js      # IndexedDB storage manager
│   ├── xml-parser.js   # XML parsing and generation
│   ├── audio-recorder.js # Audio recording using Web Audio API
│   └── export.js       # Export functionality with JSZip
└── icons/
    └── icon.svg        # App icon (generate PNGs from this)
```

## Browser Requirements

- Modern browser with ES6 support
- IndexedDB support
- Web Audio API support
- MediaRecorder API support
- Service Worker support

Tested on:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+
- Mobile browsers (Chrome, Safari)

## Offline Support

The service worker caches all static assets for offline use. Audio recordings and imported wordlists are stored in IndexedDB and available offline.

## Security & Privacy

- All data is stored locally on the user's device
- No data is sent to external servers
- Audio recordings require microphone permission
- Users can clear all data via browser settings

## Development

To modify the app:

1. Edit files in the `www` directory
2. Refresh the browser to see changes
3. For service worker changes, use "Update on reload" in DevTools

## License

This project is licensed under AGPL-3.0. See the LICENSE file in the repository root.
