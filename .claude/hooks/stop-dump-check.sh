#!/bin/bash
# Non-blocking dump context-window warning.
# Fires on Stop event. Counts undistilled entries and prints a soft NOTE.
# Always exits 0 — never blocks session end.

if [ "${STOP_HOOK_ACTIVE:-}" = "1" ]; then exit 0; fi
export STOP_HOOK_ACTIVE=1

DUMP_FILE="${CLAUDE_PROJECT_DIR}/context/lvl3-dump.md"
ENTRY_THRESHOLD=10
AGE_THRESHOLD_DAYS=7

if [ ! -f "$DUMP_FILE" ]; then exit 0; fi

undistilled=$(grep -c "^## 20[^[]*$" "$DUMP_FILE" 2>/dev/null || echo 0)
last_mod=$(stat -c %Y "$DUMP_FILE" 2>/dev/null || echo 0)
now=$(date +%s)
age_days=$(( (now - last_mod) / 86400 ))

[ "$undistilled" -ge "$ENTRY_THRESHOLD" ] && \
  echo "NOTE [dump]: $undistilled undistilled entries — context window will grow. Consider /distill."

[ "$age_days" -ge "$AGE_THRESHOLD_DAYS" ] && \
  echo "NOTE [dump]: last dump activity was ${age_days}d ago. Consider /distill."

exit 0
