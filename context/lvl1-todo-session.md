# Session TODOs

> Pull tasks here from lvl2-todo-backlog.md at the start of each session. Delete completed items — outcomes live in lvl1-decisions.md.

## Design handoff — completed

- [x] Read design handoff files (fetched from Claude Design API, extracted tar bundle)
- [x] Move website source to final location — `index.html` at repo root
- [x] Decide whether `swarm/` and `infra/telegram-bot/` are in scope — swarm kept, telegram-bot removed
- [x] Log handoff acceptance in `context/lvl1-decisions.md`
- [x] Empty `handoff/from-design/` and remove obsolete scaffolding

## Deploy — next actions

- [ ] Deploy `index.html` to Coolify: new Static Site resource → connect `brrcta/site-new` → branch `main` → no build command → set domain
- [ ] Point DNS A record at VPS IP
- [ ] Set up Cloudflare free tier in front of VPS for edge image caching

## Content — fill before going live

- [ ] Drop `assets/hero.jpg` (2400×1030) — cinematic banner
- [ ] Drop `assets/memes/01–09.jpg` — CEO of Memes slider
- [ ] Drop `assets/recs/01–03.jpg` and fill `RX_ITEMS` array in `index.html` with real products
- [ ] Fill Impressum placeholders in `index.html` (legal modal) with real operator details from `context/operator.md`
- [ ] Fill Datenschutz placeholders in `index.html` (legal modal) — hoster name, log retention period
- [ ] Wire guestbook `fetch('/api/guestbook', …)` stub to a real backend endpoint when ready

## Remaining template cleanup

- [ ] Fill `{{PROJECT_NAME}}`, `{{ROOT_PATH}}`, `{{MARKET}}`, `{{LANG}}` in `CLAUDE.md`
- [ ] Rewrite `content/AGENTS.md` and `swarm/AGENTS.md` — still contain affops template content
- [ ] Update `.claude/rules/phase-gates.md` with project-specific phases
