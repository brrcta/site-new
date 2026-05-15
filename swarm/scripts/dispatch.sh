#!/bin/bash
SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="$SWARM_DIR/models.json"
TODAY=$(date +%y%m%d)
TASK_ID="${TODAY}-$(date +%H%M%S)"
FILE="$SWARM_DIR/tasks/pending/task-$TASK_ID.json"

# Resolve provider + model + token cap for a given task type from models.json
resolve_model() {
    local task_type="$1"
    if command -v jq &>/dev/null && [ -f "$MODELS" ]; then
        local provider role model cap
        provider=$(jq -r ".routing[\"$task_type\"].provider // .swarm_default.provider" "$MODELS")
        role=$(jq -r ".routing[\"$task_type\"].role // .swarm_default.role" "$MODELS")
        model=$(jq -r ".providers[\"$provider\"].models[\"$role\"]" "$MODELS")
        cap=$(jq -r ".token_caps[\"$role\"] // .token_caps.worker" "$MODELS")
        echo "$provider|$model|$cap"
    else
        echo "anthropic|claude-haiku-4-5-20251001|1000"
    fi
}

write_task() {
    local type="$1" arg="$2"

    # Run pre-check before writing any task
    bash "$SWARM_DIR/scripts/pre-check.sh" "$type" "$arg" || exit 1

    local resolved provider model cap
    resolved=$(resolve_model "$type")
    provider="${resolved%%|*}"
    rest="${resolved#*|}"
    model="${rest%%|*}"
    cap="${rest##*|}"

    cat > "$FILE" <<EOF
{
  "id": "task-$TASK_ID",
  "type": "$type",
  "arg": "$arg",
  "status": "pending",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "provider": "$provider",
  "model": "$model",
  "max_tokens": $cap,
  "max_retries": 2,
  "retry_count": 0,
  "agent": null,
  "output": null
}
EOF
    echo "Dispatched: task-$TASK_ID ($type: $arg) → $provider/$model [cap: ${cap}t]"
}

case "$1" in
    article|batch|research|seo|postmortem|dashboard|infra|maintenance) write_task "$1" "$2" ;;
    *) echo "Usage: dispatch.sh [article|batch|research|seo|postmortem|dashboard|infra|maintenance] <arg>"; exit 1 ;;
esac
