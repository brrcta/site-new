# Handoff Protocol — Claude Design → site-new

This repo is the **operations layer** for the site Claude Design is producing.
Design owns the website files; this side owns context, automation, deployment, and content ops.

---

## Drop zone

Claude Design should land delivered artifacts under:

```
handoff/from-design/
```

Anything written there is treated as inbound. Once accepted, files move to
their final home (see "Acceptance routing" below) and the drop folder is cleared.

---

## Expected payload

| Artifact | Where it lands inside `handoff/from-design/` | Routes to |
|----------|---------------------------------------------|-----------|
| Website source (whole site) | `site/` | repo root or `site/` (decide on first handoff) |
| Brand identity (name, mission, ICP, voice, market, language) | `brand.md` | fills `CLAUDE.md` placeholders + `context/lvl2-project.md` |
| Visual assets (logos, palette, typography, mockups) | `assets/` | `site/public/` or `assets/` once accepted |
| Tech stack decisions (framework, hosting, CMS) | `tech-stack.md` | `context/lvl2-tech-stack.md` |
| Content strategy (pillars, plan, voice rules) | `content/` | `content/AGENTS.md` + new `context/lvl2-content-*.md` |
| Phase plan (milestones, gates) | `phases.md` | `.claude/rules/phase-gates.md` |
| Required env vars / secrets list | `env.md` | merged into `.env.example` |

If any artifact is missing on receipt, log it as a blocker in `context/lvl1-todo-session.md`
before processing the rest.

---

## Acceptance routing (on receipt)

1. Read everything under `handoff/from-design/` once before moving anything.
2. Apply `brand.md` first — it fills `CLAUDE.md` placeholders and unblocks every
   downstream context file.
3. Move website source into final position; commit as a single "import design handoff" commit.
4. Update `context/lvl2-project.md`, `lvl2-tech-stack.md`, `.claude/rules/phase-gates.md`
   in one pass. Don't drift the placeholders — replace every `{{PLACEHOLDER}}`.
5. Update `content/AGENTS.md` and `swarm/AGENTS.md` — both currently contain
   template content from the upstream `affops` project and must be rewritten
   for this project's brand/voice/stack.
6. Add new env keys to `.env.example`. Never commit a real `.env`.
7. Run `.claude/hooks/session-start.sh` mentally — if it expects a stack
   (npm/pip/etc.) the design didn't provide, add the install line now.
8. Log the handoff acceptance as a row in `context/lvl1-decisions.md`.
9. Empty `handoff/from-design/` (keep `.gitkeep`).

---

## Open questions to resolve at handoff

- Does the website live at the repo root, or in `site/`? (Affects gitignore + hooks.)
- Which package manager? (Affects `session-start.sh`.)
- Deployment target — VPS via `infra/setup-vps.sh`, or somewhere else? If
  somewhere else, `infra/` may need to be retired or rewritten.
- Does the project need the `swarm/` orchestration layer at all? It is heavy
  and only earns its keep when multiple parallel Claude sessions are doing
  scheduled work. Default to leaving it dormant until a use case appears.

---

## What is already wired

- `.claude/settings.json` — permissions, session hooks, always-loaded context
- `.claude/hooks/session-start.sh` — placeholder; add deps on handoff
- `.claude/hooks/stop-dump-check.sh`, `archive-logs.sh` — context window hygiene
- `.claude/commands/{research,status}.md` — generic, keep
- `.claude/skills/{distill,recap,wrapup}/SKILL.md` — generic, keep
- `.claude/agents/technician.md` — generic, keep
- `context/lvl1-*` — empty, populate during operation
- `context/lvl2-*` — placeholder content, fill from `brand.md` + `tech-stack.md`
- `context/lvl3-*` — empty inbox + archives
- `swarm/` — full orchestration layer, dormant until needed
- `infra/telegram-bot/` — optional remote control, requires VPS setup
