#!/usr/bin/env bash
# heartbeat.sh — event-driven swarm monitor (0 tokens when idle)
# Production path: triggered by affops-heartbeat.timer (systemd user timer, every 10min)
# Interactive path: swarm/scripts/monitor.sh (foreground dashboard)
# DO NOT run both simultaneously on the same machine.
set -euo pipefail

SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "$SWARM_DIR/.." && pwd)"
MODELS="$SWARM_DIR/models.json"
LOG="$SWARM_DIR/logs/heartbeat.log"
WEBHOOK="$SWARM_DIR/scripts/webhook-fire.sh"
mkdir -p "$SWARM_DIR/logs"

# Load env for TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID if present
[ -f "$REPO_DIR/.env" ] && set -a && . "$REPO_DIR/.env" && set +a

# Token cap: heartbeat monitor = 400 (2x human baseline of 200)
HEARTBEAT_CAP=400
if command -v jq &>/dev/null && [ -f "$MODELS" ]; then
    HEARTBEAT_CAP=$(jq -r '.token_caps.heartbeat // 400' "$MODELS")
fi

# Use filesystem count — state.json is stale and not reliable
ACTIVE=$(find "$SWARM_DIR/tasks/active" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l)

if [ "$ACTIVE" -eq 0 ]; then
    echo "[$(date -Iseconds)] idle — 0 active tasks, skipping LLM call" >> "$LOG"
    exit 0
fi

# Retry logic: check each active task for age and retry eligibility
NOW_EPOCH=$(date +%s)
STUCK_THRESHOLD=1800  # 30 minutes in seconds

for task_file in "$SWARM_DIR/tasks/active"/*.json; do
    [ -f "$task_file" ] || continue
    task_id=$(jq -r '.id' "$task_file" 2>/dev/null) || continue
    created=$(jq -r '.created' "$task_file" 2>/dev/null) || continue
    retry_count=$(jq -r '.retry_count // 0' "$task_file" 2>/dev/null)
    max_retries=$(jq -r '.max_retries // 2' "$task_file" 2>/dev/null)

    # Convert ISO timestamp to epoch
    created_epoch=$(date -d "$created" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created" +%s 2>/dev/null || echo 0)
    age=$((NOW_EPOCH - created_epoch))

    if [ "$age" -gt "$STUCK_THRESHOLD" ]; then
        if [ "$retry_count" -lt "$max_retries" ]; then
            new_count=$((retry_count + 1))
            # Bump retry count and move back to pending
            jq ".retry_count = $new_count | .status = \"pending\" | .agent = null" "$task_file" > "${task_file}.tmp"
            mv "${task_file}.tmp" "$SWARM_DIR/tasks/pending/$(basename "$task_file")"
            rm -f "$task_file"
            echo "[$(date -Iseconds)] RETRY $task_id (attempt $new_count/$max_retries) — stuck >30min" >> "$LOG"
            bash "$WEBHOOK" task_retry "task $task_id stuck >30min — retry $new_count/$max_retries" 2>>"$LOG" || true
        else
            # Retry exhausted — move to failed/
            mkdir -p "$SWARM_DIR/tasks/failed"
            jq '.status = "failed"' "$task_file" > "${task_file}.tmp"
            mv "${task_file}.tmp" "$SWARM_DIR/tasks/failed/$(basename "$task_file")"
            rm -f "$task_file"
            echo "[$(date -Iseconds)] FAILED $task_id — retries exhausted ($max_retries)" >> "$LOG"
            bash "$WEBHOOK" task_failed "task $task_id failed after $max_retries retries" 2>>"$LOG" || true
        fi
    fi
done

# Recount active after retry processing
ACTIVE=$(find "$SWARM_DIR/tasks/active" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l)
[ "$ACTIVE" -eq 0 ] && exit 0

PROMPT='Heartbeat monitor. Check swarm/tasks/active/*.json, run `tmux ls` for agent-1/agent-2 sessions, tail -50 swarm/logs/*.log if present. Output <=10 lines: active task count, per-task status summary, any errors or warnings, and ALERT if any task appears stuck >30min based on created timestamp.'

SUMMARY=$(cd "$REPO_DIR" && claude --print --model claude-sonnet-4-6 --max-tokens "$HEARTBEAT_CAP" "$PROMPT" 2>>"$LOG")
echo "[$(date -Iseconds)] active=$ACTIVE | $SUMMARY" >> "$LOG"

bash "$WEBHOOK" heartbeat "$SUMMARY" 2>>"$LOG" || true
