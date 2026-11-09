'use strict';
// Integrationstest: echter Server auf zufälligem Port, zwei WebSocket-Clients.
const test = require('node:test');
const assert = require('node:assert');
const os = require('os');
const path = require('path');
const fs = require('fs');

process.env.DATA_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'aura-'));
const WebSocket = require('ws');
const { server } = require('../server.js');

let port;
test.before(() => new Promise((r) => server.listen(0, () => { port = server.address().port; r(); })));
test.after(() => new Promise((r) => { for (const c of require('../server.js').players.values()) c.ws.terminate(); server.close(() => r()); }));

function client(name) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
    const inbox = [];
    const waiters = [];
    ws.on('message', (d) => {
      const m = JSON.parse(d.toString()); inbox.push(m);
      for (const w of [...waiters]) if (w.pred(m)) { waiters.splice(waiters.indexOf(w), 1); w.res(m); }
    });
    ws.on('error', reject);
    ws.on('open', () => {
      const c = {
        ws, inbox,
        send: (m) => ws.send(JSON.stringify(m)),
        wait: (pred, ms = 3000) => new Promise((res, rej) => {
          const hit = inbox.find(pred); if (hit) return res(hit);
          const w = { pred, res }; waiters.push(w);
          setTimeout(() => rej(new Error('Timeout beim Warten auf Nachricht')), ms);
        }),
      };
      c.send({ t: 'hello', name, ver: 'test' });
      resolve(c);
    });
  });
}

test('Statusseite und API antworten', async () => {
  const html = await (await fetch(`http://127.0.0.1:${port}/`)).text();
  assert.match(html, /Aura Farm Server/);
  const s = await (await fetch(`http://127.0.0.1:${port}/api/status`)).json();
  assert.equal(s.online, 0);
  assert.equal((await fetch(`http://127.0.0.1:${port}/healthz`)).status, 200);
});

test('zwei Spieler sehen sich, Tricks und Bestenliste', async () => {
  const a = await client('Elias');
  const wa = await a.wait((m) => m.t === 'welcome');
  assert.equal(wa.name, 'Elias');
  const b = await client('Elias'); // gleicher Name -> wird eindeutig gemacht
  const wb = await b.wait((m) => m.t === 'welcome');
  assert.equal(wb.name, 'Elias#2');
  assert.equal(wb.players.length, 1);
  await a.wait((m) => m.t === 'join' && m.name === 'Elias#2');

  a.send({ t: 'state', p: [1, 0, 2], yaw: 1.5, vape: 3, aura: 12345, farmed: 20000 });
  const st = await b.wait((m) => m.t === 'states' && m.list.some((p) => p.id === wa.id && p.aura === 12345));
  assert.deepEqual(st.list.find((p) => p.id === wa.id).p, [1, 0, 2]);

  a.send({ t: 'trick', id: 'tornado', st: 0.8, p: [1, 1.6, 2], dir: [0, 0, -1] });
  const tr = await b.wait((m) => m.t === 'trick');
  assert.equal(tr.id, 'tornado'); assert.equal(tr.from, wa.id); assert.equal(tr.vape, 3);

  a.send({ t: 'trick', id: 'hack', st: 1 }); // unbekannter Trick wird ignoriert
  a.send({ t: 'chat', msg: 'Sheeesh' });
  const ch = await b.wait((m) => m.t === 'chat');
  assert.equal(ch.msg, 'Sheeesh');

  const s = await (await fetch(`http://127.0.0.1:${port}/api/status`)).json();
  assert.equal(s.online, 2);
  assert.equal(s.board[0].name, 'Elias'); assert.equal(s.board[0].aura, 12345);
  assert.ok(!b.inbox.some((m) => m.t === 'trick' && m.id === 'hack'));

  b.ws.close();
  await a.wait((m) => m.t === 'leave' && m.id === wb.id);
  a.ws.close();
});

test('Kaputte Nachrichten bringen den Server nicht um', async () => {
  const c = await client('<script>x');
  const w = await c.wait((m) => m.t === 'welcome');
  assert.equal(w.name, 'scriptx');
  c.ws.send('kein json'); c.ws.send(JSON.stringify({ t: 'state', p: 'quatsch', aura: 'viel' }));
  c.send({ t: 'ping', ts: 1 });
  await c.wait((m) => m.t === 'pong');
  c.ws.close();
});
