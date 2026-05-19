#!/usr/bin/env bash
# gb-approve — review and approve/reject pending guestbook entries
#
# Usage:
#   gb-approve list          show pending entries (numbered)
#   gb-approve approve N     move entry N to approved (published)
#   gb-approve reject  N     delete entry N from pending
#
# First-time VPS setup:
#   echo '[]' > /var/www/site/guestbook-pending.json
#   echo '[]' > /var/www/site/guestbook.json
#   chmod +x /var/www/site/gb-approve.sh
#   # add to ~/.bashrc:
#   # alias gb='export GB_PENDING=/var/www/site/guestbook-pending.json GB_APPROVED=/var/www/site/guestbook.json; /var/www/site/gb-approve.sh'

set -euo pipefail

GB_PENDING="${GB_PENDING:-/var/www/site/guestbook-pending.json}"
GB_APPROVED="${GB_APPROVED:-/var/www/site/guestbook.json}"

cmd="${1:-list}"

case "$cmd" in

  list)
    python3 - "$GB_PENDING" <<'PY'
import json, sys, datetime
try:
    data = json.load(open(sys.argv[1]))
except:
    data = []
if not data:
    print("No pending entries.")
    sys.exit(0)
for i, e in enumerate(data, 1):
    ts = datetime.datetime.fromtimestamp(e['ts'] / 1000).strftime('%Y-%m-%d %H:%M')
    print(f"[{i}] {e['name']} · {ts}")
    print(f"    {e['text'][:120]}{'…' if len(e['text']) > 120 else ''}")
    print()
PY
    ;;

  approve)
    N="${2:?Usage: gb-approve approve N}"
    python3 - "$GB_PENDING" "$GB_APPROVED" "$N" <<'PY'
import json, sys
pending_path, approved_path, idx = sys.argv[1], sys.argv[2], int(sys.argv[3]) - 1

pending = json.load(open(pending_path))
try:
    approved = json.load(open(approved_path))
except:
    approved = []

entry = pending.pop(idx)
# remove internal ip field before publishing
entry.pop('ip', None)
approved.insert(0, entry)  # newest first

json.dump(pending,  open(pending_path,  'w'), ensure_ascii=False, indent=2)
json.dump(approved, open(approved_path, 'w'), ensure_ascii=False, indent=2)
print(f"✓ Approved [{len(approved)} total]: {entry['name']} — {entry['text'][:60]}{'…' if len(entry['text'])>60 else ''}")
PY
    ;;

  reject)
    N="${2:?Usage: gb-approve reject N}"
    python3 - "$GB_PENDING" "$N" <<'PY'
import json, sys
pending_path, idx = sys.argv[1], int(sys.argv[2]) - 1
pending = json.load(open(pending_path))
entry = pending.pop(idx)
json.dump(pending, open(pending_path, 'w'), ensure_ascii=False, indent=2)
print(f"✗ Rejected: {entry['name']} — {entry['text'][:60]}{'…' if len(entry['text'])>60 else ''}")
PY
    ;;

  *)
    echo "Usage: gb-approve [list | approve N | reject N]"
    exit 1
    ;;

esac
