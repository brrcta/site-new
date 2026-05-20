#!/usr/bin/env node
'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const PENDING_FILE = process.env.GB_PENDING || '/var/www/florianvasin.com/guestbook-pending.json';
const PORT = parseInt(process.env.GB_PORT || '8041', 10);
const HOST = '127.0.0.1';

const CORS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

function load() {
    try { return JSON.parse(fs.readFileSync(PENDING_FILE, 'utf8')); }
    catch { return []; }
}

function save(data) {
    fs.mkdirSync(path.dirname(PENDING_FILE), { recursive: true });
    fs.writeFileSync(PENDING_FILE, JSON.stringify(data, null, 2));
}

const server = http.createServer((req, res) => {
    if (req.method === 'OPTIONS') {
        res.writeHead(200, CORS);
        res.end();
        return;
    }

    if (req.method !== 'POST' || req.url !== '/api/guestbook') {
        res.writeHead(404);
        res.end();
        return;
    }

    let body = '';
    req.on('data', chunk => { body += chunk; if (body.length > 4096) req.destroy(); });
    req.on('end', () => {
        let parsed;
        try { parsed = JSON.parse(body); }
        catch { res.writeHead(400); res.end(); return; }

        const name = String(parsed.name || '').trim().slice(0, 60);
        const text = String(parsed.text || '').trim().slice(0, 600);

        if (!name || !text) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'name and text required' }));
            return;
        }

        const entry = {
            name,
            text,
            ts: Date.now(),
            ip: req.headers['x-real-ip'] || req.socket.remoteAddress,
        };

        const data = load();
        data.push(entry);
        save(data);

        res.writeHead(200, { ...CORS, 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ ok: true }));
    });
});

server.listen(PORT, HOST, () => {
    console.log(`[guestbook-api] listening on ${HOST}:${PORT}`);
    console.log(`[guestbook-api] pending file: ${PENDING_FILE}`);
});
