# Tech Stack

| Component | Technology |
|-----------|------------|
| <!-- e.g. Backend --> | <!-- e.g. Python / Node / Go --> |
| <!-- e.g. Hosting --> | <!-- e.g. Hetzner VPS / Fly.io / Vercel --> |
| <!-- e.g. Containers --> | <!-- e.g. Docker --> |
| Automation | Claude Code CLI, Cron |
| Remote Control | Telegram bot (`infra/telegram-bot/bot.py`) |

---

## Agent Architecture Principles

- **Three levels of guardrails**: prompt rules = hope; voluntary gates = optional; infrastructure enforcement = mandatory. Level 1 is not security.
- **Scripts vs agents**: scripts produce facts, agents do thinking. Never use an agent to produce a fact a script can produce for free. Never use a script to do reasoning.
- **One backend, two front doors**: don't build a separate "AI API." One good API — humans use UI, agents use skills layer, both hit the same backend with the same auth.
- **Event-driven for token efficiency**: bash pre-check gate (0 tokens) → spawn LLM only when tasks exist. Cron → gate → LLM is the default pattern.
- **Security defaults**: least privilege not prompts; readonly prod; named write endpoints only; wrap external input in UNTRUSTED tags; billing caps; audit trails everywhere.

---

## File Organization Rule

> One source of truth per concern. Config in `infra/`, orchestration in `swarm/`, context in `context/`, project-specific code in its own directory.
