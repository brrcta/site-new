# Swarm — Agent Knowledge Base

This file provides compressed, declarative knowledge for any agent operating within the swarm
orchestration layer. Read this file to orient yourself without re-reading all scripts.

---

## Architecture

**Task queue:** filesystem-based state machine.
```
tasks/pending/   ← dispatch.sh writes here
tasks/active/    ← agent claims task (moves file)
tasks/done/      ← agent marks complete (moves file)
tasks/failed/    ← heartbeat.sh moves here after max_retries exhausted
```

**Agent sessions:** 2 tmux sessions (`agent-1`, `agent-2`) in isolated git worktrees.
`spawn.sh` creates sessions; `cleanup.sh` kills them; `sync.sh` merges work back.

**Heartbeat:** systemd timer fires every 10 min → `heartbeat.sh` → Sonnet monitor call if tasks active,
0 tokens if idle. Retry logic: task stuck >30min → bump to pending (up to max_retries=2) → then failed/.

---

## Model Routing — Single Source of Truth: `swarm/models.json`

| Role | Provider | Model | Token cap | Used for |
|------|----------|-------|-----------|---------|
| worker | anthropic | claude-opus-4-6 | 6,000 | article drafts, batch content |
| reviewer | anthropic | claude-sonnet-4-6 | 2,000 | editorial check, research, distill |
| analyst | anthropic | claude-haiku-4-5-20251001 | 1,000 | SEO, SERP, qualify, cluster |
| technician | anthropic | claude-sonnet-4-6 | 3,000 | config, maintenance, scripts |
| orchestrator | anthropic | claude-opus-4-6 | 4,000 | top-level planning |
| heartbeat | anthropic | claude-sonnet-4-6 | 400 | swarm monitor |

**3rd-party provider support:** `models.json` also defines `openai` (codex + o4-mini) and `minimax`
(MiniMax-Text-01). Change `routing[task_type].provider` to swap providers for any task type.
`dispatch.sh` and `bot.py` both resolve from `models.json` at runtime.

**Token cap standard:** 2× human tokens per role. Human baseline = tokens a skilled human would use
to solve the same task. Caps are enforced via `--max-tokens` in every claude invocation.

---

## Task JSON Schema

```json
{
  "id": "task-YYMMDD-HHMMSS",
  "type": "article|batch|research|seo|postmortem|dashboard|infra|maintenance",
  "arg": "task argument",
  "status": "pending|active|done|failed",
  "created": "ISO-8601",
  "provider": "anthropic|openai|minimax",
  "model": "resolved model string",
  "max_tokens": 6000,
  "max_retries": 2,
  "retry_count": 0,
  "agent": null,
  "output": null
}
```

---

## Pre-Check Gate

`pre-check.sh` runs before every `dispatch.sh` call. It validates:
1. jq available
2. models.json exists and is valid JSON
3. Task type resolves to a non-null model
4. All task queue directories exist
5. Pending queue not backing up (warns if >20 pending)

Exit 0 = proceed. Exit 1 = block dispatch.

---

## Sync / Merge Rules

`sync.sh` validates before merging any worktree:
- `.sh` files: `bash -n` syntax check
- `.py` files: `python3 -m py_compile`
- `.json` files: `jq .` validation

Merge is blocked if any check fails. Fix the error in the worktree first.

---

## Notification System

`webhook-fire.sh <event_type> <message> [json_payload]` fires to:
- Telegram (if `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` set in env)
- HTTP webhook (if `WEBHOOK_URL` set in env)
- Always logs to `swarm/logs/webhook.log`

Event types: `heartbeat | task_complete | task_failed | task_retry | alert | info`

Use `webhook-fire.sh` for all outbound notifications. Do not call `notify.sh` directly.

---

## Scope Boundaries

| Agent | May edit | May NOT edit |
|-------|----------|-------------|
| worker | content/draft/*.md | swarm scripts, infra, context files |
| technician | swarm scripts, infra, .claude/settings.json | content/, ghost/pages/, context/lvl2-brand-* |
| analyst | context/lvl2-keywords.md, lvl2-insights.md | content/, infra, swarm scripts |
| reviewer | context/lvl1-decisions.md | infra, swarm scripts, brand files |

Never `git push` without explicit user confirmation.
Never modify `.env` — update `.env.example` and note what user must set manually.
