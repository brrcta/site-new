# {{PROJECT_NAME}} | root: {{ROOT_PATH}} | market: {{MARKET}}

## Lifecycle
start: .claude/hooks/session-start.sh -> context/lvl1-todo-session.md
end:   .claude/skills/wrapup/SKILL.md -> log context/lvl1-decisions.md
auto-detect: Reconcile context/lvl1-todo-session.md and context/lvl1-decisions.md against what actually happened in this conversation. Do not wait for the user to point this out.
todo-convention: Delete completed tasks from lvl1-todo-session.md outright — outcome lives in lvl1-decisions.md, no double bookkeeping. Do not use [x] ticks.
principles: think-before-coding | simplicity-first | surgical-changes | goal-driven | explicit-context-passing | tool-scope<=5 | retrieval-led

IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning. Read the indexed file before acting; do not answer from memory when an index entry exists.

## Principles

### Think Before Coding
Before any implementation: state the goal in one sentence, list assumptions, name the tradeoffs.
Ambiguous task → ask, never fill gaps with guesses.
Map every affected file before touching any of them.

### Simplicity First
Use the simplest implementation that satisfies the requirement — nothing more.
No new abstraction unless the pattern repeats 3+ times.
No new dependency without explicit justification.
No generalization for hypothetical future use cases.

### Surgical Changes
Only modify files the task explicitly requires.
No drive-by refactoring, no cleanup of unrelated code, no opportunistic improvements.
State the change set (files + reason) before executing.
Nearby issue spotted → flag it in a note, do not fix it.

### Goal-Driven Execution
Define success criteria before starting work.
Verify completion against the stated criteria — not against whether implementation looks complete.
Mark done only when each criterion is verified.

## Index (pipe-delimited; paths relative to root)

|context:{lvl1-todo-session.md:session-priorities,lvl1-decisions.md:decision-log,lvl2-project.md:project-context,lvl2-workflow.md:project-workflow,lvl2-tech-stack.md:infra-notes,lvl2-todo-backlog.md:backlog,lvl3-dump.md:inbox,lvl3-dump-archive.md:raw-archive,lvl3-decisions-archive.md:archive}

|.claude/commands:{research.md,status.md}

|.claude/skills:{distill/SKILL.md,recap/SKILL.md,wrapup/SKILL.md}

|.claude/agents:{technician.md:config+maintenance}

|.claude/rules:{phase-gates.md:phase-enforcement}

|.claude/hooks:{session-start.sh:deps+todo-print,stop-dump-check.sh:dump-context-warning,archive-logs.sh:token-budget-archival}

|swarm:{models.json:provider-role-routing,state.json:agent-counters,scripts/spawn.sh:tmux-launch,scripts/dispatch.sh:write-task,scripts/monitor.sh:foreground-dashboard,scripts/heartbeat.sh:event-driven-timer,scripts/heartbeat-install.sh:systemd-user-installer,scripts/notify.sh:telegram-send,scripts/sync.sh,scripts/setup.sh,scripts/cleanup.sh,scripts/bot-start.sh,scripts/bot-stop.sh,tasks/{pending,active,done}/*.json}

|infra:{telegram-bot/bot.py:long-poll-bridge,telegram-bot/telegram-bridge.service,telegram-bot/requirements.txt,systemd/affops-heartbeat.service,systemd/affops-heartbeat.timer}

## Project
name={{PROJECT_NAME}} | market={{MARKET}} | lang={{LANG}}

## Context loading
Auto-loaded every session (settings.json always_load): CLAUDE.md + context/lvl1-todo-session.md + context/lvl1-decisions.md. All other files are read on-demand via the index above. Load lvl2-* only when the task requires it; lvl3-* only on explicit request. Subagents do not share memory — pass context explicitly in every agent prompt.

## Interaction rules
- lvl3-dump: Save each thought verbatim under a `**raw:**` label. Follow with `**signal:**` — 1–3 sentences highlighting the sharpest, most actionable insight. Raw text is preserved; it may become a decision, doc section, or task later.
