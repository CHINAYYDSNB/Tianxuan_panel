#!/usr/bin/env node
// Combined static file server + API proxy for Tianxuan Flutter app
// Serves Flutter web build, proxies /api/v2/* to 1Panel server
//
// Usage:
//   node server.mjs
//
// Environment variables (or create .env file):
//   API_HOST   — 1Panel server IP (default: placeholder)
//   API_PORT   — 1Panel server port (default: 25567)
//   PORT       — dev server port   (default: 25568)
//   API_KEY    — API Key for auto-login (optional, omit to use login page)

import http from 'http';
import fs from 'fs';
import path from 'path';

// Load .env file if exists
const envPath = path.resolve(import.meta.dirname, '.env');
if (fs.existsSync(envPath)) {
  const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
  for (const line of lines) {
    const m = line.match(/^\s*(\w+)=(.*)$/);
    if (m) process.env[m[1]] = m[1].trim();
  }
}

const PORT       = parseInt(process.env.PORT || '25568', 10);
const API_HOST   = process.env.API_HOST || 'your.1panel.server.ip';
const API_PORT   = parseInt(process.env.API_PORT || '25567', 10);
const API_KEY    = process.env.API_KEY || '';
const STATIC_DIR = path.resolve(import.meta.dirname, 'build', 'web');

const MIME = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.map': 'application/json',
  '.txt': 'text/plain',
};

function serveStatic(req, res) {
  let filePath = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  const fullPath = path.join(STATIC_DIR, filePath);
  if (!fs.existsSync(fullPath) || fs.statSync(fullPath).isDirectory()) {
    filePath = '/index.html';
  }
  const absPath = path.join(STATIC_DIR, filePath);
  const ext = path.extname(filePath);
  const ct = MIME[ext] || 'application/octet-stream';
  try {
    let content = fs.readFileSync(absPath);
    // Dev helper: inject localStorage config to skip login page
    if (filePath === '/index.html' && API_KEY) {
      const inject = `<script>
localStorage.setItem('server_url','http://localhost:${PORT}');
localStorage.setItem('api_key','${API_KEY}');
</script>`;
      content = Buffer.from(content.toString().replace('</head>', inject + '</head>'));
    }
    res.writeHead(200, { 'Content-Type': ct, 'Cache-Control': 'no-cache' });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end('Not found');
  }
}

function proxyAPI(req, res) {
  console.log(`[proxy] ${req.method} ${req.url}`);
  const proxyReq = http.request(
    {
      method: req.method,
      hostname: API_HOST,
      port: API_PORT,
      path: req.url,
      headers: { ...req.headers, host: `${API_HOST}:${API_PORT}` },
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode, { ...proxyRes.headers });
      proxyRes.pipe(res);
    }
  );
  proxyReq.on('error', (e) => {
    console.error(`[proxy] Error: ${e.message}`);
    if (res.headersSent) return;
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ code: 502, message: `Proxy error: ${e.message}` }));
  });
  req.pipe(proxyReq);
}

http.createServer((req, res) => {
  if (req.url.startsWith('/api/v2/')) {
    proxyAPI(req, res);
  } else {
    serveStatic(req, res);
  }
}).listen(PORT, '0.0.0.0', () => {
  console.log(`Tianxuan app → http://localhost:${PORT}`);
  console.log(`Static: ${STATIC_DIR}`);
  console.log(`API proxy: → ${API_HOST}:${API_PORT}`);
  if (API_KEY) console.log('Auto-login: enabled (API_KEY set)');
  else         console.log('Auto-login: disabled (use login page)');
  console.log('\nOpen http://localhost:' + PORT + ' in your browser.');
});
