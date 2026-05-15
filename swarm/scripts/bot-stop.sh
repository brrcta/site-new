#!/bin/bash
# Stop the Telegram bot.
# Run from repo root: bash swarm/scripts/bot-stop.sh

set -euo pipefail

PIDFILE="swarm/logs/bot.pid"

if [ ! -f "$PIDFILE" ]; then
  echo "Bot not running (no PID file found)"
  exit 0
fi

PID=$(cat "$PIDFILE")
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  rm "$PIDFILE"
  echo "Bot stopped (PID $PID)"
else
  echo "Bot process $PID not found — removing stale PID file"
  rm "$PIDFILE"
fi
