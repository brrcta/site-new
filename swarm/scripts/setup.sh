#!/bin/bash
set -e
SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(dirname "$SWARM_DIR")"

echo "=== Swarm Setup ==="
mkdir -p "$SWARM_DIR"/{worktrees,tasks/{pending,active,done,failed},logs,hooks}

BRANCH=$(git -C "$REPO_ROOT" branch --show-current)
for agent in agent-1 agent-2; do
    if [ ! -d "$SWARM_DIR/worktrees/$agent" ]; then
        git -C "$REPO_ROOT" worktree add "$SWARM_DIR/worktrees/$agent" -b "${agent}-work" "$BRANCH"
        echo "Created $agent"
    fi
done
echo "=== Done ==="
