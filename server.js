#!/usr/bin/env node
/* Simple static dev server for the PWA (document root: ./www)
 * - Serves files with correct MIME types
 * - SPA fallback to index.html
 * - Proper headers for service worker and HTML (no-cache)
 * - Optional --open to launch default browser
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = Number(process.env.PORT) || 5173;
const HOST = process.env.HOST || '127.0.0.1';
const ROOT = path.resolve(__dirname, 'www');

function guessContentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  switch (ext) {
    case '.html': return 'text/html; charset=utf-8';
    case '.css': return 'text/css; charset=utf-8';
    case '.js': return 'application/javascript; charset=utf-8';
    case '.mjs': return 'application/javascript; charset=utf-8';
    case '.json': return 'application/json; charset=utf-8';
    case '.webmanifest': return 'application/manifest+json; charset=utf-8';
    case '.svg': return 'image/svg+xml';
    case '.png': return 'image/png';
    case '.jpg':
    case '.jpeg': return 'image/jpeg';
    case '.gif': return 'image/gif';
    case '.webp': return 'image/webp';
    case '.ico': return 'image/x-icon';
    case '.wav': return 'audio/wav';
    case '.mp3': return 'audio/mpeg';
    case '.ogg': return 'audio/ogg';
    case '.mp4': return 'video/mp4';
    case '.wasm': return 'application/wasm';
    case '.txt': return 'text/plain; charset=utf-8';
    default: return 'application/octet-stream';
  }
}

function isPathInside(child, parent) {
  const rel = path.relative(parent, child);
  return !!rel && !rel.startsWith('..') && !path.isAbsolute(rel);
}

function send(res, status, headers, bodyStream) {
  res.writeHead(status, headers);
  if (bodyStream) bodyStream.pipe(res); else res.end();
}

function serveFile(req, res, fsPath) {
  const type = guessContentType(fsPath);
  const noCache = type.startsWith('text/html') || fsPath.endsWith('/service-worker.js') || fsPath.endsWith('manifest.json');
  const headers = {
    'Content-Type': type,
    'Cache-Control': noCache ? 'no-cache, no-store, must-revalidate' : 'public, max-age=3600',
  };
  // Service worker recommended header for scope overrides (not required here, but harmless)
  if (fsPath.endsWith('/service-worker.js')) headers['Service-Worker-Allowed'] = '/';

  try {
    const stream = fs.createReadStream(fsPath);
    stream.on('error', () => send(res, 404, { 'Content-Type': 'text/plain' }, null));
    send(res, 200, headers, stream);
  } catch (e) {
    send(res, 404, { 'Content-Type': 'text/plain' }, null);
  }
}

const server = http.createServer((req, res) => {
  if (!req.url) return send(res, 400, { 'Content-Type': 'text/plain' }, null);
  const rawUrl = decodeURI(req.url.split('?')[0]);

  // Default to index for root
  let fsPath = path.join(ROOT, rawUrl === '/' ? '/index.html' : rawUrl);
  fsPath = path.normalize(fsPath);
  if (!isPathInside(fsPath, ROOT)) {
    return send(res, 403, { 'Content-Type': 'text/plain' }, null);
  }

  // If requesting a directory, try index.html
  if (fs.existsSync(fsPath) && fs.statSync(fsPath).isDirectory()) {
    fsPath = path.join(fsPath, 'index.html');
  }

  if (fs.existsSync(fsPath) && fs.statSync(fsPath).isFile()) {
    return serveFile(req, res, fsPath);
  }

  // SPA fallback for GET requests: serve index.html
  if (req.method === 'GET' || req.method === 'HEAD') {
    const indexPath = path.join(ROOT, 'index.html');
    if (fs.existsSync(indexPath)) {
      return serveFile(req, res, indexPath);
    }
  }

  send(res, 404, { 'Content-Type': 'text/plain' }, null);
});

server.listen(PORT, HOST, () => {
  const url = `http://${HOST}:${PORT}/`;
  console.log(`PWA dev server running at ${url}`);
  if (process.argv.includes('--open')) {
    const platform = process.platform;
    try {
      if (platform === 'darwin') spawn('open', [url], { stdio: 'ignore', detached: true });
      else if (platform === 'win32') spawn('cmd', ['/c', 'start', '', url], { stdio: 'ignore', detached: true });
      else spawn('xdg-open', [url], { stdio: 'ignore', detached: true });
    } catch (e) {
      console.warn('Failed to open browser automatically:', e && e.message);
    }
  }
});
