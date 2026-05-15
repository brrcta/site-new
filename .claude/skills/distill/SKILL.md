---
name: distill
description: Distill raw inspiration from lvl3-dump into permanent tier2 files, then prune. Use when user says "distill" or on a 7-10 day cadence.
allowed-tools: Read, Write, Edit, Grep
---

# Distill

## What you know

**Tier system:**
- lvl3-dump.md = raw inbox (unfiltered; grows freely between distill runs)
- lvl2-* files = permanent knowledge base (principles only; no raw examples)
- lvl3-dump-archive.md = verbatim archive (preserved for quote mining + voice fine-tuning)

**Tag → target file mapping:**
- `brand-voice`, `copywriting` → lvl2-brand-voice.md
- `content-pillars` → lvl2-content-pillars.md (hub/cluster strategy only)
- `content-ideas` → lvl2-content-plan.md (concrete article candidates)
- `seo` → lvl2-keywords.md
- `niche` → lvl2-brand-icp.md (audience observations)
- `worldview`, `philosophy` → lvl2-brand-philosophy.md
- `positioning` → lvl2-brand-icp.md (Competitive Positioning section)
- `ai-infra` → lvl2-tech-stack.md

**Disambiguation:**
- `niche` + audience observation → lvl2-brand-icp.md | brand belief → lvl2-brand-philosophy.md
- `content-pillars` + hub/cluster strategy → lvl2-content-pillars.md | concrete article → lvl2-content-plan.md

**Extraction rules:**
- Extract **principles**, not examples ("Warning frames outperform positive frames" not "here's a subject line")
- One bullet point per insight added to a target file
- If already covered in different words → skip (no duplicates)
- If no tag maps → leave in dump, don't force it

**State markers:**
- Undistilled: `## YYYY-MM-DD` (no suffix)
- Distilled: `## YYYY-MM-DD [distilled YYYY-MM-DD]`
- Stale: `## YYYY-MM-DD [stale — review]` (>30 days, never distilled)

## Process

1. Read @context/lvl3-dump.md in full
2. For each entry NOT marked `[distilled]`:
   a. Check tag → determine target file
   b. Read target file → check if entry adds net-new signal
   c. If yes: extract principle → append to appropriate section
   d. Mark entry: `## YYYY-MM-DD [distilled YYYY-MM-DD]`
3. Archive: for each `[distilled ...]` entry where distill date > 10 days old:
   a. Append full entry block to @context/lvl3-dump-archive.md
   b. Remove entry from @context/lvl3-dump.md
4. Flag: entries older than 30 days without distillation → append `[stale — review]`

## Success criteria

- No un-distilled entries remain that have actionable signal
- All distilled entries older than 10 days moved to archive
- Stale entries (>30d undistilled) flagged
- lvl2 files updated with extracted principles
- Report: entries processed / extracted / archived / remaining

## Report to user

- How many entries processed
- What was extracted and where it went
- How many entries archived to lvl3-dump-archive.md
- How many entries remain in the dump
