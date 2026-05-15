#!/bin/bash
# Start the Telegram bot as a background process.
# Run from repo root: bash swarm/scripts/bot-start.sh

set -euo pipefail

PIDFILE="swarm/logs/bot.pid"
LOGFILE="swarm/logs/bot.log"
ENV_FILE="infra/telegram-bot/telegram.env"
VENV_PYTHON="infra/telegram-bot/venv/bin/python"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found — copy template and fill in values" >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Bot already running (PID $(cat "$PIDFILE"))"
  exit 0
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

nohup "$VENV_PYTHON" infra/telegram-bot/bot.py >> "$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"
echo "Bot started (PID $(cat "$PIDFILE")) — logs: $LOGFILE"
