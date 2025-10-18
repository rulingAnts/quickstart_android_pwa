# Developer Guide (PWA)

This repository is a browser-first Progressive Web App (PWA) with a tiny Node-based static dev server. No Flutter/Dart is used anymore.

## Quick Start

```bash
npm install   # ensure Node 18+ is available
npm start     # serves ./www on http://127.0.0.1:5173 with SPA fallback
```

Alternative local servers are listed in `www/README.md` and `QUICKSTART_PWA.md`.

## Project Structure

- www/ — all app source (HTML, CSS, JS modules, manifest, service worker)
- server.js — local static server with proper MIME and SPA routing
- scripts/dev-android.js — emulator + adb reverse helper for testing on Android
- scripts/pull-from-download.js — interactive helper to pull a ZIP from device Downloads

## Day-to-day Dev

- Edit files under `www/` and refresh the browser
- For service worker changes, hard refresh or use DevTools “Update on reload”
- Use the entry list panel to jump around entries; the app persists last position automatically

## Android Emulator Workflow

```bash
npm run dev:android
```

What it does:
- Starts the local dev server
- Lists AVDs and starts one if needed
- Waits for boot, runs `adb reverse tcp:5173 tcp:5173`
- Optionally opens Chrome on the emulator pointing to http://127.0.0.1:5173

## Import/Export Notes

- Import supports online URL or local file; UTF-16 detection and decoding is automatic
- Export produces a ZIP including UTF-16LE XML and 16-bit WAV audio files named like `0001body.wav`
- Storage is IndexedDB for entries/audio/consent; localStorage holds a few small flags

## Coding Standards

- Vanilla JS (ES modules), keep dependencies minimal
- Keep functions small, avoid global state; organize code under `www/js/`
- Prefer progressive enhancement, graceful failure with clear messages

## Testing Tips

- Use test data in `test_data/`
- Verify microphone permissions and that the capability check passes (the app blocks if strict 16-bit WAV is not feasible)

## Releasing

For web hosting, deploy the `www/` folder to any static host with HTTPS. For Android packaging, see TWA notes in `INSTALLATION.md`.

## Contributing

Open issues/PRs with concise scope. Please update relevant docs if behavior changes. All contributions are licensed AGPL-3.0.
See `FLUTTER_README.md` for more details on MVP features and roadmap.
