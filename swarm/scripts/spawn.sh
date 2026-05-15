#!/bin/bash
set -e
SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="$SWARM_DIR/models.json"

# Read swarm default provider + model + token cap from models.json (requires jq)
if command -v jq &>/dev/null && [ -f "$MODELS" ]; then
    PROVIDER=$(jq -r '.swarm_default.provider' "$MODELS")
    ROLE=$(jq -r '.swarm_default.role' "$MODELS")
    CLI=$(jq -r ".providers[\"$PROVIDER\"].cli" "$MODELS")
    MODEL_FLAG=$(jq -r ".providers[\"$PROVIDER\"].cli_model_flag" "$MODELS")
    MODEL=$(jq -r ".providers[\"$PROVIDER\"].models[\"$ROLE\"]" "$MODELS")
    MAX_TOKENS=$(jq -r ".token_caps[\"$ROLE\"] // .token_caps.worker" "$MODELS")
    LAUNCH_CMD="$CLI $MODEL_FLAG $MODEL --max-tokens $MAX_TOKENS"
else
    # Fallback: no jq or no models.json
    LAUNCH_CMD="claude --model claude-haiku-4-5-20251001 --max-tokens 1000"
fi

echo "Swarm launch cmd: $LAUNCH_CMD"

for agent in agent-1 agent-2; do
    tmux kill-session -t "$agent" 2>/dev/null || true
    tmux new-session -d -s "$agent" -c "$SWARM_DIR/worktrees/$agent"
    tmux send-keys -t "$agent" "$LAUNCH_CMD" Enter
    echo "Spawned $agent ($LAUNCH_CMD)"
done
echo "Attach: tmux attach -t agent-1"
