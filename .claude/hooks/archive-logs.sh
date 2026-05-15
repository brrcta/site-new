#!/bin/bash
# archive-logs.sh — token-budget archival for context/lvl1-decisions.md
# Fires on Stop event. Archives when file exceeds ~1500 tokens (6000 chars),
# keeps newest ~1000 tokens (4000 chars). Always exits 0.

if [ "${ARCHIVE_LOGS_ACTIVE:-}" = "1" ]; then exit 0; fi
export ARCHIVE_LOGS_ACTIVE=1

DECISIONS="${CLAUDE_PROJECT_DIR}/context/lvl1-decisions.md"
ARCHIVE="${CLAUDE_PROJECT_DIR}/context/lvl3-decisions-archive.md"

ARCHIVE_THRESHOLD=6000  # ~1500 tokens
KEEP_TARGET=4000        # ~1000 tokens

[ ! -f "$DECISIONS" ] && exit 0

char_count=$(wc -c < "$DECISIONS")
[ "$char_count" -le "$ARCHIVE_THRESHOLD" ] && exit 0

tmpfile=$(mktemp)
arch_tmp=$(mktemp)
trap 'rm -f "$tmpfile" "$arch_tmp"' EXIT

# Lines 1-4 are fixed header (title, blank, table header, separator).
# Lines 5+ are data rows. Scan from bottom, accumulate until keep_target;
# rows beyond the cutpoint are archived (older entries).
awk -v keep_target="$KEEP_TARGET" -v arch_file="$arch_tmp" '
NR <= 4 { header[NR] = $0; next }
{ data[di++] = $0 }
END {
    cut = 0
    kept = 0
    for (i = di - 1; i >= 0; i--) {
        kept += length(data[i]) + 1
        if (kept > keep_target) {
            cut = i + 1
            break
        }
    }
    for (i = 1; i <= 4; i++) print header[i]
    for (i = cut; i < di; i++) print data[i]
    if (cut > 0)
        for (i = 0; i < cut; i++) print data[i] > arch_file
}
' "$DECISIONS" > "$tmpfile"

archived=$(wc -l < "$arch_tmp" 2>/dev/null || echo 0)
[ "$archived" -eq 0 ] && exit 0

# Append archived (older) rows to archive — preserves chronological order
cat "$arch_tmp" >> "$ARCHIVE"

new_chars=$(wc -c < "$tmpfile")
new_tokens=$(( new_chars / 4 ))
moved_tokens=$(( (char_count - new_chars) / 4 ))

cp "$tmpfile" "$DECISIONS"

echo "NOTE [archive-logs]: moved $archived rows (~${moved_tokens} tokens) to lvl3-decisions-archive.md — ${new_tokens} tokens remain in decisions log"

exit 0
