# Dump — Raw Inspiration & Reference

> Staging area for raw content, links, quotes, patterns. NOT always-loaded.
> Run `/distill` every 7-10 days to extract signal into permanent tier2 files.
> Format: `**raw:**` label followed by verbatim content, then `**signal:**` with 1–3 sentence insight.

---

## 2026-05-19 — TG bot guestbook integration (deferred)

**raw:** VPS-wide Telegram bot with per-project handlers routed by group chat ID. This site gets its own TG chat. Once the chat is live, the bot should: (1) notify on new guestbook submission (watches guestbook-pending.json), (2) let me approve/reject via TG reply command. guestbook-api.py already writes to guestbook-pending.json; gb-approve.sh already has the approve/reject logic — TG handler just needs to call those same operations. Do NOT code until chat ID is known.

**signal:** Hook point is clear — guestbook-api.py appends to guestbook-pending.json; the TG handler watches that file (inotify or poll) and sends a message with inline approve/reject buttons. Approval calls the same Python block as gb-approve.sh approve N.

---

## 2026-05-15 — Infra bootstrap, pre-handoff

**raw:** Repo initialised from `whitelabel-claude-ops.zip` (a generic Claude Code ops template lifted from the `affops`/`movinslooow` project for parentslist.eu). All scaffolding extracted, scripts made executable, handoff inbox created at `handoff/from-design/`. Brand placeholders in `CLAUDE.md` and `context/lvl2-*` deliberately left empty — Claude Design will deliver the whole website plus brand/identity/stack inputs and this side will absorb them per `HANDOFF.md`.

**signal:** Two files still carry upstream template content and MUST be rewritten on handoff: `content/AGENTS.md` (movinslooow brand/voice/HWG rules, EU parenting niche) and `swarm/AGENTS.md` (affops worker/reviewer/analyst role caps). Treat both as placeholder text, not active config.
