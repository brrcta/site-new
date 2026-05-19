#!/usr/bin/env python3
"""
Guestbook API — minimal HTTP server, no dependencies beyond stdlib.
Accepts POST /api/guestbook, appends to guestbook-pending.json.
nginx serves guestbook.json (approved) as a static file.

Nginx snippet (add inside your site server block):
    location /api/guestbook {
        proxy_pass http://127.0.0.1:8041;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location = /guestbook.json {
        root /var/www/site;          # adjust to your actual web root
        add_header Cache-Control "no-cache";
        add_header Access-Control-Allow-Origin "*";
    }

Systemd: see infra/systemd/guestbook-api.service
"""

import json
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

PENDING_FILE = os.environ.get('GB_PENDING', '/var/www/site/guestbook-pending.json')
HOST = '127.0.0.1'
PORT = int(os.environ.get('GB_PORT', 8041))

_lock = threading.Lock()


def load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def save(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


class Handler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_POST(self):
        if self.path != '/api/guestbook':
            self.send_error(404)
            return
        try:
            length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(length))
        except (ValueError, json.JSONDecodeError):
            self.send_error(400, 'Bad JSON')
            return

        name = str(body.get('name', '')).strip()[:60]
        text = str(body.get('text', '')).strip()[:600]

        if not name or not text:
            self.send_error(400, 'name and text required')
            return

        entry = {
            'name': name,
            'text': text,
            'ts': int(time.time() * 1000),
            'ip': self.headers.get('X-Real-IP', self.client_address[0]),
        }

        with _lock:
            data = load(PENDING_FILE)
            data.append(entry)
            save(PENDING_FILE, data)

        self.send_response(200)
        self._cors()
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{"ok":true}')

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def log_message(self, fmt, *args):
        print(f'[guestbook-api] {self.address_string()} {fmt % args}')


if __name__ == '__main__':
    os.makedirs(os.path.dirname(PENDING_FILE), exist_ok=True)
    server = HTTPServer((HOST, PORT), Handler)
    print(f'[guestbook-api] listening on {HOST}:{PORT}')
    print(f'[guestbook-api] pending file: {PENDING_FILE}')
    server.serve_forever()
