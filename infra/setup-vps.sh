#!/bin/bash
# VPS setup: Nginx static site + Node guestbook API + Claude Code CLI
# Run from repo root: bash infra/setup-vps.sh
# Tested on: Ubuntu 22.04 / Debian 12
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOMAIN="florianvasin.com"
WEB_ROOT="/var/www/$DOMAIN"
API_DEST="/opt/guestbook-api"
LOG_DIR="$REPO_DIR/swarm/logs"

echo "=== florianvasin.com VPS Setup ==="
echo "Repo: $REPO_DIR"
echo ""

# ── 0. Base hardening & shell tools ──────────────────────────────────────────
echo "▸ Installing base tools (tmux, fail2ban, unattended-upgrades)..."
sudo apt-get update -qq
sudo apt-get install -y tmux fail2ban unattended-upgrades
sudo systemctl enable --now fail2ban
sudo dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null
echo "✓ tmux $(tmux -V | awk '{print $2}'), fail2ban active, unattended-upgrades enabled"

# ── 1. Node.js ────────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
    echo "▸ Installing Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "✓ Node.js $(node --version)"
fi

# ── 2. Claude Code CLI ────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo "▸ Installing Claude Code CLI..."
    sudo npm install -g @anthropic-ai/claude-code
else
    echo "✓ Claude Code CLI $(claude --version 2>/dev/null || echo 'installed')"
fi

# ── 3. Nginx ──────────────────────────────────────────────────────────────────
if ! command -v nginx &>/dev/null; then
    echo "▸ Installing Nginx..."
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    echo "✓ Nginx installed"
else
    echo "✓ Nginx $(nginx -v 2>&1)"
fi

# Deploy site config
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN.conf"
echo "▸ Installing Nginx config → $NGINX_CONF"
sudo cp "$REPO_DIR/infra/nginx/$DOMAIN.conf" "$NGINX_CONF"
sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN.conf"
sudo nginx -t
sudo systemctl reload nginx
echo "✓ Nginx config deployed and reloaded"

# ── 4. Web root ───────────────────────────────────────────────────────────────
sudo mkdir -p "$WEB_ROOT"
sudo chown "$USER:$USER" "$WEB_ROOT"
echo "✓ Web root: $WEB_ROOT"

# ── 5. Guestbook API (Node) ───────────────────────────────────────────────────
echo "▸ Installing guestbook API → $API_DEST"
sudo mkdir -p "$API_DEST"
sudo cp "$REPO_DIR/infra/guestbook-api/server.js" "$API_DEST/server.js"
sudo cp "$REPO_DIR/infra/guestbook-api/package.json" "$API_DEST/package.json"
echo "✓ Guestbook API files installed"

SERVICE_DEST="/etc/systemd/system/guestbook-api.service"
if [ ! -f "$SERVICE_DEST" ]; then
    echo "▸ Installing systemd service..."
    sudo cp "$REPO_DIR/infra/systemd/guestbook-api.service" "$SERVICE_DEST"
    sudo systemctl daemon-reload
    sudo systemctl enable guestbook-api
    echo "✓ guestbook-api service installed and enabled"
else
    echo "✓ Reloading existing systemd service..."
    sudo cp "$REPO_DIR/infra/systemd/guestbook-api.service" "$SERVICE_DEST"
    sudo systemctl daemon-reload
fi
sudo systemctl restart guestbook-api
echo "✓ guestbook-api running"

# ── 6. Tailscale ─────────────────────────────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
    echo "▸ Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "✓ Tailscale installed"
else
    echo "✓ Tailscale $(tailscale version 2>/dev/null | head -1)"
fi
echo "▸ Starting Tailscale (will prompt for login)..."
sudo tailscale up --accept-routes 2>&1 | grep -E "(https://|started)" || true
echo "✓ Tailscale IP: $(sudo tailscale ip -4 2>/dev/null || echo 'check after auth')"

# ── 7. Logs directory ─────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
echo "✓ Log dir: $LOG_DIR"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Setup complete — next steps ==="
echo ""
echo "1. Deploy site files:"
echo "   VPS_HOST=$USER@<your-ip> bash infra/deploy.sh"
echo ""
echo "2. HTTPS (run once, certbot auto-renews):"
echo "   sudo apt install -y certbot python3-certbot-nginx"
echo "   sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "3. Authenticate Claude (if not done):"
echo "   claude"
echo ""
echo "4. Tail guestbook API logs:"
echo "   sudo journalctl -u guestbook-api -f"
echo ""
echo "5. Verify site: https://$DOMAIN"
