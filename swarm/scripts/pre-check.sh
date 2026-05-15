#!/usr/bin/env bash
# pre-check.sh — standardized pre-flight gate before any swarm task is dispatched.
# Called by dispatch.sh. Exit 0 = proceed; Exit 1 = block dispatch.
set -euo pipefail

SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="$SWARM_DIR/models.json"
TASK_TYPE="${1:-}"
TASK_ARG="${2:-}"

fail() { echo "PRE-CHECK FAIL: $*" >&2; exit 1; }
warn() { echo "PRE-CHECK WARN: $*" >&2; }

# 1. jq must be available
command -v jq &>/dev/null || fail "jq not found — install with: apt-get install jq"

# 2. models.json must exist and be valid JSON
[ -f "$MODELS" ] || fail "models.json not found at $MODELS"
jq . "$MODELS" > /dev/null 2>&1 || fail "models.json is invalid JSON"

# 3. Task type must be non-empty
[ -n "$TASK_TYPE" ] || fail "task type is required"

# 4. Resolved model must exist in models.json (not null)
PROVIDER=$(jq -r ".routing[\"$TASK_TYPE\"].provider // .swarm_default.provider" "$MODELS")
ROLE=$(jq -r ".routing[\"$TASK_TYPE\"].role // .swarm_default.role" "$MODELS")
MODEL=$(jq -r ".providers[\"$PROVIDER\"].models[\"$ROLE\"] // \"null\"" "$MODELS")
[ "$MODEL" != "null" ] || fail "no model resolved for type='$TASK_TYPE' (provider=$PROVIDER role=$ROLE) — check models.json"

# 5. Task queue dirs must exist
for dir in pending active done failed; do
    [ -d "$SWARM_DIR/tasks/$dir" ] || fail "task dir missing: swarm/tasks/$dir — run setup.sh first"
done

# 6. Warn (non-blocking) if too many pending tasks are queued
PENDING=$(find "$SWARM_DIR/tasks/pending" -maxdepth 1 -name "*.json" 2>/dev/null | wc -l)
[ "$PENDING" -lt 20 ] || warn "$PENDING pending tasks — queue may be backed up"

echo "PRE-CHECK OK: type=$TASK_TYPE provider=$PROVIDER role=$ROLE model=$MODEL"
exit 0
