#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────
#  Company OS — OpenClaw Plugin Installer
#  github.com/openclaw/company-os
# ─────────────────────────────────────────────

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW="$HOME/.openclaw"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║      Company OS — OpenClaw Plugin    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Pre-flight check ─────────────────────────
if [ ! -d "$OPENCLAW" ]; then
  echo -e "${RED}✗ OpenClaw not found at $OPENCLAW${NC}"
  echo "  Please install OpenClaw first: https://openclaw.ai"
  exit 1
fi

if [ ! -f "$OPENCLAW/openclaw.json" ]; then
  echo -e "${RED}✗ openclaw.json not found. Run 'openclaw setup' first.${NC}"
  exit 1
fi

echo -e "${GREEN}✓ OpenClaw detected${NC}"
echo ""

# ── Check for existing installation ──────────
EXISTING=$(python3 -c "
import json, os
with open('$OPENCLAW/openclaw.json') as f:
    c = json.load(f)
# Detect previously installed CEO by checking for workspace-* dirs we created
plugin_agents = [a['id'] for a in c.get('agents',{}).get('list',[])
                 if a.get('workspace','').startswith('$OPENCLAW/workspace-')
                 and a.get('id') not in ('main',)]
print(','.join(plugin_agents))
" 2>/dev/null)

if [ -n "$EXISTING" ]; then
  echo -e "${YELLOW}⚠ Company OS already installed (CEO: $EXISTING)${NC}"
  read -p "Reinstall and replace existing setup? [y/N] " REINSTALL
  if [[ ! "$REINSTALL" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
  fi
  # Remove existing main agents before reinstalling
  python3 - <<PYEOF
import json
config_path = "$OPENCLAW/openclaw.json"
with open(config_path) as f:
    config = json.load(f)
config['agents']['list'] = [a for a in config.get('agents',{}).get('list',[]) if not a.get('main')]
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print("  ✓ Removed existing CEO agents")
PYEOF
  # Remove existing cron jobs for old main agents
  CRON_FILE="$OPENCLAW/cron/jobs.json"
  if [ -f "$CRON_FILE" ]; then
    IFS=',' read -ra OLD_IDS <<< "$EXISTING"
    for OLD_ID in "${OLD_IDS[@]}"; do
      python3 -c "
import json
with open('$CRON_FILE') as f: data=json.load(f)
data['jobs']=[j for j in data.get('jobs',[]) if j.get('agentId')!='$OLD_ID']
with open('$CRON_FILE','w') as f: json.dump(data,f,indent=2)
" 2>/dev/null && echo "  ✓ Removed cron job for $OLD_ID"
    done
  fi
  echo ""
fi

# ── Collect setup info ───────────────────────
echo -e "${CYAN}${BOLD}Let's set up your AI company.${NC}"
echo ""

read -p "$(echo -e "${BOLD}Your name${NC} (e.g. Alex): ")" OWNER_NAME
while [ -z "$OWNER_NAME" ]; do
  read -p "Name cannot be empty. Your name: " OWNER_NAME
done

read -p "$(echo -e "${BOLD}CEO name${NC} (e.g. Max, Nova, Atlas): ")" CEO_NAME
while [ -z "$CEO_NAME" ]; do
  read -p "CEO name cannot be empty: " CEO_NAME
done

# Capitalize first letter of each word for display, lowercase for ID
CEO_NAME=$(echo "$CEO_NAME" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
CEO_ID=$(echo "$CEO_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

echo ""
echo -e "${BOLD}CEO personality${NC} — describe your CEO in 2-3 sentences."
echo -e "${YELLOW}Tip: e.g. \"Direct and decisive. Gets to the point fast. Not afraid to push back when something doesn't make sense.\"${NC}"
read -p "> " CEO_PERSONA
[ -z "$CEO_PERSONA" ] && CEO_PERSONA="Direct, decisive, and professionally blunt. Gets to the point without wasting time. Comfortable pushing back when something doesn't add up."

read -p "$(echo -e "${BOLD}Your timezone${NC} [America/Toronto]: ")" TIMEZONE
[ -z "$TIMEZONE" ] && TIMEZONE="America/Toronto"

read -p "$(echo -e "${BOLD}Primary language${NC} [中文]: ")" LANGUAGE
[ -z "$LANGUAGE" ] && LANGUAGE="中文"

echo ""
echo -e "${BOLD}Your contact accounts${NC} — so your CEO recognizes you on any platform."
echo -e "${YELLOW}Enter your usernames/IDs, one per line. Press Enter twice when done.${NC}"
echo -e "${YELLOW}e.g. Discord: core119 / Telegram: @carol / Slack: carol.wu${NC}"
OWNER_ACCOUNTS_LIST=""
OWNER_ACCOUNTS_MD=""
while IFS= read -r line; do
  [ -z "$line" ] && break
  OWNER_ACCOUNTS_LIST="$OWNER_ACCOUNTS_LIST$line\n"
  OWNER_ACCOUNTS_MD="$OWNER_ACCOUNTS_MD- $line\n"
done
[ -z "$OWNER_ACCOUNTS_MD" ] && OWNER_ACCOUNTS_MD="- (未设置 — 建议补充 Discord/Telegram 账号)\n"
# Escape for sed
OWNER_ACCOUNTS=$(printf '%s' "$OWNER_ACCOUNTS_MD" | sed 's/[&/\]/\\&/g')

read -p "$(echo -e "${BOLD}Company knowledge base path${NC} [$HOME/company-kb]: ")" COMPANY_KB
[ -z "$COMPANY_KB" ] && COMPANY_KB="$HOME/company-kb"

read -p "$(echo -e "${BOLD}Talent library path${NC} [$HOME/talent-library]: ")" TALENT_DIR
[ -z "$TALENT_DIR" ] && TALENT_DIR="$HOME/talent-library"

INSTALL_DATE=$(date '+%Y-%m-%d')

echo ""
echo -e "${CYAN}${BOLD}── Summary ────────────────────────────${NC}"
echo -e "  Owner:        ${BOLD}$OWNER_NAME${NC}"
echo -e "  CEO:          ${BOLD}$CEO_NAME${NC} (id: $CEO_ID)"
echo -e "  Timezone:     $TIMEZONE"
echo -e "  Language:     $LANGUAGE"
echo -e "  Company KB:   $COMPANY_KB"
echo -e "  Talent dir:   $TALENT_DIR"
echo ""
read -p "Looks good? Install now? [Y/n] " CONFIRM
[[ "$CONFIRM" =~ ^[Nn] ]] && echo "Aborted." && exit 0

echo ""
echo -e "${CYAN}Installing...${NC}"

# ── Helper: replace placeholders in a file ───
apply_template() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  sed \
    -e "s|{{CEO_NAME}}|$CEO_NAME|g" \
    -e "s|{{CEO_ID}}|$CEO_ID|g" \
    -e "s|{{CEO_PERSONA}}|$CEO_PERSONA|g" \
    -e "s|{{OWNER_NAME}}|$OWNER_NAME|g" \
    -e "s|{{OWNER_ACCOUNTS}}|$OWNER_ACCOUNTS|g" \
    -e "s|{{TIMEZONE}}|$TIMEZONE|g" \
    -e "s|{{LANGUAGE}}|$LANGUAGE|g" \
    -e "s|{{COMPANY_KB}}|$COMPANY_KB|g" \
    -e "s|{{TALENT_DIR}}|$TALENT_DIR|g" \
    -e "s|{{OPENCLAW_CONFIG}}|$OPENCLAW|g" \
    -e "s|{{INSTALL_DATE}}|$INSTALL_DATE|g" \
    "$src" > "$dst"
}

# ── 1. Create CEO workspace ───────────────────
WORKSPACE="$OPENCLAW/workspace-$CEO_ID"

# Helper: patch identity in an existing file (replace name lines only)
patch_identity() {
  local file="$1"
  # Replace any line containing the old CEO name pattern or owner name pattern
  # We re-apply the full template over identity files only — memory is untouched
  apply_template "$PLUGIN_DIR/templates/workspace/$(basename "$file")" "$file"
}

if [ -d "$WORKSPACE" ]; then
  echo -e "${CYAN}  Workspace exists — updating identity files, preserving memory...${NC}"
  # Only overwrite identity files; never touch memory/ or any other files
  for f in SOUL.md HEARTBEAT.md USER.md; do
    if [ -f "$PLUGIN_DIR/templates/workspace/$f" ]; then
      apply_template "$PLUGIN_DIR/templates/workspace/$f" "$WORKSPACE/$f"
    fi
  done
  # Create PERFORMANCE.md only if it doesn't exist
  [ ! -f "$WORKSPACE/PERFORMANCE.md" ] && \
    apply_template "$PLUGIN_DIR/templates/workspace/PERFORMANCE.md" "$WORKSPACE/PERFORMANCE.md"
  # Ensure company/ops dir exists
  mkdir -p "$WORKSPACE/company/ops"
  apply_template \
    "$PLUGIN_DIR/templates/workspace/company/ops/hiring-sop.md" \
    "$WORKSPACE/company/ops/hiring-sop.md"
  echo -e "${GREEN}  ✓ Identity updated (SOUL.md, USER.md, HEARTBEAT.md)${NC}"
  echo -e "${GREEN}  ✓ Memory files untouched${NC}"
else
  mkdir -p "$WORKSPACE/memory"
  mkdir -p "$WORKSPACE/company/ops"

  for f in SOUL.md HEARTBEAT.md USER.md PERFORMANCE.md; do
    apply_template "$PLUGIN_DIR/templates/workspace/$f" "$WORKSPACE/$f"
  done

  apply_template \
    "$PLUGIN_DIR/templates/workspace/company/ops/hiring-sop.md" \
    "$WORKSPACE/company/ops/hiring-sop.md"

  echo -e "${GREEN}  ✓ CEO workspace created: $WORKSPACE${NC}"
fi

# ── 2. Create company knowledge base ─────────
mkdir -p "$COMPANY_KB"/{deliverables,docs,reports,weekly-reports}

if [ ! -f "$COMPANY_KB/taskboard.md" ]; then
  apply_template "$PLUGIN_DIR/templates/company-kb/taskboard.md" "$COMPANY_KB/taskboard.md"
  echo -e "${GREEN}  ✓ Taskboard created: $COMPANY_KB/taskboard.md${NC}"
fi

if [ ! -f "$COMPANY_KB/leaderboard.md" ]; then
  apply_template "$PLUGIN_DIR/templates/company-kb/leaderboard.md" "$COMPANY_KB/leaderboard.md"
  echo -e "${GREEN}  ✓ Leaderboard created: $COMPANY_KB/leaderboard.md${NC}"
fi

# ── 3. Create talent library ──────────────────
mkdir -p "$TALENT_DIR"
if [ ! -f "$TALENT_DIR/categories.json" ]; then
  cat > "$TALENT_DIR/categories.json" << EOF
{
  "categories": [
    { "id": "business",   "label": "Business & Investment", "color": "blue"   },
    { "id": "tech",       "label": "Tech & Engineering",    "color": "purple" },
    { "id": "career",     "label": "Functional Roles",      "color": "green"  },
    { "id": "creative",   "label": "Creative & Content",    "color": "pink"   },
    { "id": "education",  "label": "Education & Coaching",  "color": "yellow" },
    { "id": "lifestyle",  "label": "Lifestyle & Wellness",  "color": "teal"   },
    { "id": "uncategorized", "label": "Uncategorized",      "color": "gray"   }
  ],
  "personas": {}
}
EOF
  echo -e "${GREEN}  ✓ Talent library initialized: $TALENT_DIR${NC}"
fi

# ── 4. Add CEO to agents.list ─────────────────
AGENTS_FILE="$OPENCLAW/agents/list.json"
[ ! -f "$AGENTS_FILE" ] && AGENTS_FILE="$OPENCLAW/openclaw.json"

# Use Python to safely add agent entry to openclaw.json
python3 - <<PYEOF
import json, sys, os

config_path = "$OPENCLAW/openclaw.json"
with open(config_path, 'r') as f:
    config = json.load(f)

agents = config.get('agents', {}).get('list', [])
existing_ids = [a.get('id') for a in agents]

if '$CEO_ID' in existing_ids:
    print("  ⚠ Agent '$CEO_ID' already in agents.list — skipping")
else:
    agents.append({
        "id": "$CEO_ID",
        "workspace": "$WORKSPACE"
    })
    config['agents']['list'] = agents
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print("  ✓ CEO added to agents.list")
PYEOF

# ── 5. Add CEO cron heartbeat ─────────────────
CRON_FILE="$OPENCLAW/cron/jobs.json"
if [ -f "$CRON_FILE" ]; then
  python3 - <<PYEOF
import json, uuid

cron_path = "$CRON_FILE"
with open(cron_path, 'r') as f:
    data = json.load(f)

jobs = data.get('jobs', [])
existing = [j.get('agentId') for j in jobs]

if '$CEO_ID' in existing:
    print("  ⚠ Cron job for '$CEO_ID' already exists — skipping")
else:
    # Try to find the main agent's sessionKey to reuse
    main_session = None
    for j in jobs:
        if j.get('agentId') == 'main' and j.get('sessionKey'):
            main_session = j['sessionKey']
            break

    job = {
        "id": str(uuid.uuid4()),
        "agentId": "$CEO_ID",
        "enabled": True if main_session else False,
        "everyMs": 900000,
        "workspace": "$WORKSPACE"
    }
    if main_session:
        job["sessionKey"] = main_session

    jobs.append(job)
    data['jobs'] = jobs
    with open(cron_path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    if main_session:
        print("  ✓ Cron heartbeat created (every 15min)")
    else:
        print("  ✓ Cron job created (disabled — set sessionKey to activate)")
PYEOF
else
  echo -e "${YELLOW}  ⚠ No cron/jobs.json found — skipping heartbeat setup${NC}"
fi

# ── 6. Bind CEO to configured channels ───────
python3 - <<PYEOF
import json

config_path = "$OPENCLAW/openclaw.json"
with open(config_path, 'r') as f:
    config = json.load(f)

channels = config.get('channels', {})
bindings = config.get('bindings', [])
added = []

def already_bound(agent_id, channel, account_id):
    return any(
        b.get('agentId') == agent_id and
        b.get('match', {}).get('channel') == channel and
        b.get('match', {}).get('accountId') == account_id
        for b in bindings
    )

# Bind Telegram accounts
for account_id in channels.get('telegram', {}).get('accounts', {}):
    if not already_bound('$CEO_ID', 'telegram', account_id):
        bindings.append({
            "agentId": "$CEO_ID",
            "match": { "channel": "telegram", "accountId": account_id }
        })
        added.append(f"telegram:{account_id}")

# Bind Discord if configured
discord_cfg = channels.get('discord', {})
if discord_cfg.get('enabled') or discord_cfg.get('token'):
    if not already_bound('$CEO_ID', 'discord', 'default'):
        bindings.append({
            "agentId": "$CEO_ID",
            "match": { "channel": "discord", "accountId": "default" }
        })
        added.append("discord:default")

config['bindings'] = bindings
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

if added:
    print(f"  ✓ CEO bound to: {', '.join(added)}")
else:
    print("  ✓ Channel bindings already up to date")
PYEOF

# ── 7. Enable agentToAgent messaging ─────────
python3 - <<PYEOF
import json

config_path = "$OPENCLAW/openclaw.json"
with open(config_path, 'r') as f:
    config = json.load(f)

tools = config.setdefault('tools', {})
tools.setdefault('sessions', {})['visibility'] = 'all'
tools.setdefault('agentToAgent', {})['enabled'] = True

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print("  ✓ Agent-to-agent messaging enabled")
PYEOF

# ── Done ──────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║        Installation Complete! 🎉     ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  CEO ${BOLD}$CEO_NAME${NC} is ready."
echo -e "  Company KB: ${BOLD}$COMPANY_KB${NC}"
echo -e "  Talent library: ${BOLD}$TALENT_DIR${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Next steps:${NC}"
echo -e "  1. ${BOLD}Activate heartbeat:${NC} set sessionKey in cron/jobs.json"
echo -e "     (or run 'openclaw setup' to configure Telegram)"
echo -e "  2. ${BOLD}Import talent:${NC} bash scripts/import-persona.sh /path/to/persona"
echo -e "  3. ${BOLD}Start your company:${NC} send your CEO a task via Telegram"
echo ""
