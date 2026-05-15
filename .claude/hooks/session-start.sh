#!/bin/bash
set -euo pipefail

# Only run full setup in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Run async so session starts immediately while deps install in background
echo '{"async": true, "asyncTimeout": 300000}'

echo "=== {{PROJECT_NAME}} Session Start ==="
echo "Date: $(date)"
echo ""

# Install project-specific dependencies
# Add pip/npm/apt installs here as your stack requires
# Example: pip install -q -r requirements.txt
echo "(Add dependency installs here if needed)"
echo ""

# Print priority todos for context
grep -A20 "Priority\|BLOCKER\|HIGH" "$CLAUDE_PROJECT_DIR/context/lvl1-todo-session.md" 2>/dev/null | head -40 || true
echo ""

# Dump context-window notice
DUMP_FILE="$CLAUDE_PROJECT_DIR/context/lvl3-dump.md"
if [ -f "$DUMP_FILE" ]; then
  undistilled=$(grep -c "^## 20[^[]*$" "$DUMP_FILE" 2>/dev/null || echo 0)
  [ "$undistilled" -ge 10 ] && echo "NOTE [dump]: $undistilled undistilled entries — context window growing. Consider /distill."
fi

echo "=== Ready ==="
