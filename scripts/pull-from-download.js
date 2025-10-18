#!/usr/bin/env node
/**
 * Lists /sdcard/Download on an Android device/emulator, then prompts for a filename
 * and pulls it to the host ~/Downloads directory.
 * - If no devices are connected, offers to start an AVD and lets you select.
 * - If multiple devices are connected, prompts to select one.
 */
const { spawn, spawnSync } = require('child_process');
const os = require('os');
const path = require('path');
const readline = require('readline');

function askQuestion(query) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => rl.question(query, (ans) => { rl.close(); resolve(ans); }));
}

function adbCmd(args, opts = {}) {
  const res = spawnSync('adb', args, { encoding: 'utf8', ...opts });
  if (res.error) throw res.error;
  return res;
}

function ensureAdb() {
  const res = spawnSync('adb', ['version'], { encoding: 'utf8' });
  if (res.status !== 0) throw new Error('adb not found on PATH. Install Android platform-tools and add to PATH.');
}

function getConnectedDevices() {
  const out = adbCmd(['devices']).stdout || '';
  const lines = out.split(/\r?\n/).filter(Boolean);
  return lines.slice(1)
    .map((l) => l.trim().split(/\s+/))
    .filter((p) => p[1] === 'device')
    .map((p) => p[0]);
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

function findAndroidSdkRoot() {
  const env = process.env.ANDROID_SDK_ROOT || process.env.ANDROID_HOME;
  if (env) return env;
  if (process.platform === 'darwin') return path.join(os.homedir(), 'Library', 'Android', 'sdk');
  if (process.platform === 'linux') return path.join(os.homedir(), 'Android', 'Sdk');
  if (process.platform === 'win32') return process.env.LOCALAPPDATA ? path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk') : undefined;
}

function resolveEmulatorPath() {
  const onPath = which('emulator');
  if (onPath) return onPath;
  const sdk = findAndroidSdkRoot();
  if (sdk) return path.join(sdk, 'emulator', process.platform === 'win32' ? 'emulator.exe' : 'emulator');
}

async function listAVDs(emulatorPath) {
  return new Promise((resolve) => {
    const bin = emulatorPath || 'emulator';
    const child = spawn(bin, ['-list-avds']);
    let out = '';
    child.stdout.on('data', (d) => (out += d.toString()));
    child.on('close', () => resolve(out.split(/\r?\n/).map(s => s.trim()).filter(Boolean)));
    child.on('error', () => resolve([]));
  });
}

async function ensureDevice(serial, emulatorPath) {
  const devs = getConnectedDevices();
  if (serial && devs.includes(serial)) return serial;
  if (devs.length === 1) return devs[0];
  if (devs.length > 1) {
    console.log('Connected devices:');
    devs.forEach((d, i) => console.log(`  [${i + 1}] ${d}`));
    const pick = (await askQuestion('Pick device number (or Enter to cancel): ')).trim();
    if (!pick) throw new Error('Cancelled.');
    const idx = Number(pick);
    if (!Number.isInteger(idx) || idx < 1 || idx > devs.length) throw new Error('Invalid selection.');
    return devs[idx - 1];
  }
  // No devices: offer to start an AVD
  const want = (await askQuestion('No devices connected. Start an Android Virtual Device now? [y/N]: ')).trim().toLowerCase();
  const yes = want === 'y' || want === 'yes';
  if (!yes) throw new Error('No device connected.');
  const avds = await listAVDs(emulatorPath);
  if (!emulatorPath) throw new Error('Cannot find emulator. Ensure Android SDK is installed and emulator is on PATH.');
  if (!avds.length) throw new Error('No AVDs found. Create one in Android Studio > Device Manager.');
  console.log('Available AVDs:');
  avds.forEach((n, i) => console.log(`  [${i + 1}] ${n}`));
  const choice = (await askQuestion('Select an AVD number: ')).trim();
  const idx = Number(choice);
  if (!Number.isInteger(idx) || idx < 1 || idx > avds.length) throw new Error('Invalid selection.');
  const bin = emulatorPath || 'emulator';
  const em = spawn(bin, ['-avd', avds[idx - 1]], { stdio: 'ignore', detached: true });
  em.unref();
  // wait until adb sees a device
  await new Promise((resolve) => {
    const t = setInterval(() => {
      if (getConnectedDevices().length > 0) { clearInterval(t); resolve(); }
    }, 2000);
  });
  return getConnectedDevices()[0];
}

function shell(deviceArgs, cmd) {
  return adbCmd(deviceArgs.concat(['shell', 'sh', '-c', cmd]));
}

async function main() {
  ensureAdb();
  const emulatorPath = resolveEmulatorPath();
  const serialFlag = process.argv.find(a => a.startsWith('--serial='));
  const serialOpt = serialFlag ? serialFlag.split('=')[1] : undefined;
  const serial = await ensureDevice(serialOpt, emulatorPath);
  const deviceArgs = serial ? ['-s', serial] : [];
  console.log(`Using device: ${serial}`);

  // Run ls and capture output
  // Use -lhat: long format, human sizes, all files, sort by modification time (newest first)
  const lsRes = adbCmd(deviceArgs.concat(['shell', 'ls', '-lhat', '/sdcard/Download']), { encoding: 'utf8' });
  const out = (lsRes.stdout || '').toString();
  console.log(out);

  // Parse potential .zip filenames from ls output (last column typically filename)
  const lines = out.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  const zipRegex = /\.zip$/i;
  const zips = [];
  for (const line of lines) {
    // Skip total lines or directory entries
    if (/^total\b/i.test(line)) continue;
    const parts = line.split(/\s+/);
    const name = parts[parts.length - 1];
    if (zipRegex.test(name)) zips.push(name);
  }

  if (zips.length) {
    console.log('ZIP files found:');
    zips.forEach((z, i) => console.log(`  [${i + 1}] ${z}`));
  } else {
    console.log('No .zip files detected in /sdcard/Download. You can still type a name manually.');
  }

  // Prompt for selection or manual filename
  let filename = (await askQuestion('Select ZIP by number (Enter = latest by mtime), or type an exact filename: ')).trim();
  if (!filename) {
    if (zips.length) {
      filename = zips[0]; // ls -lah is not guaranteed sorted, but list order is as parsed; we showed in the listed order
      console.log(`Selected latest ZIP by default: ${filename}`);
    } else {
      console.log('No filename provided and no ZIPs detected. Exiting.');
      return;
    }
  }
  const idx = Number(filename);
  if (Number.isInteger(idx) && idx >= 1 && idx <= zips.length) {
    filename = zips[idx - 1];
  }

  const remote = `/sdcard/Download/${filename}`;
  const destDir = path.join(os.homedir(), 'Downloads');
  const destPath = path.join(destDir, path.basename(filename));
  console.log(`Pulling ${remote} -> ${destPath}`);
  await new Promise((resolve, reject) => {
    const pull = spawn('adb', deviceArgs.concat(['pull', remote, destPath]), { stdio: 'inherit' });
    pull.on('close', (code) => (code === 0 ? resolve() : reject(new Error(`adb pull exited with code ${code}`))));
    pull.on('error', reject);
  });
  console.log('Done.');
}

main().catch((e) => {
  console.error(e.message || String(e));
  process.exit(1);
});
