#!/bin/bash
# NOTE: monitor.sh is the interactive foreground dashboard (run manually in tmux).
# Production path is swarm/scripts/heartbeat.sh (systemd user timer, 0 tokens when idle).
# Do NOT run both simultaneously — they will write conflicting state.json updates.
SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$SWARM_DIR/state.json"

update_state() {
    local pending active done now
    pending=$(ls -1 "$SWARM_DIR/tasks/pending"/*.json 2>/dev/null | wc -l)
    active=$(ls -1 "$SWARM_DIR/tasks/active"/*.json 2>/dev/null | wc -l)
    done=$(ls -1 "$SWARM_DIR/tasks/done"/*.json 2>/dev/null | wc -l)
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat > "$STATE" <<EOF
{
  "active_agents": [],
  "pending": $pending,
  "active": $active,
  "done": $done,
  "last_sync": null,
  "last_updated": "$now"
}
EOF
    echo "$pending $active $done"
}

echo "Monitoring... (Ctrl+C to stop)"
while true; do
    read -r pending active done <<< "$(update_state)"
    echo "[$(date +%H:%M)] Pending: $pending | Active: $active | Done: $done"
    sleep 30
done
