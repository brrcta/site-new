#!/bin/bash
set -e
SWARM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(dirname "$SWARM_DIR")"

validate_worktree() {
    local agent="$1"
    local worktree="$SWARM_DIR/worktrees/$agent"
    local ok=true

    # Syntax-check any changed shell scripts
    while IFS= read -r f; do
        if [[ "$f" == *.sh ]]; then
            bash -n "$worktree/$f" 2>/dev/null || { echo "[$agent] bash syntax error: $f"; ok=false; }
        fi
    done < <(git -C "$worktree" diff --name-only HEAD 2>/dev/null)

    # Syntax-check any changed Python files
    while IFS= read -r f; do
        if [[ "$f" == *.py ]]; then
            python3 -m py_compile "$worktree/$f" 2>/dev/null || { echo "[$agent] Python syntax error: $f"; ok=false; }
        fi
    done < <(git -C "$worktree" diff --name-only HEAD 2>/dev/null)

    # Validate any changed JSON files
    while IFS= read -r f; do
        if [[ "$f" == *.json ]]; then
            jq . "$worktree/$f" > /dev/null 2>&1 || { echo "[$agent] JSON invalid: $f"; ok=false; }
        fi
    done < <(git -C "$worktree" diff --name-only HEAD 2>/dev/null)

    [ "$ok" = true ]
}

for agent in agent-1 agent-2; do
    worktree="$SWARM_DIR/worktrees/$agent"
    [ -d "$worktree" ] || continue

    if [ -n "$(git -C "$worktree" status --porcelain)" ]; then
        echo "[$agent] has changes — validating before merge"

        if validate_worktree "$agent"; then
            git -C "$worktree" add -A
            git -C "$worktree" commit -m "Work from $agent"
            git -C "$REPO_ROOT" merge "${agent}-work" --no-edit
            echo "[$agent] merged OK"
        else
            echo "[$agent] BLOCKED — validation failed; fix errors before merging"
            exit 1
        fi
    fi
done
