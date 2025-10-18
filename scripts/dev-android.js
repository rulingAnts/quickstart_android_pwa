#!/usr/bin/env node
/**
 * Dev orchestrator for Android testing:
 * 1) Launch the local web server (node server.js)
 * 2) Prompt to open in a browser (on desktop and/or Android emulator)
 * 3) Detect available Android Virtual Devices (emulator -list-avds) and let user select
 * 4) Launch selected emulator and run `adb reverse tcp:<PORT> tcp:<PORT>` so PWA can access localhost
 *
 * Requirements:
 * - Android SDK tools on PATH: `emulator`, `adb` (usually via Android Studio SDK)
 * - Node >= 18
 */
const { spawn, spawnSync } = require('child_process');
const readline = require('readline');
const os = require('os');
const path = require('path');

const PORT = Number(process.env.PORT) || 5173;
const HOST = process.env.HOST || '127.0.0.1';
const URL = `http://${HOST}:${PORT}/`;

function askQuestion(query) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => rl.question(query, (ans) => { rl.close(); resolve(ans); }));
}

function spawnDetached(cmd, args = [], opts = {}) {
  const child = spawn(cmd, args, { stdio: 'ignore', detached: true, ...opts });
  child.unref();
  return child;
}

function spawnLogged(cmd, args = [], opts = {}) {
  const child = spawn(cmd, args, { stdio: 'inherit', ...opts });
  return child;
}

function homeDir() {
  return os.homedir ? os.homedir() : process.env.HOME || process.env.USERPROFILE || '';
}

function pathExists(p) {
  try { require('fs').accessSync(p); return true; } catch { return false; }
}

function findAndroidSdkRoot() {
  const envRoot = process.env.ANDROID_SDK_ROOT || process.env.ANDROID_HOME;
  if (envRoot && pathExists(envRoot)) return envRoot;
  // Common defaults
  const candidates = [];
  if (process.platform === 'darwin') {
    candidates.push(path.join(homeDir(), 'Library', 'Android', 'sdk'));
  } else if (process.platform === 'linux') {
    candidates.push(path.join(homeDir(), 'Android', 'Sdk'));
  } else if (process.platform === 'win32') {
    if (process.env.LOCALAPPDATA) candidates.push(path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk'));
    if (process.env.APPDATA) candidates.push(path.join(process.env.APPDATA, 'Android', 'Sdk'));
  }
  for (const c of candidates) if (pathExists(c)) return c;
  return undefined;
}

function which(cmd) {
  try {
    const r = spawnSync(process.platform === 'win32' ? 'where' : 'which', [cmd], { encoding: 'utf8' });
    if (r.status === 0) {
      const out = (r.stdout || '').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
      return out[0];
    }
  } catch {}
  return undefined;
}

function resolveEmulatorPath() {
  // Prefer PATH
  const onPath = which('emulator');
  if (onPath) return onPath;
  // Try within SDK
  const sdk = findAndroidSdkRoot();
  if (sdk) {
    const p = path.join(sdk, 'emulator', process.platform === 'win32' ? 'emulator.exe' : 'emulator');
    if (pathExists(p)) return p;
  }
  return undefined;
}

function resolveAdbPath() {
  const onPath = which('adb');
  if (onPath) return onPath;
  const sdk = findAndroidSdkRoot();
  if (sdk) {
    const p = path.join(sdk, 'platform-tools', process.platform === 'win32' ? 'adb.exe' : 'adb');
    if (pathExists(p)) return p;
  }
  return undefined;
}

async function listAVDs(emulatorPath) {
  return new Promise((resolve) => {
    const bin = emulatorPath || 'emulator';
    const child = spawn(bin, ['-list-avds']);
    let out = '';
    child.stdout.on('data', (d) => (out += d.toString()))
    child.stderr.on('data', () => {});
    child.on('close', () => {
      const list = out.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
      resolve(list);
    });
    child.on('error', () => resolve([]));
  });
}

async function ensureEmulatorRunning(avdName, emulatorPath, adbPath) {
  // Check if any emulator is running via `adb devices` showing emulator-XXXX
  const running = await new Promise((resolve) => {
    const child = spawn(adbPath || 'adb', ['devices']);
    let out = '';
    child.stdout.on('data', (d) => (out += d.toString()));
    child.on('close', () => {
      const emulators = out.split(/\r?\n/).filter((l) => /emulator-\d+\s+device/.test(l));
      resolve(emulators.length > 0);
    });
    child.on('error', () => resolve(false));
  });

  if (running) return true;

  if (!avdName) return false;

  console.log(`Starting Android emulator: ${avdName} ...`);
  // Start emulator in background
  spawnDetached(emulatorPath || 'emulator', ['-avd', avdName]);

  // Wait for device boot
  await new Promise((resolve) => {
    const checker = setInterval(() => {
      const c = spawn(adbPath || 'adb', ['wait-for-device']);
      c.on('close', () => {
        clearInterval(checker);
        resolve();
      });
      c.on('error', () => {});
    }, 2000);
  });

  // Additional wait until boot completed property
  await new Promise((resolve) => {
    const start = Date.now();
    const max = 120000;
    const tick = async () => {
      const getprop = spawn(adbPath || 'adb', ['shell', 'getprop', 'sys.boot_completed']);
      let out = '';
      getprop.stdout.on('data', (d) => (out += d.toString()));
      getprop.on('close', () => {
        if (out.trim() === '1') resolve();
        else if (Date.now() - start > max) resolve();
        else setTimeout(tick, 2000);
      });
      getprop.on('error', () => setTimeout(tick, 2000));
    };
    tick();
  });
  return true;
}

async function adbReverse(port, adbPath) {
  return new Promise((resolve) => {
    const child = spawn(adbPath || 'adb', ['reverse', `tcp:${port}`, `tcp:${port}`], { stdio: 'inherit' });
    child.on('close', () => resolve(true));
    child.on('error', () => resolve(false));
  });
}

async function openBrowser(url) {
  try {
    if (process.platform === 'darwin') spawnDetached('open', [url]);
    else if (process.platform === 'win32') spawnDetached('cmd', ['/c', 'start', '', url]);
    else spawnDetached('xdg-open', [url]);
  } catch {}
}

async function main() {
  const sdkRoot = findAndroidSdkRoot();
  const emulatorPath = resolveEmulatorPath();
  const adbPath = resolveAdbPath();

  console.log('Android SDK diagnostics:');
  console.log(` - ANDROID_SDK_ROOT/ANDROID_HOME: ${process.env.ANDROID_SDK_ROOT || process.env.ANDROID_HOME || '(not set)'}`);
  console.log(` - Resolved SDK root: ${sdkRoot || '(not found)'}`);
  console.log(` - emulator: ${emulatorPath || '(not found on PATH or SDK)'}`);
  console.log(` - adb: ${adbPath || '(not found on PATH or SDK)'}`);
  console.log('');

  if (!emulatorPath || !adbPath) {
    console.log('Tip: Ensure Android command line tools are installed and on PATH.');
    console.log('On macOS with Android Studio, emulator/adb are usually in ~/Library/Android/sdk/{emulator,platform-tools}');
    console.log('You can add these to PATH in ~/.zshrc, e.g.:');
    console.log('  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"');
    console.log('  export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$PATH"\n');
  }

  console.log(`Starting local dev server on ${URL} ...`);
  const server = spawnLogged('node', ['server.js'], { cwd: path.resolve(__dirname, '..') });

  // Give the server a moment to bind the port
  await new Promise((r) => setTimeout(r, 800));

  // Android emulator flow
  const avds = emulatorPath ? await listAVDs(emulatorPath) : [];
  if (!emulatorPath) {
    console.log('Cannot find `emulator` binary. Skipping emulator step.');
    console.log('Install Android Command-line tools and set PATH as noted above.');
  } else if (!avds.length) {
    console.log('No Android Virtual Devices found.');
    console.log('Open Android Studio > Device Manager and create a device, or use:');
    console.log('  avdmanager create avd -n Pixel_API_35 -k "system-images;android-35;google_apis;x86_64"');
    console.log('Then re-run this script.');
    return; // leave server running in foreground
  }

  // Ask up-front whether to open Chrome on the emulator (before booting the AVD)
  let answer = (await askQuestion('Open Chrome on the emulator to this URL? [y/N]: ')).trim().toLowerCase();
  const openOnEmu = answer === 'y' || answer === 'yes';

  console.log('\nAvailable Android Virtual Devices:');
  avds.forEach((n, i) => console.log(`  [${i + 1}] ${n}`));
  const pick = (await askQuestion('Select an AVD by number (or press Enter to skip): ')).trim();
  if (!pick) return; // leave server running
  const idx = Number(pick);
  if (!Number.isInteger(idx) || idx < 1 || idx > avds.length) {
    console.log('Invalid selection, skipping emulator step.');
    return;
  }
  const avdName = avds[idx - 1];

  const up = await ensureEmulatorRunning(avdName, emulatorPath, adbPath);
  if (!up) {
    console.log('Failed to start or detect emulator.');
    return;
  }

  if (!adbPath) {
    console.log('Cannot find `adb`, skipping adb reverse. Set PATH for platform-tools.');
  }
  const reversed = adbPath ? await adbReverse(PORT, adbPath) : false;
  if (!reversed) console.log('Warning: adb reverse failed. You may need to accept device permissions or start adb.');

  // Ask to open Chromium-based browser on the emulator
  if (openOnEmu) {
    // Use adb to launch Chrome
    // Try generic VIEW intent first (default browser), then Chrome explicitly
    const base = ['shell', 'am', 'start', '-a', 'android.intent.action.VIEW', '-d', URL];
    const adbBin = adbPath || 'adb';
    const first = spawn(adbBin, base, { stdio: 'inherit' });
    first.on('close', (code) => {
      if (code === 0) return;
      spawn(adbBin, base.concat(['com.android.chrome/com.google.android.apps.chrome.Main']), { stdio: 'inherit' });
    });
  }

  // keep server running in foreground
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
