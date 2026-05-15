# Backlog TODOs

> Non-urgent items. Pull into lvl1-todo-session.md when relevant.

## Infrastructure

- [ ] Harden VPS: SSH key-only auth, fail2ban, automatic security updates
- [ ] Set up monitoring (e.g. Uptime Kuma via Docker, bound to 127.0.0.1:3001)
- [ ] Configure automated backups
- [ ] Set up Cloudflare Tunnel if reverse proxy without exposed ports is needed

## Remote Control

- [ ] Set up Telegram bot for phone-based Claude triggers (see `infra/telegram-bot/`)
- [ ] Test end-to-end: phone → Telegram → bot.py → Claude Code CLI → output

## Claude Code Enhancements

- [ ] Add `FIRECRAWL_API_KEY` to `settings.json` env block to enable `tools/scrape.py`
- [ ] Add `Bash(python3 tools/scrape.py *)` to `settings.json` permissions allow list
- [ ] Add `paths:` frontmatter to rules when project directories grow and scope-limiting becomes useful
- [ ] Customize phase-gates.md with project-specific milestones

## Project-Specific

<!-- Add your project's backlog items here -->
