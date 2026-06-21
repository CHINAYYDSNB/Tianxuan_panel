#!/usr/bin/env node
// ⚠️ DEPRECATED — use server.mjs instead (static + proxy in one)
// CORS proxy for 1Panel API
// forwards to 1Panel, adds CORS headers, handles errors

import http from 'http';

const PORT = process.env.PORT || 25568;
const API_HOST = process.env.API_HOST || 'YOUR_1PANEL_IP';
const API_PORT = process.env.API_PORT || 25567;

const server = http.createServer((req, res) => {
  console.log(`[proxy] ${req.method} ${req.url}`);

  // CORS headers for all responses
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, PUT, OPTIONS',
    'Access-Control-Allow-Headers': '1Panel-Token, 1Panel-Timestamp, 1Panel-Key, Content-Type, Authorization',
    'Access-Control-Expose-Headers': '*',
  };

  // OPTIONS preflight — respond immediately
  if (req.method === 'OPTIONS') {
    res.writeHead(204, { ...corsHeaders, 'Access-Control-Max-Age': '86400' });
    return res.end();
  }

  const proxyReq = http.request(
    {
      method: req.method,
      hostname: API_HOST,
      port: API_PORT,
      path: req.url,
      headers: { ...req.headers, host: `${API_HOST}:${API_PORT}` },
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode, { ...proxyRes.headers, ...corsHeaders });
      proxyRes.pipe(res);
    }
  );

  proxyReq.on('error', (e) => {
    console.error(`[proxy] Error: ${e.message}`);
    if (res.headersSent) return; // partial response already sent
    res.writeHead(502, { 'Content-Type': 'application/json', ...corsHeaders });
    res.end(JSON.stringify({ code: 502, message: `Proxy error: ${e.message}` }));
  });

  req.pipe(proxyReq);
});

server.listen(PORT, () => {
  console.log(`CORS proxy running on http://localhost:${PORT}`);
  console.log(`→ ${API_HOST}:${API_PORT}`);
  console.log('\nIn Flutter app, connect to localhost:' + PORT);
});
