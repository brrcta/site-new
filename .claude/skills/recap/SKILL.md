---
name: recap
description: Weekly review of priorities and progress. Use every week or when user says "recap", "weekly review", or "tower".
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Recap

## What you know

**Phase gates (from rules/phase-gates.md):**
- Phase 0: site live + legal pages → gate to Phase 1
- Phase 1: 20+ articles → gate to Phase 2
- Phase 2: 5+ page 1, 1k sessions → gate to Phase 3

**Priority ranking:** BLOCKER > HIGH > normal > nice-to-have

**Blockers slow everything downstream.** A Ghost login blocker in Phase 0 blocks all publishing.
Surface blockers first; don't let them sit below other items.

## Context to load

- @context/lvl1-todo-session.md — current todos and blockers
- @context/lvl1-decisions.md — recent decisions for context

## What a good recap produces

- Clear statement of the current phase and what the gate criteria require
- Top 3 priorities for next week (must unblock the current phase gate)
- Blockers called out explicitly with proposed resolution
- Completed items marked; stale items (no progress in 2+ weeks) flagged for removal or deferral
- Updated lvl1-todo-session.md with revised priorities

## Success criteria

- lvl1-todo-session.md reflects next week's actual priorities (not last week's leftovers)
- Every BLOCKER has a proposed resolution or an explicit decision to defer
- User can read the updated todo file and know exactly what to do first
