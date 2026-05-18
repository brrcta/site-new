# Task: Separate Telegram Bot into Standalone Repo

## Goal
Move the Telegram bot out of this project repo into its own standalone repo
so it is project-agnostic and can serve multiple projects (one group per project,
bot routes by chat_id).

## Context
The bot currently lives inside this repo's infra. It needs to:
- Be extracted into a new standalone repo (e.g. `tg-bot`)
- Support multiple Telegram groups — one group per project
- Route messages by `chat_id` to the correct project handler
- Run as a single systemd service on the VPS regardless of how many projects are added

## Target repo structure

```
tg-bot/
├── bot.py            ← main entry, polling loop
├── config.py         ← PROJECTS map: chat_id → project name
├── handlers/
│   ├── __init__.py
│   ├── affops.py     ← handler for affops group
│   └── sitenew.py    ← handler for site-new group (stub for now)
├── requirements.txt
└── telegram-bridge.service
```

## Step 1 — Find the current bot files in this repo

Locate all bot-related files:
```bash
find . -name "bot.py" -o -name "telegram-bridge.service" -o -name "requirements.txt" | grep -v node_modules
```

## Step 2 — Create the new repo on GitHub

Create a new GitHub repo named `tg-bot` (or equivalent) under the same account.
Keep it private.

## Step 3 — Build the new repo structure

Create `config.py` with the PROJECTS routing map:

```python
# Map Telegram chat_id (negative int) to project name.
# Add one line per project group. Get chat_id via:
#   https://api.telegram.org/bot<TOKEN>/getUpdates
PROJECTS = {
    -1001234567890: "affops",    # replace with real chat_id
    -1009876543210: "sitenew",   # replace with real chat_id
}
```

Create `handlers/affops.py` — move existing bot logic here:

```python
def handle(update, bot):
    # existing affops handler logic goes here
    pass
```

Create `handlers/sitenew.py` — stub for now:

```python
def handle(update, bot):
    # site-new project handler — extend as needed
    pass
```

Rewrite `bot.py` to route by chat_id:

```python
import config
import handlers.affops as affops
import handlers.sitenew as sitenew

HANDLERS = {
    "affops":   affops.handle,
    "sitenew":  sitenew.handle,
}

def dispatch(update, bot):
    chat_id = update["message"]["chat"]["id"]
    project = config.PROJECTS.get(chat_id)
    if project is None:
        return  # unknown group — ignore silently
    handler = HANDLERS.get(project)
    if handler:
        handler(update, bot)

# wire dispatch into your existing polling loop
```

Update `telegram-bridge.service` — change ExecStart path to new location:

```ini
[Service]
ExecStart=/usr/bin/python3 /home/<user>/tg-bot/bot.py
WorkingDirectory=/home/<user>/tg-bot
```

## Step 4 — Get chat_ids for each group

For each Telegram group (affops-alerts, sitenew-alerts):
1. Add the bot to the group
2. Send any message in the group
3. Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. Find `chat.id` (negative integer) for that group
5. Add to `config.py` PROJECTS map

## Step 5 — Deploy on VPS

```bash
# clone new repo
git clone git@github.com:<user>/tg-bot.git ~/tg-bot
cd ~/tg-bot
pip install -r requirements.txt

# install and start service
sudo cp telegram-bridge.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable telegram-bridge
sudo systemctl restart telegram-bridge

# verify
sudo systemctl status telegram-bridge
```

## Step 6 — Remove bot files from this repo

```bash
git rm infra/telegram-bot/bot.py
git rm infra/telegram-bot/requirements.txt
git rm infra/telegram-bot/telegram-bridge.service
git commit -m "Remove bot files — moved to standalone tg-bot repo"
git push
```

## Step 7 — Verify

Send a test message in each Telegram group.
Confirm:
- affops group triggers affops handler
- sitenew group triggers sitenew handler  
- A message in an unregistered group is silently ignored

## Adding future projects (maintenance rule)

1. Create Telegram group, add bot, get `chat_id`
2. Add one line to `config.py` PROJECTS map
3. Create `handlers/<projectname>.py`
4. Add entry to HANDLERS dict in `bot.py`
5. `git push` → `git pull` on VPS → `sudo systemctl restart telegram-bridge`
