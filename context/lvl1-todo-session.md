# Session TODOs

> Pull tasks here from lvl2-todo-backlog.md at the start of each session. Delete completed items — outcomes live in lvl1-decisions.md.

## NEXT SESSION — Awaiting Claude Design handoff

Receive payload at `handoff/from-design/` and process per `HANDOFF.md`.

### On receipt (in this order)

- [ ] Read every file under `handoff/from-design/` before moving anything
- [ ] Apply `brand.md` → fill `{{PROJECT_NAME}}`, `{{ROOT_PATH}}`, `{{MARKET}}`, `{{LANG}}` in `CLAUDE.md`
- [ ] Move website source to its final location (root vs `site/` — decide and log)
- [ ] Populate `context/lvl2-project.md` from `brand.md`
- [ ] Populate `context/lvl2-tech-stack.md` from `tech-stack.md`
- [ ] Replace `.claude/rules/phase-gates.md` defaults with project phases from `phases.md`
- [ ] Rewrite `content/AGENTS.md` and `swarm/AGENTS.md` — both currently contain affops/movinslooow template content
- [ ] Merge new keys from `env.md` into `.env.example`
- [ ] Update `.claude/hooks/session-start.sh` with the project's dependency install command
- [ ] Decide whether `swarm/` and `infra/telegram-bot/` are in scope or should be retired
- [ ] Log handoff acceptance row in `context/lvl1-decisions.md`
- [ ] Empty `handoff/from-design/` (keep `.gitkeep`)
- [ ] Fill operator details from `context/operator.md` (Florian Vasin, hi@florianvasin.com, +49 152 230 976 80, Hildastr. 16, DE-77654, Offenburg) into all `{{OPERATOR_NAME}}`, `{{KONTAKT_EMAIL}}`, etc. placeholders across all pages
- [ ] Route `content/pages/affiliate-disclaimer.html` → final stack page (`/affiliate-hinweis`); replace every `{{PLACEHOLDER}}` (use operator.md); remove the Amazon `<aside>` if Amazon Partnerprogramm is not used
- [ ] Create the Impressum page (`/impressum`) per German law (§ 5 TMG) — required fields: responsible person (Florian Vasin), address, email, phone, business form, tax ID. Reference `context/operator.md`.
- [ ] Embed `content/pages/snippets/footer-disclaimers.html` in the site footer (every page) — replace placeholders
- [ ] Wire `content/pages/snippets/nicotine-warning-block.html` into the page template/component used for any nicotine-product post (above-the-fold)
- [ ] Convert `content/pages/snippets/nicotine-inline-tag.html` into a reusable component/partial; require it next to every affiliate link to a nicotine product
- [ ] Confirm editorial copy contains zero HWG-triggering phrases (no Raucherentwöhnung / harm-reduction / health-effect claims)

> Projects sub-page is deferred. The Higgsfield → web video pipeline is
> already documented in `content/pages/videos/README.md` and will be picked
> up when the page is actually built.
- [ ] Delete this NEXT SESSION block once handoff is fully absorbed
