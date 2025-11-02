#!/usr/bin/env node
/*
 * Pull a file from /sdcard/Download on a connected Android device/emulator.
 * - Lists files (ls -lhat), filters .zip as candidates
 * - Press Enter to pick the most recent ZIP by mtime
 * - Or type a number from the list, or type an exact filename
 * - Pulls to ~/Downloads
 */

const { spawn } = require('child_process');
const readline = require('readline');
const os = require('os');
const path = require('path');

function run(cmd, args = [], opts = {}) {
  return new Promise((resolve) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], ...opts });
    let out = '', err = '';
    p.stdout.on('data', d => out += d.toString());
    p.stderr.on('data', d => err += d.toString());
    p.on('close', code => resolve({ code, out, err }));
  });
}

function createPrompt() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  rl.on('SIGINT', () => process.exit(0));
  return {
    ask(q) { return new Promise(res => rl.question(q, a => res(a))); },
    close() { rl.close(); },
  };
}

async function ensureDevice() {
  const res = await run('adb', ['devices']);
  const lines = res.out.trim().split('\n').slice(1).map(l => l.trim()).filter(Boolean);
  const devices = lines.map(l => l.split(/\s+/)).filter(p => p[1] === 'device').map(p => p[0]);
  if (!devices.length) throw new Error('No devices found. Start an emulator or connect a device.');
  return devices[0];
}

async function listDownloads() {
  const res = await run('adb', ['shell', 'ls', '-lhat', '/sdcard/Download']);
  if (res.code !== 0) throw new Error('Failed to list /sdcard/Download');
  const lines = res.out.split('\n').filter(l => l && !l.endsWith(' .') && !l.endsWith(' ..'));
  return lines;
}

function parseZipCandidates(lines) {
  // Typical ls -lhat format; filename is after the last whitespace block
  const entries = lines.map(l => {
    const parts = l.trim().split(/\s+/);
    const name = parts.slice(8).join(' ');
    return { raw: l, name };
  }).filter(e => e.name && e.name !== '.' && e.name !== '..');

  const zips = entries.filter(e => /\.zip$/i.test(e.name));
  return { entries, zips };
}

async function pull(remote, destDir) {
  const res = await run('adb', ['pull', `/sdcard/Download/${remote}`, destDir]);
  if (res.code !== 0) throw new Error(res.err || 'adb pull failed');
  return res.out.trim();
}

(async () => {
  const prompt = createPrompt();
  try {
    await ensureDevice();
    const lines = await listDownloads();
    const { entries, zips } = parseZipCandidates(lines);

    console.log('Files in /sdcard/Download (most recent first):');
    entries.forEach((e, i) => console.log(`[${i+1}] ${e.name}`));

    let suggestion = zips.length ? zips[0].name : (entries[0] ? entries[0].name : null);
    const ans = await prompt.ask(`Choose file to pull (number or filename) [Enter for latest ${suggestion || 'N/A'}]: `);

    let choice = ans.trim();
    if (!choice) choice = suggestion || '';

    if (!choice) throw new Error('No files found to pull.');

    let filename = choice;
    const idx = Number(choice);
    if (Number.isInteger(idx) && idx >= 1 && idx <= entries.length) {
      filename = entries[idx - 1].name;
    }

    const destDir = path.join(os.homedir(), 'Downloads');
    console.log(`Pulling ${filename} -> ${destDir}`);
    const output = await pull(filename, destDir);
    console.log(output);
    console.log('Done.');
  } catch (e) {
    console.error('Error:', e && e.message ? e.message : e);
    process.exitCode = 1;
  } finally {
    prompt.close();
  }
})();
