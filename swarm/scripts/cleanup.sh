#!/bin/bash
for agent in agent-1 agent-2; do
    tmux kill-session -t "$agent" 2>/dev/null && echo "Stopped $agent"
done
