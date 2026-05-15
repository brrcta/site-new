#!/usr/bin/env python3
"""
Telegram bridge for Claude Code CLI.
Full access: slash commands, agents, skills, natural language.
Only responds to TELEGRAM_ALLOWED_USER_ID (owner only).

Limitation: non-interactive (--print mode). No mid-task clarifications.
"""
import json
import os
import subprocess
import logging
from pathlib import Path
from telegram import Update, BotCommand
from telegram.ext import ApplicationBuilder, MessageHandler, CommandHandler, filters, ContextTypes

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

ALLOWED_USER_ID = int(os.environ["TELEGRAM_ALLOWED_USER_ID"])
WORK_DIR = os.environ.get("WORK_DIR", "/home/user/affops")
CLAUDE_BIN = os.environ.get("CLAUDE_BIN", "claude")
TIMEOUT = int(os.environ.get("CLAUDE_TIMEOUT", "300"))  # 5 min default

PERMISSION_KEYWORDS = (
    "permission denied",
    "not allowed",
    "requires approval",
    "unauthorized",
    "tool use denied",
    "tool call denied",
)

SKIP_PERMISSIONS = os.environ.get("CLAUDE_SKIP_PERMISSIONS", "false").lower() == "true"


def _load_models_json() -> dict:
    path = Path(WORK_DIR) / "swarm" / "models.json"
    try:
        return json.loads(path.read_text())
    except Exception as e:
        log.warning("Could not load swarm/models.json (%s) — using fallback model routing", e)
        return {}


def _build_cmd_routing(data: dict) -> tuple[dict[str, str], dict[str, int]]:
    """Resolve command → (model, max_tokens) from models.json cmd_routing block."""
    providers = data.get("providers", {})
    token_caps = data.get("token_caps", {})
    cmd_routing = data.get("cmd_routing", {})

    # Fallback hardcoded values (Anthropic) if models.json is absent or incomplete
    _fallback_models = {
        "worker":      "claude-opus-4-6",
        "reviewer":    "claude-sonnet-4-6",
        "analyst":     "claude-haiku-4-5-20251001",
        "orchestrator": "claude-opus-4-6",
    }
    _fallback_caps = {
        "worker": 6000, "reviewer": 2000, "analyst": 1000, "orchestrator": 4000,
    }

    swarm_default = data.get("swarm_default", {})
    default_provider = swarm_default.get("provider", "anthropic")

    cmd_models: dict[str, str] = {}
    cmd_caps: dict[str, int] = {}

    for cmd, routing in cmd_routing.items():
        if cmd.startswith("_"):
            continue
        role = routing.get("role", "worker")
        provider = routing.get("provider", default_provider)
        provider_data = providers.get(provider, {})
        model = provider_data.get("models", {}).get(role) or _fallback_models.get(role, "claude-haiku-4-5-20251001")
        cap = token_caps.get(role) or _fallback_caps.get(role, 1000)
        cmd_models[cmd] = model
        cmd_caps[cmd] = cap

    return cmd_models, cmd_caps


# Load routing from swarm/models.json at startup (provider-agnostic)
_MODELS_DATA = _load_models_json()
CMD_MODELS, CMD_CAPS = _build_cmd_routing(_MODELS_DATA)

# Commands that skip Claude and run Python scripts directly (0 tokens).
# Values are callables: (args: str) -> list[str]
DIRECT_SCRIPTS: dict[str, object] = {
    "/ghost-status": lambda _: ["python3", "ghost/scripts/publish-post.py", "--list"],
    "/ghost-pages":  lambda _: ["python3", "ghost/scripts/publish.py",      "--list"],
    "/publish":      lambda a: ["python3", "ghost/scripts/publish-post.py"] + (a.split() if a else []),
    "/publish-draft": lambda a: ["python3", "ghost/scripts/publish-post.py", "--draft"] + (a.split() if a else []),
    "/publish-page": lambda a: ["python3", "ghost/scripts/publish.py"]      + (a.split() if a else []),
}


def run_claude(prompt: str, model: str | None = None, max_tokens: int | None = None) -> str:
    """Run Claude Code CLI non-interactively, return tagged output."""
    cmd = [CLAUDE_BIN, "--print"]
    if SKIP_PERMISSIONS:
        cmd.append("--dangerously-skip-permissions")
    if model:
        cmd.extend(["--model", model])
    if max_tokens:
        cmd.extend(["--max-tokens", str(max_tokens)])
    cmd.append(prompt)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=TIMEOUT,
            cwd=WORK_DIR,
            env=os.environ.copy(),
        )
        output = result.stdout.strip() or result.stderr.strip() or "(no output)"

        # Surface permission blocks clearly instead of burying them in output
        lower = output.lower()
        if any(kw in lower for kw in PERMISSION_KEYWORDS):
            return f"NEEDS PERMISSION\n\n{output}\n\nFix: add the tool to allow list in .claude/settings.json, or set CLAUDE_SKIP_PERMISSIONS=true in .env"

        if result.returncode != 0:
            return f"ERROR (exit {result.returncode})\n\n{output}"

        return f"{output}\n\nDone."

    except subprocess.TimeoutExpired:
        return f"TIMEOUT after {TIMEOUT}s — task did not complete. Increase CLAUDE_TIMEOUT in .env if needed."
    except FileNotFoundError:
        return f"Claude CLI not found at '{CLAUDE_BIN}'. Run: npm install -g @anthropic-ai/claude-code"
    except Exception as e:
        log.exception("run_claude failed")
        return f"ERROR: {e}"


def is_owner(update: Update) -> bool:
    return update.effective_user.id == ALLOWED_USER_ID


async def send_chunked(update: Update, text: str):
    """Send reply in <=4000 char chunks (Telegram limit: 4096)."""
    for i in range(0, len(text), 4000):
        await update.message.reply_text(text[i:i + 4000])


def run_direct(script_cmd: list[str]) -> str:
    """Run a Python script directly — bypasses Claude, costs 0 tokens."""
    try:
        result = subprocess.run(
            script_cmd, capture_output=True, text=True, timeout=TIMEOUT, cwd=WORK_DIR
        )
        output = result.stdout.strip() or result.stderr.strip() or "(no output)"
        return output if result.returncode == 0 else f"ERROR (exit {result.returncode})\n\n{output}"
    except subprocess.TimeoutExpired:
        return f"TIMEOUT after {TIMEOUT}s"
    except Exception as e:
        return f"ERROR: {e}"


async def run_and_reply(update: Update, prompt: str, status_msg: str = "Working..."):
    await update.message.reply_text(status_msg)

    # Route to direct script (0 tokens) if configured
    cmd_key = prompt.split()[0] if prompt.startswith("/") else None
    if cmd_key and cmd_key in DIRECT_SCRIPTS:
        cmd_args = prompt[len(cmd_key):].strip()
        output = run_direct(DIRECT_SCRIPTS[cmd_key](cmd_args))
    else:
        model = CMD_MODELS.get(cmd_key) if cmd_key else None
        cap = CMD_CAPS.get(cmd_key) if cmd_key else None
        output = run_claude(prompt, model=model, max_tokens=cap)

    await send_chunked(update, output)


async def scrape_then_claude(
    update: Update,
    scraper_cmd: list[str],
    claude_prompt: str,
    scrape_msg: str = "Scraping...",
    think_msg: str = "Analyzing...",
):
    """Pre-fetch web data via Firecrawl, then pass enriched context to Claude.
    Claude receives real page content and only reasons — never fetches."""
    await update.message.reply_text(scrape_msg)
    scraped = run_direct(scraper_cmd)

    if scraped.startswith("ERROR") or scraped.startswith("TIMEOUT"):
        await update.message.reply_text(f"Scrape failed: {scraped}\nFalling back to AI-only mode.")
        await update.message.reply_text(think_msg)
        cmd_key = claude_prompt.split()[0] if claude_prompt.startswith("/") else None
        model = CMD_MODELS.get(cmd_key) if cmd_key else None
        cap = CMD_CAPS.get(cmd_key) if cmd_key else None
        output = run_claude(claude_prompt, model=model, max_tokens=cap)
    else:
        await update.message.reply_text(think_msg)
        enriched = f"<scraped_data>\n{scraped}\n</scraped_data>\n\n{claude_prompt}"
        cmd_key = claude_prompt.split()[0] if claude_prompt.startswith("/") else None
        model = CMD_MODELS.get(cmd_key) if cmd_key else None
        cap = CMD_CAPS.get(cmd_key) if cmd_key else None
        output = run_claude(enriched, model=model, max_tokens=cap)

    await send_chunked(update, output)


# --- Built-in commands ---

async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update):
        return
    await update.message.reply_text(
        "Claude Code — full remote control\n\n"
        "DIRECT (0 tokens — instant)\n"
        "/ghost-status — list all posts + status\n"
        "/ghost-pages — list all pages + status\n"
        "/publish <slug> — publish post live\n"
        "/publish-draft <slug> — push post as draft\n"
        "/publish-page <slug> — publish page live\n\n"
        "AI COMMANDS\n"
        "/status — todos + recommended next action\n"
        "/draft <keyword> — draft article outline\n"
        "/research <topic> — research + save insights\n"
        "/analytics — phase progress + recommendations\n"
        "/qualify <keyword> — KD/volume/intent go/no-go\n"
        "/track <keyword> — SERP position check\n"
        "/trends <keyword> — seasonal patterns\n"
        "/competitors <url> — competitor analysis\n\n"
        "AI SKILLS (multi-step)\n"
        "/batch <k1,k2,...> — batch write articles\n"
        "/optimize <slug> — SEO optimize article\n"
        "/cluster <keywords> — cluster by intent\n"
        "/weekly — weekly review\n\n"
        "Or send any plain text as a Claude prompt.\n"
        "Note: non-interactive — no mid-task Q&A."
    )


# --- Direct commands (0 tokens) ---

async def cmd_ghost_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, "/ghost-status", "Fetching posts...")


async def cmd_ghost_pages(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, "/ghost-pages", "Fetching pages...")


async def cmd_publish(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    slug = " ".join(context.args)
    if not slug:
        await update.message.reply_text("Usage: /publish <slug>")
        return
    await run_and_reply(update, f"/publish {slug}", f"Publishing: {slug}...")


async def cmd_publish_draft(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    slug = " ".join(context.args)
    if not slug:
        await update.message.reply_text("Usage: /publish_draft <slug>")
        return
    await run_and_reply(update, f"/publish-draft {slug}", f"Pushing draft: {slug}...")


async def cmd_publish_page(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    slug = " ".join(context.args)
    if not slug:
        await update.message.reply_text("Usage: /publish_page <slug>")
        return
    await run_and_reply(update, f"/publish-page {slug}", f"Publishing page: {slug}...")


# --- AI commands (maps to .claude/commands/) ---

async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, "/status", "Fetching status...")


async def cmd_draft(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keyword = " ".join(context.args)
    if not keyword:
        await update.message.reply_text("Usage: /draft <keyword>")
        return
    await run_and_reply(update, f"/draft {keyword}", f"Drafting: {keyword}...")


async def cmd_research(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    topic = " ".join(context.args)
    if not topic:
        await update.message.reply_text("Usage: /research <topic>")
        return
    await scrape_then_claude(
        update,
        scraper_cmd=["python3", "tools/scrape.py", "search", topic, "--limit", "8"],
        claude_prompt=f"/research {topic}",
        scrape_msg=f"Searching: {topic}...",
        think_msg="Synthesizing findings...",
    )


async def cmd_analytics(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, "/analytics", "Running analytics...")


async def cmd_qualify(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keyword = " ".join(context.args)
    if not keyword:
        await update.message.reply_text("Usage: /qualify <keyword>")
        return
    await run_and_reply(update, f"/qualify {keyword}", f"Qualifying: {keyword}...")


async def cmd_track(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keyword = " ".join(context.args)
    if not keyword:
        await update.message.reply_text("Usage: /track <keyword>")
        return
    await scrape_then_claude(
        update,
        scraper_cmd=["python3", "tools/scrape.py", "search", keyword, "--limit", "10"],
        claude_prompt=f"/track {keyword}",
        scrape_msg=f"Fetching SERP: {keyword}...",
        think_msg="Checking position...",
    )


async def cmd_trends(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keyword = " ".join(context.args)
    if not keyword:
        await update.message.reply_text("Usage: /trends <keyword>")
        return
    await run_and_reply(update, f"/trends {keyword}", f"Checking trends: {keyword}...")


async def cmd_competitors(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    target = " ".join(context.args)
    if not target:
        await update.message.reply_text("Usage: /competitors <url-or-domain>")
        return
    url = target if target.startswith("http") else f"https://{target}"
    await scrape_then_claude(
        update,
        scraper_cmd=["python3", "tools/scrape.py", "crawl", url, "--limit", "8"],
        claude_prompt=f"/competitors {target}",
        scrape_msg=f"Crawling {target}...",
        think_msg="Extracting patterns...",
    )


# --- Skills (maps to .claude/skills/) ---

async def cmd_batch(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keywords = " ".join(context.args)
    if not keywords:
        await update.message.reply_text("Usage: /batch <keyword1, keyword2, ...>")
        return
    await run_and_reply(update, f"/content-batch {keywords}", f"Batch writing: {keywords}...")


async def cmd_optimize(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    target = " ".join(context.args)
    if not target:
        await update.message.reply_text("Usage: /optimize <slug-or-url>")
        return
    await run_and_reply(update, f"/content-optimize {target}", f"Optimizing: {target}...")


async def cmd_cluster(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    keywords = " ".join(context.args)
    if not keywords:
        await update.message.reply_text("Usage: /cluster <keyword1, keyword2, ...>")
        return
    await run_and_reply(update, f"/keyword-cluster {keywords}", "Clustering keywords...")


async def cmd_trend_watch(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    focus = " ".join(context.args)
    # Scrape Reddit parenting hot posts + a news search as signal sources
    reddit_urls = [
        "https://www.reddit.com/r/AttachmentParenting/hot.json?limit=25",
        "https://www.reddit.com/r/Parenting/hot.json?limit=25",
        "https://www.reddit.com/r/Montessori/hot.json?limit=20",
    ]
    await update.message.reply_text("Scanning trending signals (Reddit + news)...")
    scraped_parts = []
    for url in reddit_urls:
        result = run_direct(["python3", "tools/scrape.py", "page", url])
        if not result.startswith("ERROR"):
            scraped_parts.append(result)
    # Also run a news search for the focus topic
    search_q = f"parenting {focus} news 2026" if focus else "conscious parenting news 2026"
    news = run_direct(["python3", "tools/scrape.py", "search", search_q, "--limit", "6"])
    if not news.startswith("ERROR"):
        scraped_parts.append(f"## News search: {search_q}\n\n{news}")

    prompt = f"/trend-watch {focus}".strip()
    if scraped_parts:
        await update.message.reply_text("Identifying trends...")
        enriched = f"<scraped_data>\n{'---'.join(scraped_parts)}\n</scraped_data>\n\n{prompt}"
        output = run_claude(enriched, model=CMD_MODELS.get("/trend-watch"), max_tokens=CMD_CAPS.get("/trend-watch"))
    else:
        await update.message.reply_text("Scrape failed — running AI-only mode...")
        output = run_claude(prompt)
    await send_chunked(update, output)


async def cmd_competitor_watch(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    target = " ".join(context.args)
    # If a specific domain given, crawl it; otherwise Claude handles the full watch cycle
    if target:
        url = target if target.startswith("http") else f"https://{target}"
        await scrape_then_claude(
            update,
            scraper_cmd=["python3", "tools/scrape.py", "crawl", url, "--limit", "5"],
            claude_prompt=f"/competitor-watch {target}",
            scrape_msg=f"Crawling {target} for new articles...",
            think_msg="Extracting gaps and patterns...",
        )
    else:
        await run_and_reply(update, "/competitor-watch", "Running competitor watch (AI reads tracked list)...")


async def cmd_weekly(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, "/weekly-tower", "Running weekly review...")


# --- Plain text → raw Claude prompt ---

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_owner(update): return
    await run_and_reply(update, update.message.text)


# --- Main ---

async def post_init(app):
    """Register bot commands so they show up in Telegram's command menu."""
    await app.bot.set_my_commands([
        BotCommand("help", "Show all commands"),
        # Direct (0 tokens)
        BotCommand("ghost_status", "List posts + status [instant]"),
        BotCommand("ghost_pages", "List pages + status [instant]"),
        BotCommand("publish", "Publish post live [slug]"),
        BotCommand("publish_draft", "Push post as draft [slug]"),
        BotCommand("publish_page", "Publish page live [slug]"),
        # AI
        BotCommand("status", "Todos + next action"),
        BotCommand("draft", "Draft article outline [keyword]"),
        BotCommand("research", "Research topic [topic]"),
        BotCommand("analytics", "Phase progress + recommendations"),
        BotCommand("qualify", "Keyword go/no-go [keyword]"),
        BotCommand("track", "SERP position [keyword]"),
        BotCommand("trends", "Seasonal patterns [keyword]"),
        BotCommand("competitors", "Competitor deep-dive [url] ✦scrape"),
        BotCommand("competitor_watch", "Weekly competitor surveillance ✦scrape"),
        BotCommand("trend_watch", "Trending topics scan ✦scrape"),
        BotCommand("batch", "Batch write articles [k1,k2,...]"),
        BotCommand("optimize", "SEO optimize article [slug]"),
        BotCommand("cluster", "Cluster keywords [k1,k2,...]"),
        BotCommand("weekly", "Weekly review"),
    ])


if __name__ == "__main__":
    token = os.environ["TELEGRAM_TOKEN"]
    app = ApplicationBuilder().token(token).post_init(post_init).build()

    for cmd, handler in [
        ("start", cmd_help), ("help", cmd_help),
        # Direct (0 tokens)
        ("ghost_status", cmd_ghost_status),
        ("ghost_pages", cmd_ghost_pages),
        ("publish", cmd_publish),
        ("publish_draft", cmd_publish_draft),
        ("publish_page", cmd_publish_page),
        # AI
        ("status", cmd_status),
        ("draft", cmd_draft),
        ("research", cmd_research),
        ("analytics", cmd_analytics),
        ("qualify", cmd_qualify),
        ("track", cmd_track),
        ("trends", cmd_trends),
        ("competitors", cmd_competitors),
        ("competitor_watch", cmd_competitor_watch),
        ("trend_watch", cmd_trend_watch),
        ("batch", cmd_batch),
        ("optimize", cmd_optimize),
        ("cluster", cmd_cluster),
        ("weekly", cmd_weekly),
    ]:
        app.add_handler(CommandHandler(cmd, handler))

    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    log.info("Telegram bridge polling...")
    app.run_polling()
