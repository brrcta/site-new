#!/bin/bash
# Deploy static site to VPS via rsync.
# Usage: VPS_HOST=user@host bash infra/deploy.sh [--restart-api]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VPS="${VPS_HOST:-}"
REMOTE_ROOT="/var/www/florianvasin.com"

if [ -z "$VPS" ]; then
    echo "Error: VPS_HOST not set."
    echo "  VPS_HOST=user@yourserver.com bash infra/deploy.sh"
    exit 1
fi

echo "▸ Deploying static files → $VPS:$REMOTE_ROOT"

rsync -avz --delete \
    --exclude='.git' \
    --exclude='.claude' \
    --exclude='context' \
    --exclude='swarm' \
    --exclude='infra' \
    --exclude='tools' \
    --exclude='handoff' \
    --exclude='*.sh' \
    --exclude='*.md' \
    "$REPO_DIR/" \
    "$VPS:$REMOTE_ROOT/"

echo "✓ Static files synced"

if [[ "${1:-}" == "--restart-api" ]]; then
    echo "▸ Restarting guestbook-api on $VPS..."
    ssh "$VPS" "sudo systemctl restart guestbook-api"
    echo "✓ guestbook-api restarted"
fi

echo "✓ Deploy complete → https://florianvasin.com"
