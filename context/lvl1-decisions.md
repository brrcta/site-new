# Decision Log

| Date | Decision | Rationale | Outcome |
|------|----------|-----------|---------|
| 2026-05-18 | Implemented Florian Vasin portfolio as `index.html` at repo root (Synthwave A design) | Claude Design handoff absorbed; self-contained HTML, no build step | Live in repo, ready for Coolify deploy |
| 2026-05-18 | Created `assets/memes/`, `assets/recs/` directories; hero image slot at `assets/hero.jpg` | Design probes these paths at runtime; placeholder fallbacks built in | Structure in place — images to be dropped in manually |
| 2026-05-18 | Deleted obsolete template scaffolding: `HANDOFF.md`, `SETUP.md`, `docker-compose.yml`, `handoff/`, `infra/telegram-bot/` | Handoff complete; no containers needed for static site; bot lives in separate repo | Repo cleaned up |
| 2026-05-18 | Deployment strategy: Coolify on existing VPS, not Vercel, not rawdog SSH | VPS already running (Ghost/Coolify); Coolify handles nginx + TLS + git webhook natively; rawdog SSH is premature at project 2 | Deploy via Coolify: connect repo → branch `main` → no build command → domain |
| 2026-05-18 | Dropped GitHub Actions for deployment; Coolify webhook replaces it | Redundant — Coolify pulls on push natively | Push to `main` → live in ~30s |
| 2026-05-18 | Cloudflare free tier recommended in front of VPS | Single-origin VPS is slow for images; Cloudflare edge-caches assets globally at no cost | To be set up at domain config time |
| 2026-05-18 | Images committed directly to repo (not persistent volume) | Small initial set (hero + memes + recs); under 50 MB threshold; simplest deploy path | Revisit if image set grows significantly |
