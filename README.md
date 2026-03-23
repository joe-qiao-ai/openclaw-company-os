# Company OS for OpenClaw

Turn any OpenClaw install into a fully operational AI company — with a customizable CEO agent, a structured hiring and offboarding system, a shared task board, and a talent library.

---

## What This Does

After running the installer, your OpenClaw becomes a company:

- **A CEO agent** with your chosen name and personality, who understands their role: delegate, don't execute
- **A hiring system** — the CEO checks your talent library first, recommends candidates, and only deploys after you confirm
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

The CEO follows a strict order — no shortcuts:

1. **Check the talent library first** — reads `~/talent-library/` and lists available personas
2. **Match to your request** — finds the best candidates and presents them to you
3. **You choose** — CEO deploys only after you confirm
4. **If nothing fits** — CEO tells you why and suggests downloading from [Guild](https://guild.ai) or building from scratch

The CEO will never propose creating a new agent without checking the library first.

---

## Importing Personas from Guild

Download a persona package from [Guild](https://guild.ai), then:

```bash
bash scripts/import-persona.sh /path/to/persona-folder
```

The persona will appear in your talent library, ready to be hired by your CEO.

---

## Reinstalling / Updating

The installer detects existing installations and handles them cleanly:

```bash
git pull
bash install.sh
```

- If a previous Company OS install is found, you'll be asked whether to replace it
- **Memory files are always preserved** — only identity files (SOUL.md, USER.md) are updated
- Old workspaces are cleaned up automatically

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
    ├── SOUL.md          # CEO identity and rules
    ├── HEARTBEAT.md     # What the CEO does every cycle
    ├── USER.md          # Who you are, your contact accounts
    ├── PERFORMANCE.md   # Recognition and score history
    └── company/ops/
        └── hiring-sop.md

~/company-kb/
    ├── taskboard.md     # Active tasks across all agents
    └── leaderboard.md   # Monthly agent performance ranking
```

---

## Part of the Guild Ecosystem

Company OS is the foundation layer. [Guild](https://guild.ai) is where you find, browse, and download the people.

Install Company OS → browse Guild → hire who you need.
