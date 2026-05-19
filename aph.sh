#!/usr/bin/env bash
# aph — post a new aphorism to the live site
# Usage:  aph "markets don't reward effort, they reward positioning"
# Put this in your PATH or call it directly on the VPS.
#
# First-time setup on VPS:
#   chmod +x aph.sh
#   echo '[]' > /path/to/site/aphorisms.json
#   # then add to ~/.bashrc: alias aph='/path/to/site/aph.sh'

set -euo pipefail

APH_FILE="${APH_FILE:-/var/www/site/aphorisms.json}"

if [ $# -eq 0 ]; then
  echo "Usage: aph \"your aphorism here\""
  exit 1
fi

TEXT="$*"

# Create file if it doesn't exist yet
[ -f "$APH_FILE" ] || echo "[]" > "$APH_FILE"

python3 - "$APH_FILE" "$TEXT" <<'PYEOF'
import json, sys, time

path, text = sys.argv[1], sys.argv[2]
data = json.load(open(path))
data.append({"text": text, "ts": int(time.time() * 1000)})
json.dump(data, open(path, "w"), ensure_ascii=False, indent=2)
print(f"✓ [{len(data)}] {text[:60]}{'…' if len(text)>60 else ''}")
PYEOF
