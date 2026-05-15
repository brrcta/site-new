---
name: wrapup
description: End-of-session wrap-up. Use when session ends or user says "wrap up".
allowed-tools: Read, Write, Edit
---

# Session Wrapup

## What you know

**Context lifecycle:**
- lvl1-decisions.md = rolling 30-day decision log (always-loaded)
- lvl1-todo-session.md = current sprint todos (always-loaded)
- lvl3-decisions-archive.md = decisions older than 30 days (not loaded by default)

**Decision format:**
```
| YYYY-MM-DD | Decision text | Rationale | Outcome |
```
Append new rows to the table in lvl1-decisions.md. Do not create new headings — extend the table.

**30-day trim rule:** decisions older than `today - 30 days` are moved to lvl3-decisions-archive.md.
Append moved rows to the archive table (create archive if missing). Delete from lvl1-decisions.md.

**Todo rules:**
- Mark completed items with `[x]`
- Add newly discovered items as `[ ]`
- Do not delete any items — keep history visible

## Process

1. Summarize key decisions made this session (read conversation context)
2. Append decisions to @context/lvl1-decisions.md
3. Update @context/lvl1-todo-session.md (mark completed, add new)
4. Move rows older than 30 days from lvl1-decisions.md → context/lvl3-decisions-archive.md

## Success criteria

- All session decisions logged in lvl1-decisions.md
- Completed todos marked `[x]` in lvl1-todo-session.md
- No rows older than 30 days remain in lvl1-decisions.md
- Archive updated if any rows were moved
