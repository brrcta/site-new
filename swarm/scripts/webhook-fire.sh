#!/usr/bin/env bash
# webhook-fire.sh — generalized outbound event notification.
# Fires to Telegram (if TELEGRAM_BOT_TOKEN set) and HTTP webhook (if WEBHOOK_URL set).
# Replaces notify.sh — call this instead for all event notifications.
#
# Usage: webhook-fire.sh <event_type> <message> [json_payload]
#   event_type: heartbeat | task_complete | task_failed | task_retry | alert | info
#   message:    human-readable summary (sent to Telegram)
#   json_payload: optional JSON string appended to HTTP POST body

set -euo pipefail

EVENT_TYPE="${1:-info}"
MESSAGE="${2:-}"
JSON_PAYLOAD="${3:-{}}"

SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "$SWARM_DIR/.." && pwd)"
LOG="$SWARM_DIR/logs/webhook.log"
mkdir -p "$SWARM_DIR/logs"

# Load env vars if present
[ -f "$REPO_DIR/.env" ] && set -a && . "$REPO_DIR/.env" && set +a

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FULL_MSG="[$EVENT_TYPE] $MESSAGE"

log_event() {
    echo "[$TIMESTAMP] $FULL_MSG" >> "$LOG"
}

fire_telegram() {
    [ -z "${TELEGRAM_BOT_TOKEN:-}" ] && return 0
    [ -z "${TELEGRAM_CHAT_ID:-}" ] && return 0
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$FULL_MSG" \
        > /dev/null 2>>"$LOG" || true
}

fire_http() {
    [ -z "${WEBHOOK_URL:-}" ] && return 0
    BODY="{\"event\":\"$EVENT_TYPE\",\"message\":$(echo "$MESSAGE" | jq -Rs .),\"timestamp\":\"$TIMESTAMP\",\"payload\":$JSON_PAYLOAD}"
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$BODY" \
        > /dev/null 2>>"$LOG" || true
}

log_event
fire_telegram
fire_http
