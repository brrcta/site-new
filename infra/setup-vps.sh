#!/bin/bash
# VPS setup: Claude Code CLI + Telegram bot (systemd)
# Run from repo root: bash infra/setup-vps.sh
# Tested on: Ubuntu 22.04 / Debian 12

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOT_DIR="$REPO_DIR/infra/telegram-bot"
ENV_FILE="$BOT_DIR/telegram.env"
SERVICE_SRC="$BOT_DIR/telegram-bridge.service"
SERVICE_DEST="/etc/systemd/system/telegram-bridge.service"
VENV_DIR="$BOT_DIR/venv"
LOG_DIR="$REPO_DIR/swarm/logs"

echo "=== AffOps VPS Setup ==="
echo "Repo: $REPO_DIR"
echo ""

# ── 0. Base hardening & shell tools ──────────────────────────────────────────
# tmux: persistent CC sessions across SSH disconnects (Termius + mosh friendly)
# fail2ban: ban SSH brute-force sources
# unattended-upgrades: automatic security patches
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

# ── 3. Python venv + deps ─────────────────────────────────────────────────────
echo "▸ Setting up Python venv..."
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
"$VENV_DIR/bin/pip" install --quiet -r "$BOT_DIR/requirements.txt"
echo "✓ Python deps installed ($VENV_DIR)"

# ── 4. Nginx (reverse proxy for Ghost + static sites) ──────────────────────────
if ! command -v nginx &>/dev/null; then
    echo "▸ Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    echo "✓ Nginx installed"
else
    echo "✓ Nginx $(nginx -v 2>&1)"
fi

# Create web root directories (configs managed by repos)
for site in parentslist.eu movinfaast.com florianvasin.com; do
    sudo mkdir -p "/var/www/$site"
    sudo chown root:root "/var/www/$site"
    echo "✓ Web root: /var/www/$site"
done

# ── 5. Tailscale (secure mesh networking) ────────────────────────────────────
if ! command -v tailscale &>/dev/null; then
    echo "▸ Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "✓ Tailscale installed"
else
    echo "✓ Tailscale $(tailscale version 2>/dev/null | head -1)"
fi

# Start Tailscale and capture auth URL
echo ""
echo "▸ Starting Tailscale (will prompt for login)..."
sudo tailscale up --accept-routes 2>&1 | grep -E "(https://|started)" || true
echo ""
echo "✓ Tailscale status:"
sudo tailscale status | head -5
VPS_IP=$(hostname -I | awk '{print $1}')
echo "  VPS private IP (for Termius / SSH client): $(sudo tailscale ip -4 || echo "check 'tailscale ip -4' after auth")"

# ── 6. Logs directory ─────────────────────────────────────────────────────────
mkdir -p "$LOG_DIR"
echo "✓ Log dir: $LOG_DIR"

# ── 7. Create .env if missing ─────────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << EOF
# Telegram bridge — fill in before starting the bot
TELEGRAM_TOKEN=REPLACE_ME
TELEGRAM_ALLOWED_USER_ID=REPLACE_ME
WORK_DIR=$REPO_DIR
CLAUDE_BIN=$(command -v claude || echo /usr/local/bin/claude)
CLAUDE_TIMEOUT=300
CLAUDE_SKIP_PERMISSIONS=false

# Firecrawl — pre-enriches web data before AI (used by tools/scrape.py)
# Get key at: https://www.firecrawl.dev
FIRECRAWL_API_KEY=REPLACE_ME
EOF
    echo ""
    echo "✓ Created $ENV_FILE"
    echo "  → Edit it now: TELEGRAM_TOKEN + TELEGRAM_ALLOWED_USER_ID + FIRECRAWL_API_KEY"
else
    echo "✓ $ENV_FILE exists"
    # Warn if still has placeholder values
    if grep -q "REPLACE_ME" "$ENV_FILE"; then
        echo "  ⚠ REPLACE_ME values detected — fill them in before starting!"
    fi
fi

# ── 8. systemd service ────────────────────────────────────────────────────────
if [ ! -f "$SERVICE_DEST" ]; then
    echo "▸ Installing systemd service..."
    sudo cp "$SERVICE_SRC" "$SERVICE_DEST"
    sudo systemctl daemon-reload
    echo "✓ Service installed (not started yet)"
else
    echo "✓ systemd service already installed"
    echo "  → To reload after changes: sudo systemctl daemon-reload"
fi

# ── 9. Claude auth ────────────────────────────────────────────────────────────
echo ""
echo "=== Claude Auth ==="
if claude --version &>/dev/null; then
    # Check if already authenticated by running a trivial command
    if claude --print "ping" &>/dev/null 2>&1; then
        echo "✓ Claude already authenticated"
    else
        echo "▸ Run 'claude' once to authenticate (follow the browser URL):"
        echo "  claude"
    fi
else
    echo "▸ Claude CLI not found in PATH — check npm global install"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Setup complete — next steps ==="
echo ""
echo "1. Configure Tailscale on phone:"
echo "   • Copy Tailscale invite link from output above"
echo "   • Install Tailscale app on iPhone"
echo "   • Accept invite → note VPS private IP for Termius (iOS) host config"
echo ""
echo "2. Edit env:    nano $ENV_FILE"
echo "   TELEGRAM_TOKEN          → from @BotFather on Telegram"
echo "   TELEGRAM_ALLOWED_USER_ID → message @userinfobot on Telegram"
echo "   FIRECRAWL_API_KEY       → from https://www.firecrawl.dev"
echo ""
echo "3. Authenticate Claude (if not done):"
echo "   claude"
echo ""
echo "4. Enable + start bot:"
echo "   sudo systemctl enable --now telegram-bridge"
echo ""
echo "5. Configure nginx (from respective repos):"
echo "   • affops repo → nginx config for parentslist.eu + Ghost"
echo "   • agency repo → nginx config for movinfaast.com"
echo "   • personal repo → nginx config for florianvasin.com"
echo "   Web roots ready at: /var/www/{parentslist.eu,movinfaast.com,florianvasin.com}"
echo ""
echo "6. Tail logs:"
echo "   sudo journalctl -u telegram-bridge -f"
echo ""
echo "7. Test: send /help to your bot on Telegram"
