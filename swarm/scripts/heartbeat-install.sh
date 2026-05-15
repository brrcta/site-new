#!/usr/bin/env bash
# heartbeat-install.sh — idempotent installer for the affops heartbeat systemd user timer
# WARNING: Do NOT enable while swarm/scripts/monitor.sh is running in a tmux loop —
#          dual pollers will write conflicting state.json updates.
#          Production: use this timer. Local debug: use monitor.sh interactively.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$REPO_DIR/infra/systemd"
DEST="$HOME/.config/systemd/user"

echo "Installing affops heartbeat timer to $DEST ..."
mkdir -p "$DEST"
cp "$SRC/affops-heartbeat.service" "$DEST/"
cp "$SRC/affops-heartbeat.timer" "$DEST/"

systemctl --user daemon-reload
systemctl --user enable --now affops-heartbeat.timer

echo ""
echo "Installed. Current timer status:"
systemctl --user list-timers affops-heartbeat.timer
