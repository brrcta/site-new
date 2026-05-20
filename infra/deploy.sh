#!/bin/bash
# Deploy static site to VPS via rsync.
# Usage: VPS_HOST=user@host bash infra/deploy.sh [--dry-run] [--restart-api]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VPS="${VPS_HOST:-}"
REMOTE_ROOT="/var/www/florianvasin.com"
DRY_RUN=""
RESTART_API=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN="--dry-run" ;;
        --restart-api) RESTART_API="1" ;;
    esac
done

if [ -z "$VPS" ]; then
    echo "Error: VPS_HOST not set."
    echo "  VPS_HOST=user@yourserver.com bash infra/deploy.sh [--dry-run] [--restart-api]"
    exit 1
fi

[ -n "$DRY_RUN" ] && echo "▸ Dry run — no files will be changed" || echo "▸ Deploying static files → $VPS:$REMOTE_ROOT"

rsync -avz --delete $DRY_RUN \
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

[ -n "$DRY_RUN" ] && echo "✓ Dry run complete — re-run without --dry-run to deploy" && exit 0

echo "✓ Static files synced"

if [ -n "$RESTART_API" ]; then
    echo "▸ Restarting guestbook-api on $VPS..."
    ssh "$VPS" "sudo systemctl restart guestbook-api"
    echo "✓ guestbook-api restarted"
fi

echo "✓ Deploy complete → https://florianvasin.com"
