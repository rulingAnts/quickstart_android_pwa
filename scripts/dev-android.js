#!/usr/bin/env node
/*
 * Dev Android Orchestrator
 * - Starts local PWA server (server.js)
 * - Ensures Android emulator/attached device is available
 * - Lists/starts an AVD if needed
 * - Waits for boot, runs `adb reverse tcp:5173 tcp:5173`
 * - Optionally opens Chrome on the emulator to http://127.0.0.1:5173/
 */

const { spawn } = require('child_process');
const readline = require('readline');
const os = require('os');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT) || 5173;
const HOST = process.env.HOST || '127.0.0.1';
const URL = `http://${HOST}:${PORT}/`;

function delay(ms) { return new Promise(r => setTimeout(r, ms)); }

function createPrompt() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.on('SIGINT', () => process.exit(0));
  return {
    ask(q) { return new Promise(res => rl.question(q, a => res(a))); },
    close() { rl.close(); },
  };
}

function run(cmd, args = [], opts = {}) {
  return new Promise((resolve) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], ...opts });
    let out = '', err = '';
    p.stdout.on('data', d => out += d.toString());
    p.stderr.on('data', d => err += d.toString());
    p.on('close', code => resolve({ code, out, err }));
  });
}

async function ensureTools() {
  // Try PATH first
  let adb = 'adb';
  let emulator = 'emulator';

  async function exists(bin) {
    const res = await run(process.platform === 'win32' ? 'where' : 'which', [bin]);
    return res.code === 0 && res.out.trim();
  }

  let adbOk = await exists('adb');
  let emuOk = await exists('emulator');

  if (!adbOk || !emuOk) {
    // Try common macOS SDK paths
    const sdk = path.join(os.homedir(), 'Library', 'Android', 'sdk');
    const tryAdb = path.join(sdk, 'platform-tools', process.platform === 'win32' ? 'adb.exe' : 'adb');
    const tryEmu = path.join(sdk, 'emulator', process.platform === 'win32' ? 'emulator.exe' : 'emulator');
    if (fs.existsSync(tryAdb)) { adb = tryAdb; adbOk = true; }
    if (fs.existsSync(tryEmu)) { emulator = tryEmu; emuOk = true; }
  }

  if (!adbOk || !emuOk) {
    console.log('Could not locate adb/emulator on PATH.');
    console.log('On macOS with Android Studio, they are usually in ~/Library/Android/sdk/{platform-tools,emulator}');
  }

  return { adb, emulator };
}

async function listDevices(adb) {
  const res = await run(adb, ['devices']);
  const lines = res.out.trim().split('\n').slice(1).map(l => l.trim()).filter(Boolean);
  const devices = lines
    .map(l => l.split(/\s+/))
    .filter(parts => parts[1] === 'device')
    .map(parts => parts[0]);
  return devices;
}

async function listAvds(emulator) {
  const res = await run(emulator, ['-list-avds']);
  if (res.code !== 0) return [];
  return res.out.trim().split('\n').map(s => s.trim()).filter(Boolean);
}

async function startAvd(emulator, avdName) {
  // Start headless (-no-boot-anim for faster boot)
  const child = spawn(emulator, ['-avd', avdName, '-no-boot-anim'], { stdio: 'ignore', detached: true });
  child.unref();
}

async function waitForBoot(adb) {
  await run(adb, ['wait-for-device']);
  // Poll sys.boot_completed until '1'
  for (let i = 0; i < 120; i++) {
    const r = await run(adb, ['shell', 'getprop', 'sys.boot_completed']);
    if (r.out.trim() === '1') return true;
    await delay(1000);
  }
  return false;
}

async function adbReverse(adb, port) {
  await run(adb, ['reverse', `tcp:${port}`, `tcp:${port}`]);
}

async function openChrome(adb, url) {
  // Try Chrome first, fallback to default Activity
  const tryChrome = await run(adb, ['shell', 'pm', 'path', 'com.android.chrome']);
  if (tryChrome.code === 0 && tryChrome.out.includes('package:')) {
    await run(adb, ['shell', 'am', 'start', '-n', 'com.android.chrome/com.google.android.apps.chrome.Main', '-d', url]);
  } else {
    await run(adb, ['shell', 'am', 'start', '-a', 'android.intent.action.VIEW', '-d', url]);
  }
}

async function startServer() {
  // Start server.js child; leave it running until this process exits
  const child = spawn(process.execPath, [path.join(__dirname, '..', 'server.js')], { stdio: 'pipe' });
  child.stdout.on('data', d => process.stdout.write(d));
  child.stderr.on('data', d => process.stderr.write(d));
  // Give it a moment to bind
  await delay(800);
  return child;
}

(async () => {
  console.log('Dev Android orchestrator starting...');
  const prompt = createPrompt();
  let serverProc;
  try {
    // Start server
    serverProc = await startServer();
    console.log(`Local server should be at ${URL}`);

    // Tools
    const { adb, emulator } = await ensureTools();

    // Devices check
    let devices = await listDevices(adb);
    if (!devices.length) {
      // No device: list AVDs
      const avds = await listAvds(emulator);
      if (!avds.length) {
        console.log('No AVDs found. Create one in Android Studio > Device Manager.');
        process.exit(1);
      }
      console.log('Available AVDs:');
      avds.forEach((n, i) => console.log(`  [${i+1}] ${n}`));
      const ans = await prompt.ask('Select an AVD to start (number): ');
      const idx = Math.max(1, Math.min(avds.length, parseInt(ans, 10) || 1)) - 1;
      const name = avds[idx];
      console.log(`Starting AVD: ${name} ...`);
      await startAvd(emulator, name);
      const ok = await waitForBoot(adb);
      if (!ok) throw new Error('Timed out waiting for emulator to boot.');
      devices = await listDevices(adb);
      if (!devices.length) throw new Error('Emulator failed to appear as an adb device.');
    }

    // If multiple, pick first (or let user choose in future)
    console.log(`Using device: ${devices[0]}`);

    // Reverse port
    await adbReverse(adb, PORT);
    console.log(`adb reverse set for tcp:${PORT} -> tcp:${PORT}`);

    const open = await prompt.ask('Open Chrome on the device to the dev URL now? [Y/n] ');
    if (!open || /^y/i.test(open)) {
      console.log('Launching browser on device...');
      await openChrome(adb, URL);
      console.log('If the page does not load, ensure the port reverse is listed in: adb reverse --list');
    } else {
      console.log(`You can manually open ${URL} in the device browser.`);
    }

    console.log('Press Ctrl+C to stop. The server will terminate with this process.');
  } catch (e) {
    console.error('Error:', e && e.message ? e.message : e);
    process.exitCode = 1;
  }
})();
