# Installation and Deployment Guide

This guide covers various ways to run and deploy the Wordlist Elicitation Tool PWA.

## Table of Contents

- [Running Locally](#running-locally)
- [Deploying to Web Server](#deploying-to-web-server)
- [Creating Android App with TWA](#creating-android-app-with-twa)
- [Installing as PWA](#installing-as-pwa)

## Running Locally

### Prerequisites

- A modern web browser (Chrome 90+, Firefox 88+, Safari 14+)
- Python 3, Node.js, or PHP (for local server)

### Option 1: Python HTTP Server

```bash
cd www
python3 -m http.server 8000
```

Then open http://localhost:8000 in your browser.

### Option 2: Node.js HTTP Server

```bash
# Install http-server globally (one time)
npm install -g http-server

# Serve the app
cd www
http-server -p 8000
```

### Option 3: PHP Built-in Server

```bash
cd www
php -S localhost:8000
```

### Option 4: VS Code Live Server

1. Install the "Live Server" extension in VS Code
2. Open the `www` folder in VS Code
3. Right-click on `index.html` and select "Open with Live Server"

## Deploying to Web Server

### Requirements

- Web server with HTTPS support (required for PWA features)
- Any static file hosting service

### Option 1: GitHub Pages

1. Enable GitHub Pages in your repository settings
2. Set source to main branch with `/www` folder
3. Your app will be available at: `https://username.github.io/repository-name/`

### Option 2: Netlify

1. Sign up at https://www.netlify.com
2. Connect your GitHub repository
3. Configure build settings:
   - Build command: (leave empty)
   - Publish directory: `www`
4. Deploy

### Option 3: Vercel

1. Sign up at https://vercel.com
2. Import your GitHub repository
3. Configure project:
   - Root directory: `www`
4. Deploy

### Option 4: Traditional Web Hosting

1. Upload the contents of the `www` directory to your web server
2. Ensure the server has HTTPS enabled
3. Access via your domain

## Creating Android App with TWA

Trusted Web Activity (TWA) allows you to package your PWA as a native Android app.

### Prerequisites

- Node.js and npm installed
- Android Studio installed (for building and testing)
- A deployed PWA with HTTPS

### Step 1: Install Bubblewrap CLI

```bash
npm install -g @bubblewrap/cli
```

### Step 2: Initialize TWA Project

```bash
# Create a new directory for your TWA project
mkdir wordlist-twa
cd wordlist-twa

# Initialize with your PWA URL
bubblewrap init --manifest https://your-domain.com/manifest.json
```

You'll be prompted for:
- Package name (e.g., `org.example.wordlist`)
- App name
- Icon paths
- Colors

### Step 3: Build the Android App

```bash
bubblewrap build
```

This will generate an APK file in the project directory.

### Step 4: Test the App

```bash
# Install on connected device or emulator
bubblewrap install
```

### Step 5: Generate Signing Key (for Play Store)

```bash
# Generate a keystore
keytool -genkey -v -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000

# Update bubblewrap with signing info
bubblewrap update
```

### Step 6: Build Release APK

```bash
bubblewrap build --release
```

### Step 7: Upload to Google Play Store

1. Sign in to Google Play Console
2. Create a new app
3. Upload the release APK
4. Complete store listing
5. Publish

## Installing as PWA

Users can install the PWA directly from their browser without going through an app store.

### On Chrome/Edge (Desktop)

1. Open the PWA in Chrome/Edge
2. Click the install icon in the address bar (or three-dot menu → "Install Wordlist Elicitation Tool")
3. The app will be installed and can be launched from the Start menu/Applications folder

### On Chrome (Android)

1. Open the PWA in Chrome
2. Tap the three-dot menu → "Install app" or "Add to Home screen"
3. The app will be installed on your home screen

### On Safari (iOS)

1. Open the PWA in Safari
2. Tap the Share button
3. Select "Add to Home Screen"
4. The app will be installed on your home screen

## Updating the App

### For Web Deployment

Simply update the files on your web server. The Service Worker will automatically update the cache when users reload the app.

### For TWA

1. Update your PWA on the web server
2. Update the TWA version number in `twa-manifest.json`
3. Rebuild and republish the Android app

## Troubleshooting

### Service Worker Not Registering

- Ensure you're using HTTPS (except on localhost)
- Check browser console for errors
- Clear browser cache and reload

### Audio Recording Not Working

- Ensure microphone permissions are granted
- Check browser console for errors
- Some browsers require HTTPS for microphone access

### IndexedDB Issues

- Check browser storage settings
- Ensure sufficient storage space
- Try clearing browser data and reimporting

### PWA Not Installable

- Verify `manifest.json` is valid
- Ensure HTTPS is enabled
- Check that Service Worker is registered
- Verify icons are available

## Browser Compatibility

### Tested Browsers

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Chrome Android 90+
- ✅ Safari iOS 14+

### Required Features

- IndexedDB
- Service Worker
- Web Audio API
- MediaRecorder API
- File API

## Performance Tips

1. **Generate PNG Icons**: Convert the SVG icon to PNG in all required sizes for better performance
2. **Optimize Service Worker**: Adjust cache strategy based on your needs
3. **Minimize CDN Dependencies**: Host JSZip locally for better offline support
4. **Enable Compression**: Enable gzip/brotli compression on your web server

## Security Considerations

- Always use HTTPS in production
- Data is stored locally in IndexedDB (user's device)
- No data is transmitted to external servers by default
- Users can clear data via browser settings
- Consider adding password protection for sensitive deployments

## Support

For issues or questions:
- Open an issue on GitHub
- Check the [PWA README](www/README.md)
- Review the [main README](README.md)
