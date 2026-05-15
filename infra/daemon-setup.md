# Git Auto-Sync Daemon Setup

> Phase 0 Infrastructure. Enables automatic background state sync to GitHub during development sessions.

## What It Does

The daemon watches configured project directories (`context/`, `leads/`, `.claude/`) every 5 minutes. If changes are detected, it commits and pushes automatically. Syncs silently in the background — zero overhead to your workflow.

## Installation

### 1. Create daemon script

```bash
mkdir -p /home/user/.claude/bin
cat > /home/user/.claude/bin/git-auto-sync.sh << 'EOF'
#!/bin/bash
PROJECTS=("/home/user/agency" "/home/user/affiliate-business")
while true; do
  for proj in "${PROJECTS[@]}"; do
    cd "$proj"
    if git status --porcelain | grep -q .; then
      git add context/ leads/ .claude/ 2>/dev/null
      git commit -m "auto: session state $(date +%Y%m%d-%H%M%S)" --quiet 2>/dev/null
      git push origin main --quiet 2>/dev/null
    fi
  done
  sleep 300
done
EOF
chmod +x /home/user/.claude/bin/git-auto-sync.sh
```

### 2. Install systemd service

```bash
sudo tee /etc/systemd/system/git-auto-sync.service > /dev/null << 'EOF'
[Unit]
Description=Auto-sync project state to GitHub
After=network.target

[Service]
Type=simple
User=user
ExecStart=/home/user/.claude/bin/git-auto-sync.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### 3. Enable & start

```bash
sudo systemctl daemon-reload
sudo systemctl enable git-auto-sync
sudo systemctl start git-auto-sync
```

## Verify

```bash
# Check status
sudo systemctl status git-auto-sync

# View logs
sudo journalctl -u git-auto-sync -f
```

## What Happens Each Session

```
cd /home/user/agency
# (you work normally)
# (daemon syncs silently every 5 min if changes exist)
# Close Claude Code
# (stop hook auto-commits & pushes final state if dirty)
# Done. No manual git commands.
```

## Disable

```bash
sudo systemctl disable git-auto-sync
sudo systemctl stop git-auto-sync
```
