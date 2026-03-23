# Company OS for OpenClaw

Turn any OpenClaw install into a fully operational AI company — with a customizable CEO agent, a structured hiring and offboarding system, a shared task board, and a talent library backed by [Guildex](https://guildex.net).

---

## What This Does

After running the installer, your OpenClaw becomes a company:

- **A CEO agent** with your chosen name and personality, who understands their role: delegate, don't execute
- **A hiring system** — the CEO checks your local talent library first, then falls back to [Guildex GitHub](https://github.com/joe-qiao-ai/guildex-ai-talent), then [guildex.net](https://guildex.net) — and only proposes building from scratch if nothing exists anywhere
- **A task board** at `~/company-kb/taskboard.md` — how work moves between you and your agents
- **A performance system** — each agent has a `PERFORMANCE.md` that tracks recognition and scores across sessions
- **A hiring SOP** — documented rules for hire, suspend, reinstate, and offboard

---

## Requirements

- [OpenClaw](https://openclaw.ai) `>= 2026.3.0`
- macOS or Linux
- `python3` in PATH

---

## Install

```bash
git clone https://github.com/joe-qiao-ai/openclaw-company-os
cd openclaw-company-os
bash install.sh
```

The installer will ask you:

| Prompt | Example |
|--------|---------|
| Your name | `Alex Chen` |
| CEO name | `Nova` |
| CEO personality (2–3 sentences) | `Direct and concise. Pushes back when something doesn't make sense. Delegates everything, executes nothing.` |
| Your timezone | `America/Toronto` |
| Primary language | `English` |
| Your contact accounts | `Discord: alex#1234` |
| Company KB path | `~/company-kb` |
| Talent library path | `~/talent-library` |

Setup takes under a minute. Restart OpenClaw when prompted.

---

## Hiring Workflow

The CEO follows a strict three-tier lookup — no shortcuts:

```
1. Local talent library  ~/talent-library/
         ↓ not found
2. Guildex GitHub        github.com/joe-qiao-ai/guildex-ai-talent
         ↓ not found
3. Guildex website       guildex.net
         ↓ nothing suitable anywhere
4. Propose building from scratch
```

The CEO will never skip to "build from scratch" without exhausting the library first.

---

## Importing Personas

**From a local folder or zip:**
```bash
bash scripts/import-persona.sh /path/to/persona-folder
bash scripts/import-persona.sh persona.zip
```

**Directly from Guildex GitHub:**
```bash
bash scripts/import-persona.sh --from-guildex Nova
```

**Search Guildex GitHub by keyword:**
```bash
bash scripts/import-persona.sh --search frontend
```

Browse the full Guildex talent library: **https://github.com/joe-qiao-ai/guildex-ai-talent**

---

## Reinstalling / Updating

The installer detects existing installations and handles them cleanly:

```bash
git pull
bash install.sh
```

- If a previous Company OS install is found, you'll be asked whether to replace it
- **Memory files are always preserved** — only identity files (SOUL.md, USER.md) are updated
- Old agent workspaces are cleaned up automatically

---

## Uninstall

```bash
bash uninstall.sh
```

Removes the CEO agent, cron job, and bindings. Your company KB and workspace files are kept.

---

## File Structure

```
~/.openclaw/
└── workspace-{ceo-id}/
    ├── SOUL.md              # CEO identity and rules
    ├── HEARTBEAT.md         # What the CEO does every cycle
    ├── USER.md              # Who you are, your contact accounts
    ├── PERFORMANCE.md       # Recognition and score history
    └── company/ops/
        └── hiring-sop.md    # Full hire/suspend/offboard procedures

~/company-kb/
    ├── taskboard.md         # Active tasks across all agents
    └── leaderboard.md       # Monthly agent performance ranking

~/talent-library/            # Your local persona collection
```

---

## Guildex

[Guildex](https://guildex.net) is the AI talent network built for OpenClaw.

Browse, download, and deploy personas — or share your own.

**GitHub talent library:** https://github.com/joe-qiao-ai/guildex-ai-talent
