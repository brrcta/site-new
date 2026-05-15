# Setup Guide

A minimal, opinionated Claude Code ops template. Works for any project type: SaaS, internal tools, research, agencies, automation.

---

## What's in the box

| Layer | What it is |
|-------|-----------|
| `CLAUDE.md` | Project identity + principles (loaded every session) |
| `.claude/settings.json` | Permissions, hooks, context loading |
| `.claude/hooks/` | Session lifecycle (start deps, stop dump-check, auto-archive) |
| `.claude/commands/` | Slash commands: `/research`, `/status` |
| `.claude/skills/` | Multi-step skills: `/distill`, `/recap`, `/wrapup` |
| `.claude/agents/` | Sub-agent: `technician` (config + maintenance) |
| `.claude/rules/` | Phase gate enforcement |
| `context/` | Tiered knowledge base |
| `swarm/` | Multi-agent orchestration (tmux, Telegram, heartbeat) |
| `infra/` | VPS provisioner + Telegram bot |
| `tools/scrape.py` | Firecrawl-backed web scraper |

---

## Step 1 — Fill in project identity

Open `CLAUDE.md` and replace every `{{PLACEHOLDER}}`:

| Placeholder | What to put |
|-------------|-------------|
| `{{PROJECT_NAME}}` | Short slug (e.g. `myproject-ops`) |
| `{{ROOT_PATH}}` | Absolute path to your repo (e.g. `/home/user/myproject`) |
| `{{MARKET}}` | Target market or context (e.g. `EU-EN`, `US-B2B`, `internal`) |
| `{{LANG}}` | Language code (`EN`, `DE`, `FR`, etc.) |

---

## Step 2 — Fill in context files

Work through these in order. Each file has `<!-- comment -->` prompts:

1. **`context/lvl2-project.md`** — what the project is, who it serves, success criteria, operating constraints
2. **`context/lvl2-workflow.md`** — customize the pipeline stages to match your actual work pattern
3. **`context/lvl2-tech-stack.md`** — fill in your actual stack components
4. **`context/lvl2-todo-backlog.md`** — seed with your known backlog items

Leave `context/lvl1-todo-session.md` and `context/lvl1-decisions.md` empty — they populate through normal operation.

---

## Step 3 — Customize phase gates

Open `.claude/rules/phase-gates.md` and replace the default phases with milestones specific to your project.

Examples:
- **SaaS**: Infra → Beta → Revenue → Scale
- **Agency**: Scoping → Delivery → Handoff → Retainer
- **Internal tool**: Setup → Pilot → Rollout → Maintain

---

## Step 4 — Configure session-start hook

Open `.claude/hooks/session-start.sh` and add any dependency installs your project needs:

```bash
# Install Python deps
pip install -q -r requirements.txt

# Or Node
npm ci --silent

# Or whatever your stack needs
```

The hook already prints high-priority todos and checks the dump file size.

---

## Step 5 — Set up Telegram remote control (optional)

Control Claude Code from your phone.

```bash
# 1. Create a bot: message @BotFather → /newbot → save the token
# 2. Get your user ID: message @userinfobot → note the numeric ID

# 3. Fill in credentials:
cp infra/telegram-bot/.env.example infra/telegram-bot/telegram.env
nano infra/telegram-bot/telegram.env
# Set: TELEGRAM_TOKEN, TELEGRAM_ALLOWED_USER_ID

# 4. Provision VPS (installs Node, Claude CLI, Nginx, Tailscale, systemd):
bash infra/setup-vps.sh

# 5. Start the bot:
sudo systemctl enable --now telegram-bridge
sudo journalctl -u telegram-bridge -f

# 6. Test: send /help to your bot
```

---

## Step 6 — Add project-specific commands

Add slash commands in `.claude/commands/` as your workflow evolves. Each command is a markdown file with a YAML frontmatter header:

```markdown
---
name: my-command
description: What it does
argument-hint: [optional arg]
---

# My Command

**Input:** $ARGUMENTS

## Steps
1. Do X
2. Do Y
3. Save result to context/lvl3-dump.md
```

---

## Step 7 — First session

```
/status          → see what's open
/research [topic] → explore an area, save findings
/wrapup          → log decisions, clean up todos
```

---

## Context tier system

| Tier | Files | Load policy | Purpose |
|------|-------|-------------|---------|
| lvl1 | `todo-session`, `decisions` | Always loaded | Active working memory |
| lvl2 | `project`, `workflow`, `tech-stack`, `todo-backlog` | On-demand | Reference knowledge |
| lvl3 | `dump`, `dump-archive`, `decisions-archive` | Explicit only | Raw inbox + long-term archive |

The `archive-logs.sh` hook automatically moves old decision rows from `lvl1-decisions.md` to `lvl3-decisions-archive.md` when the file exceeds ~1500 tokens.

---

## Swarm orchestration

The `swarm/` directory provides multi-agent orchestration via tmux + Telegram. Use it when you need parallel Claude sessions or scheduled background tasks:

```bash
bash swarm/scripts/setup.sh          # one-time setup
bash swarm/scripts/spawn.sh worker   # launch a worker session
bash swarm/scripts/monitor.sh        # foreground dashboard
bash swarm/scripts/heartbeat.sh      # event-driven timer
```

Model routing is configured in `swarm/models.json` — edit roles and model IDs there.

---

## File map

```
CLAUDE.md                    Project identity + principles (always loaded)
SETUP.md                     This file

.claude/
  settings.json              Permissions, hooks, context config
  hooks/
    session-start.sh         Runs on SessionStart: install deps, print todos
    stop-dump-check.sh       Runs on Stop: warn if dump has many entries
    archive-logs.sh          Runs on Stop: auto-archive old decisions
  commands/
    research.md              /research [topic]
    status.md                /status
  skills/
    distill/SKILL.md         /distill — extract lvl3-dump into lvl2 files
    recap/SKILL.md           /recap — weekly project review
    wrapup/SKILL.md          /wrapup — session end, log decisions
  agents/
    technician.md            Config + maintenance sub-agent
  rules/
    phase-gates.md           Phase gate enforcement

context/
  lvl1-todo-session.md       Active tasks (always loaded)
  lvl1-decisions.md          Decision log (always loaded)
  lvl2-project.md            Project context (on-demand)
  lvl2-workflow.md           Pipeline playbook (on-demand)
  lvl2-tech-stack.md         Stack + architecture notes (on-demand)
  lvl2-todo-backlog.md       Non-urgent backlog (on-demand)
  lvl3-dump.md               Raw notes inbox (explicit only)
  lvl3-dump-archive.md       Archived raw notes
  lvl3-decisions-archive.md  Archived decisions

swarm/
  models.json                Model routing (provider + role → model)
  state.json                 Agent counters
  scripts/                   Orchestration: spawn, dispatch, heartbeat, notify…
  tasks/{pending,active,done}/  Task queue directories

infra/
  setup-vps.sh               Full VPS provisioner (Node, Claude CLI, Nginx, Tailscale)
  telegram-bot/              Long-poll Telegram bot + systemd service
  systemd/                   Heartbeat timer service

tools/
  scrape.py                  Firecrawl-backed web scraper (used by /research)
```
