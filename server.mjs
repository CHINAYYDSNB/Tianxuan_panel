#!/usr/bin/env node
// Combined static file server + API proxy for Tianxuan Flutter app
// Serves Flutter web build, proxies /api/v2/* to 1Panel server
//
// Usage:
//   node server.mjs                          # uses env vars or defaults
//   API_HOST=your.server node server.mjs     # custom 1Panel server
//
import http from 'http';
import fs from 'fs';
import path from 'path';

const PORT = process.env.PORT || 25568;
const API_HOST = process.env.API_HOST || 'YOUR_1PANEL_IP';
const API_PORT = process.env.API_PORT || 25567;
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
  // SPA fallback — serve index.html for unknown paths
  const fullPath = path.join(STATIC_DIR, filePath);
  if (!fs.existsSync(fullPath) || fs.statSync(fullPath).isDirectory()) {
    filePath = '/index.html';
  }
  const absPath = path.join(STATIC_DIR, filePath);
  const ext = path.extname(filePath);
  const ct = MIME[ext] || 'application/octet-stream';
  try {
    const content = fs.readFileSync(absPath);
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
  console.log('\nOpen http://localhost:' + PORT + ' in your browser.');
});
