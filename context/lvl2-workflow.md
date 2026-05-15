# Project Workflow

Read this when starting a new work cycle, when unsure which step runs next, or when a priority shifts mid-session.

This file ties the available commands and skills into a sequenced pipeline. It does not duplicate per-command docs — see `.claude/commands/*.md` and `.claude/skills/*/SKILL.md` for those.

---

## Pipeline at a glance

```
DISCOVERY ──→ RESEARCH ──→ PLAN ──→ BUILD ──→ VERIFY ──→ SHIP ──→ MONITOR
                                      ▲                              │
                                      └─────── feedback loop ────────┘

Maintenance loops (orthogonal):  /recap weekly  ·  /distill 7-10d  ·  /wrapup session-end
```

---

## Stage table

| # | Stage | Trigger | Command / Skill | Input | Output | Next |
|---|-------|---------|-----------------|-------|--------|------|
| 1 | Discovery | new area to explore | `/research [topic]` | topic string | findings in `lvl3-dump.md` | Plan |
| 2 | Plan | decision needed | manual + `lvl1-todo-session.md` | findings + constraints | task list updated | Build |
| 3 | Build | task prioritized | implement via Claude | task spec | code / config / content | Verify |
| 4 | Verify | implementation done | test / review | output | pass or rework | Ship or rework |
| 5 | Ship | verified | deploy / commit / publish | verified output | live change | Monitor |
| 6 | Monitor | shipped | `/status` + observation | live signals | feedback | Discovery or Plan |

---

## Decision gates

- **Build → Verify**: never skip. At minimum, read the output back before marking done.
- **Verify → Ship**: only ship when each stated success criterion is met.
- **Discovery → Plan**: raw findings go to `lvl3-dump.md` first; surface to `lvl2-project.md` only after `/distill`.

---

## Maintenance loops

Run these on cadence, not per-task.

| Loop | Cadence | Skill | What it does |
|------|---------|-------|--------------|
| `/recap` | weekly | `.claude/skills/recap/SKILL.md` | review phase-gate metrics, surface blockers, refresh `lvl1-todo-session.md` |
| `/distill` | every 7-10 days | `.claude/skills/distill/SKILL.md` | extract signal from `lvl3-dump.md` into permanent `lvl2-*` files; archive raw |
| `/wrapup` | session end | `.claude/skills/wrapup/SKILL.md` | log decisions to `lvl1-decisions.md`, trim context |

---

## Worked example: "[replace with your task type]"

1. `/research "[topic]"` → findings appended to `lvl3-dump.md`
2. Pull relevant items into `lvl1-todo-session.md` as concrete tasks
3. Implement top-priority task → verify output against success criteria
4. `/wrapup` → decisions logged, todo cleaned up

---

## Customizing this workflow

This is a minimal skeleton. Add stages, commands, and verification steps as your project's needs become clear. The pipeline should reflect real work — not an idealized process.
