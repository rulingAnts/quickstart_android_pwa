# Quick Start Guide - PWA Version

Get up and running with the Wordlist Elicitation Tool in 5 minutes!

## Step 1: Run the App (Choose One)

### Option A: Python (Easiest)
```bash
cd www
python3 -m http.server 8000
```

### Option B: Node.js
```bash
cd www
npx http-server -p 8000
```

### Option C: PHP
```bash
cd www
php -S localhost:8000
```

Then open http://localhost:8000 in your browser.

## Step 2: Import a Wordlist

1. Click **"Import Wordlist"**
2. Click **"Select XML File"**
3. Choose the file: `test_data/sample_wordlist.xml`
4. Wait for "Successfully imported 10 entries!"
5. You'll be redirected to the home screen

## Step 3: Start Elicitation

1. Click **"Start Elicitation"**
2. You'll see the first word (Reference: 0001, Gloss: body)
3. Enter a transcription (e.g., "bɔdi")
4. Click the **red Record button** to record audio
5. Click again to stop recording
6. Click **"Next"** to move to the next word
7. Click the **back arrow** when done

## Step 4: Check Progress

On the home screen, you'll see:
- **Total**: Number of words imported
- **Completed**: Words with transcription or audio
- **Remaining**: Words not yet completed

## Step 5: Export Data

1. Click **"Export Data"**
2. Review the statistics
3. Click **"Export ZIP Archive"**
4. A ZIP file will download containing:
   - XML file with transcriptions
   - Audio recordings (WAV format)
   - Metadata and consent log

## Features Overview

### 🎤 Audio Recording
- Click the large red microphone button
- Browser will ask for microphone permission (allow it)
- Record high-quality audio for each word
- Play back recordings instantly

### 📝 Transcription
- Enter text in any language
- Full Unicode support (including IPA characters)
- Auto-saves as you type

### 💾 Local Storage
- All data stored in your browser (IndexedDB)
- Works offline after first load
- No internet connection required

### 📤 Export
- Creates ZIP archive with all data
- Includes XML, audio files, and metadata
- Ready for use with Dekereke or FLEx

## Tips & Tricks

### Install as App
1. In Chrome: Click the install icon in the address bar
2. In Safari (iOS): Share → Add to Home Screen
3. In Edge: Settings → Apps → Install this site as an app

### Keyboard Shortcuts
- **Tab**: Move between fields
- **Enter**: Submit or advance (where applicable)
- **Escape**: Cancel or go back

### IPA Input
1. Install Keyman keyboard app on your device
2. Or use online IPA keyboard
3. Copy and paste IPA characters

### Clear Data
- Chrome: Settings → Privacy → Clear browsing data → Indexed DB
- Firefox: Options → Privacy → Clear Data
- Safari: Settings → Clear History and Website Data

## Troubleshooting

### "Microphone access required"
- Allow microphone permission in browser
- Check browser settings for site permissions
- Ensure HTTPS is used (or localhost)

### "Import failed"
- Check XML file format
- Ensure file contains `<Reference>` and `<Gloss>` elements
- Try the sample file: `test_data/sample_wordlist.xml`

### Data Not Saving
- Check browser storage settings
- Ensure cookies/storage not blocked
- Try a different browser

### Offline Not Working
- Service Worker requires HTTPS (except localhost)
- Load the page once while online
- Check browser console for errors

## Next Steps

### For Development
- See [www/README.md](www/README.md) for technical details
- See [INSTALLATION.md](INSTALLATION.md) for deployment options
- See [MIGRATION_NOTES.md](MIGRATION_NOTES.md) for architecture

### For Deployment
- Upload `www/` folder to any web server
- Enable HTTPS for full PWA features
- See [INSTALLATION.md](INSTALLATION.md) for hosting options

### Create Android App
```bash
npm install -g @bubblewrap/cli
bubblewrap init --manifest https://your-domain.com/manifest.json
bubblewrap build
```

See [INSTALLATION.md](INSTALLATION.md) for complete TWA guide.

## Support

- 📖 Documentation: See README.md
- 🐛 Issues: Open a GitHub issue
- 💬 Questions: Use GitHub Discussions

## Demo Data

The repository includes sample data for testing:
- `test_data/sample_wordlist.xml` - 10 word entries
- Basic body part vocabulary
- Suitable for quick testing

## Browser Requirements

✅ Chrome/Edge 90+
✅ Firefox 88+
✅ Safari 14+
✅ Mobile browsers

## What's Next?

1. **Add More Words**: Import larger wordlists
2. **Customize**: Edit colors in `www/css/styles.css`
3. **Deploy**: Put it on a web server for field use
4. **Package**: Create Android app with TWA
5. **Contribute**: Submit improvements on GitHub

Happy eliciting! 🎉
