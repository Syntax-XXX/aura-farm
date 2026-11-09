'use strict';
/*
 * Aura Farm – Multiplayer-Server
 *
 * Ein einziger HTTP-Port:
 *   GET  /            Statusseite (Website) mit Spielern online und Bestenliste
 *   GET  /api/status  dasselbe als JSON
 *   GET  /healthz     Health-Check für Docker / Hoster
 *   WS   /ws          Spielprotokoll (JSON-Textnachrichten)
 *
 * Läuft überall, wo Node.js läuft – auch bei Gratis-Hostern (Render, Fly.io,
 * Koyeb, Railway …). Port kommt aus $PORT (Standard 8080).
 *
 * Protokoll (siehe README.md):
 *   Client → Server  hello {name, ver} · state {p:[x,y,z], yaw, vape, aura, farmed} · trick {id, st, p, dir} · chat {msg}
 *   Server → Client  welcome {id, name, players, board} · join · leave · states {list} · trick · board · chat · error
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { WebSocketServer } = require('ws');

const VERSION = require('./package.json').version;
const PORT = +process.env.PORT || 8080;
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const MAX_PLAYERS = +process.env.MAX_PLAYERS || 32;
const TICK_MS = 100; // 10 Zustands-Updates pro Sekunde
const TRICK_IDS = new Set(['plain', 'ghost', 'orings', 'french', 'dragon', 'tornado', 'jelly', 'bane', 'wall', 'dtornado', 'mushroom', 'fogbank', 'citynebel']);

/* ── Bestenliste (beste Aura je Name, dauerhaft gespeichert) ── */
const BOARD_FILE = path.join(DATA_DIR, 'leaderboard.json');
let board = {};
try { board = JSON.parse(fs.readFileSync(BOARD_FILE, 'utf8')); } catch { board = {}; }
let boardDirty = false;
function saveBoard() {
  if (!boardDirty) return;
  try {
    fs.mkdirSync(DATA_DIR, { recursive: true });
    fs.writeFileSync(BOARD_FILE + '.tmp', JSON.stringify(board));
    fs.renameSync(BOARD_FILE + '.tmp', BOARD_FILE);
    boardDirty = false;
  } catch (e) { console.error('Bestenliste speichern fehlgeschlagen:', e.message); }
}
setInterval(saveBoard, 30000).unref();
function topBoard(n = 20) {
  return Object.entries(board).map(([name, v]) => ({ name, aura: v.aura, vape: v.vape })).sort((a, b) => b.aura - a.aura).slice(0, n);
}

/* ── Spieler ── */
const players = new Map(); // id -> player
let nextId = 1;
const startedAt = Date.now();

const num = (v, min, max, def = 0) => (typeof v === 'number' && Number.isFinite(v) ? Math.min(max, Math.max(min, v)) : def);
const vec = (a, lim) => (Array.isArray(a) && a.length === 3 ? a.map((x) => num(x, -lim, lim)) : [0, 0, 0]);
function cleanName(n) {
  let s = typeof n === 'string' ? n.replace(/[^\p{L}\p{N} _.\-]/gu, '').trim().slice(0, 16) : '';
  if (!s) s = 'Spieler';
  const taken = new Set([...players.values()].map((p) => p.name.toLowerCase()));
  let name = s, i = 2;
  while (taken.has(name.toLowerCase())) name = `${s.slice(0, 13)}#${i++}`;
  return name;
}
function pub(p) { return { id: p.id, name: p.name, p: p.p, yaw: p.yaw, vape: p.vape, aura: Math.round(p.aura) }; }
function send(ws, msg) { if (ws.readyState === 1) ws.send(JSON.stringify(msg)); }
function broadcast(msg, except) {
  const s = JSON.stringify(msg);
  for (const p of players.values()) if (p !== except && p.ws.readyState === 1) p.ws.send(s);
}

/* ── HTTP (Website + API) ── */
const STATUS_HTML = fs.readFileSync(path.join(__dirname, 'public', 'index.html'));
function status() {
  return {
    name: 'Aura Farm Server', version: VERSION, uptime_s: Math.round((Date.now() - startedAt) / 1000),
    online: players.size, max: MAX_PLAYERS,
    players: [...players.values()].map((p) => ({ name: p.name, aura: Math.round(p.aura), vape: p.vape })).sort((a, b) => b.aura - a.aura),
    board: topBoard(),
  };
}
const server = http.createServer((req, res) => {
  const url = (req.url || '/').split('?')[0];
  if (url === '/healthz') { res.writeHead(200, { 'Content-Type': 'text/plain' }); return res.end('ok'); }
  if (url === '/api/status') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8', 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'no-store' });
    return res.end(JSON.stringify(status()));
  }
  if (url === '/' || url === '/index.html') { res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); return res.end(STATUS_HTML); }
  res.writeHead(404, { 'Content-Type': 'text/plain' }); res.end('nicht gefunden');
});

/* ── WebSocket ── */
const wss = new WebSocketServer({ noServer: true, maxPayload: 4096 });
server.on('upgrade', (req, socket, head) => {
  // jeden Pfad akzeptieren, der auf /ws endet (auch hinter Reverse-Proxys mit Präfix)
  if (!(req.url || '').split('?')[0].endsWith('/ws')) { socket.destroy(); return; }
  wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
});

wss.on('connection', (ws) => {
  let me = null;
  let budget = 40, last = Date.now(); // einfache Ratenbegrenzung: ~40 Nachrichten/s
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });
  const helloTimer = setTimeout(() => { if (!me) ws.close(4000, 'kein hello'); }, 10000);

  ws.on('message', (raw, isBinary) => {
    const now = Date.now();
    budget = Math.min(40, budget + ((now - last) / 1000) * 40); last = now;
    if (budget < 1) return; budget--;
    if (isBinary) return;
    let m; try { m = JSON.parse(raw.toString()); } catch { return; }
    if (!m || typeof m.t !== 'string') return;

    if (m.t === 'hello' && !me) {
      if (players.size >= MAX_PLAYERS) { send(ws, { t: 'error', msg: 'Server voll' }); ws.close(4001, 'voll'); return; }
      clearTimeout(helloTimer);
      me = { id: nextId++, ws, name: cleanName(m.name), p: [0, 0, 18], yaw: 0, vape: 0, aura: 0, farmed: 0 };
      players.set(me.id, me);
      send(ws, { t: 'welcome', id: me.id, name: me.name, ver: VERSION, players: [...players.values()].filter((p) => p !== me).map(pub), board: topBoard(10) });
      broadcast({ t: 'join', ...pub(me) }, me);
      console.log(`+ ${me.name} (${players.size} online)`);
      return;
    }
    if (!me) return;
    switch (m.t) {
      case 'state':
        me.p = vec(m.p, 500); me.yaw = num(m.yaw, -1e4, 1e4);
        me.vape = Math.round(num(m.vape, 0, 6)); me.aura = num(m.aura, -1e12, 1e12); me.farmed = num(m.farmed, 0, 1e12);
        if (me.aura > (board[me.name]?.aura ?? -Infinity)) { board[me.name] = { aura: Math.round(me.aura), vape: me.vape }; boardDirty = true; }
        break;
      case 'trick':
        if (!TRICK_IDS.has(m.id)) return;
        broadcast({ t: 'trick', from: me.id, id: m.id, st: num(m.st, 0, 1, 0.5), p: vec(m.p, 500), dir: vec(m.dir, 1), vape: me.vape, ok: m.ok !== false }, me);
        break;
      case 'chat': {
        const msg = typeof m.msg === 'string' ? m.msg.trim().slice(0, 120) : '';
        if (msg) broadcast({ t: 'chat', from: me.id, name: me.name, msg });
        break;
      }
      case 'ping':
        send(ws, { t: 'pong', ts: m.ts });
        break;
    }
  });
  ws.on('close', () => {
    clearTimeout(helloTimer);
    if (me) { players.delete(me.id); broadcast({ t: 'leave', id: me.id }); console.log(`- ${me.name} (${players.size} online)`); }
  });
  ws.on('error', () => {});
});

// Zustände an alle verteilen
setInterval(() => {
  if (players.size < 2) return;
  const list = [...players.values()].map(pub);
  broadcast({ t: 'states', list });
}, TICK_MS).unref();
// Bestenliste regelmäßig an alle
setInterval(() => { if (players.size) broadcast({ t: 'board', top: topBoard(10) }); }, 5000).unref();
// tote Verbindungen aufräumen
setInterval(() => {
  for (const ws of wss.clients) { if (!ws.isAlive) { ws.terminate(); continue; } ws.isAlive = false; ws.ping(); }
}, 20000).unref();

function shutdown() { saveBoard(); process.exit(0); }
process.on('SIGTERM', shutdown); process.on('SIGINT', shutdown);

if (require.main === module) {
  server.listen(PORT, () => console.log(`Aura Farm Server ${VERSION} läuft auf Port ${PORT} (WebSocket: /ws)`));
}
module.exports = { server, players, topBoard };
