#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  Company OS — OpenClaw Plugin Installer
#  github.com/openclaw/company-os
# ─────────────────────────────────────────────

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW="$HOME/.openclaw"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║      Company OS — OpenClaw Plugin    ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ── Pre-flight ────────────────────────────────
[ ! -d "$OPENCLAW" ] && echo -e "${RED}✗ OpenClaw not found. Install OpenClaw first.${NC}" && exit 1
[ ! -f "$OPENCLAW/openclaw.json" ] && echo -e "${RED}✗ openclaw.json missing. Run 'openclaw setup' first.${NC}" && exit 1
echo -e "${GREEN}✓ OpenClaw detected${NC}"
echo ""

# ── Detect existing install ───────────────────
EXISTING_IDS=$(python3 -c "
import json, os
with open('$OPENCLAW/openclaw.json') as f:
    c = json.load(f)
ids = [a['id'] for a in c.get('agents',{}).get('list',[])
       if a.get('workspace','').startswith('$OPENCLAW/workspace-')
       and a.get('id') != 'main']
print(','.join(ids))
" 2>/dev/null || echo "")

if [ -n "$EXISTING_IDS" ]; then
  echo -e "${YELLOW}⚠ Existing Company OS install detected (CEO: $EXISTING_IDS)${NC}"
  read -p "Reinstall? This will replace the existing CEO setup. [y/N] " REINSTALL
  [[ ! "$REINSTALL" =~ ^[Yy] ]] && echo "Aborted." && exit 0

  # Remove old workspaces, agents, bindings, cron
  IFS=',' read -ra OLD_IDS <<< "$EXISTING_IDS"
  for OLD_ID in "${OLD_IDS[@]}"; do
    OLD_WS="$OPENCLAW/workspace-$OLD_ID"
    if [ -d "$OLD_WS" ]; then
      read -p "  Delete old workspace '$OLD_ID' (memories will be lost)? [y/N] " DEL_WS
      [[ "$DEL_WS" =~ ^[Yy] ]] && rm -rf "$OLD_WS" && echo -e "  ${GREEN}✓ Deleted $OLD_WS${NC}"
    fi
  done

  OLD_IDS_JSON=$(python3 -c "import json; print(json.dumps('$EXISTING_IDS'.split(',')))")
  python3 - "$OPENCLAW/openclaw.json" "$OPENCLAW/cron/jobs.json" "$OLD_IDS_JSON" << 'PYEOF'
import json, sys, os

config_path, cron_path, old_ids_json = sys.argv[1], sys.argv[2], sys.argv[3]
old_ids = set(json.loads(old_ids_json))

with open(config_path) as f:
    config = json.load(f)

before = len(config['agents']['list'])
config['agents']['list'] = [a for a in config['agents']['list'] if a.get('id') not in old_ids]
config['bindings'] = [b for b in config.get('bindings', []) if b.get('agentId') not in old_ids]
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print(f"  \u2713 Removed {before - len(config['agents']['list'])} agent(s) and their bindings")

if os.path.exists(cron_path):
    with open(cron_path) as f:
        cron = json.load(f)
    removed = [j['agentId'] for j in cron.get('jobs', []) if j.get('agentId') in old_ids]
    cron['jobs'] = [j for j in cron['jobs'] if j.get('agentId') not in old_ids]
    with open(cron_path, 'w') as f:
        json.dump(cron, f, indent=2, ensure_ascii=False)
    for r in removed:
        print(f"  \u2713 Removed cron job: {r}")
PYEOF
  echo ""
fi

# ── Collect setup info ────────────────────────
echo -e "${CYAN}${BOLD}Let's set up your AI company.${NC}"
echo ""

read -p "$(echo -e "${BOLD}Your name${NC} (e.g. Alex): ")" OWNER_NAME
while [ -z "$OWNER_NAME" ]; do read -p "Cannot be empty: " OWNER_NAME; done

read -p "$(echo -e "${BOLD}CEO name${NC} (e.g. Max, Nova, Atlas): ")" CEO_NAME
while [ -z "$CEO_NAME" ]; do read -p "Cannot be empty: " CEO_NAME; done
CEO_NAME=$(echo "$CEO_NAME" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
CEO_ID=$(echo "$CEO_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

echo ""
echo -e "${BOLD}CEO personality${NC} — 2-3 sentences describing how your CEO thinks and communicates."
echo -e "${YELLOW}e.g. \"Direct and decisive. Pushes back when something doesn't make sense. No fluff.\"${NC}"
read -p "> " CEO_PERSONA
[ -z "$CEO_PERSONA" ] && CEO_PERSONA="Direct, decisive, and professionally blunt. Gets to the point without wasting time. Comfortable pushing back when something doesn't add up."

read -p "$(echo -e "${BOLD}Your timezone${NC} [America/Toronto]: ")" TIMEZONE
[ -z "$TIMEZONE" ] && TIMEZONE="America/Toronto"

read -p "$(echo -e "${BOLD}Primary language${NC} [中文]: ")" LANGUAGE
[ -z "$LANGUAGE" ] && LANGUAGE="中文"

echo ""
echo -e "${BOLD}Your contact accounts${NC} — CEO will recognize you on any platform."
echo -e "${YELLOW}One per line (e.g. \"Discord: core119\"). Empty line to finish.${NC}"
OWNER_ACCOUNTS_LINES=()
while IFS= read -r line; do
  [ -z "$line" ] && break
  OWNER_ACCOUNTS_LINES+=("$line")
done
[ ${#OWNER_ACCOUNTS_LINES[@]} -eq 0 ] && OWNER_ACCOUNTS_LINES=("(not set — add your Discord/Telegram ID here)")

read -p "$(echo -e "${BOLD}Company knowledge base path${NC} [$HOME/company-kb]: ")" COMPANY_KB
[ -z "$COMPANY_KB" ] && COMPANY_KB="$HOME/company-kb"

read -p "$(echo -e "${BOLD}Talent library path${NC} [$HOME/talent-library]: ")" TALENT_DIR
[ -z "$TALENT_DIR" ] && TALENT_DIR="$HOME/talent-library"

INSTALL_DATE=$(date '+%Y-%m-%d')
WORKSPACE="$OPENCLAW/workspace-$CEO_ID"

echo ""
echo -e "${CYAN}${BOLD}── Summary ────────────────────────────${NC}"
echo -e "  Owner:    ${BOLD}$OWNER_NAME${NC}"
echo -e "  CEO:      ${BOLD}$CEO_NAME${NC}  (id: $CEO_ID)"
echo -e "  Timezone: $TIMEZONE  |  Language: $LANGUAGE"
echo -e "  Accounts: ${OWNER_ACCOUNTS_LINES[*]}"
echo -e "  KB:       $COMPANY_KB"
echo -e "  Talent:   $TALENT_DIR"
echo ""
read -p "Looks good? [Y/n] " CONFIRM
[[ "$CONFIRM" =~ ^[Nn] ]] && echo "Aborted." && exit 0

echo ""
echo -e "${CYAN}Installing...${NC}"

# ── All file generation via Python (no encoding issues) ──
# Export all vars for the Python script
export _OWNER_NAME="$OWNER_NAME"
export _CEO_NAME="$CEO_NAME"
export _CEO_ID="$CEO_ID"
export _CEO_PERSONA="$CEO_PERSONA"
export _TIMEZONE="$TIMEZONE"
export _LANGUAGE="$LANGUAGE"
export _COMPANY_KB="$COMPANY_KB"
export _TALENT_DIR="$TALENT_DIR"
export _INSTALL_DATE="$INSTALL_DATE"
export _WORKSPACE="$WORKSPACE"
export _OPENCLAW="$OPENCLAW"
export _PLUGIN_DIR="$PLUGIN_DIR"
# Accounts as JSON array
_ACCOUNTS_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${OWNER_ACCOUNTS_LINES[@]}")
export _ACCOUNTS_JSON

python3 << 'PYEOF'
# -*- coding: utf-8 -*-
import os, json, uuid, shutil

def e(key): return os.environ[key]

owner     = e('_OWNER_NAME')
ceo_name  = e('_CEO_NAME')
ceo_id    = e('_CEO_ID')
persona   = e('_CEO_PERSONA')
timezone  = e('_TIMEZONE')
language  = e('_LANGUAGE')
company_kb= e('_COMPANY_KB')
talent_dir= e('_TALENT_DIR')
install_date = e('_INSTALL_DATE')
workspace = e('_WORKSPACE')
openclaw  = e('_OPENCLAW')
plugin_dir= e('_PLUGIN_DIR')
accounts  = json.loads(e('_ACCOUNTS_JSON'))

subs = {
    '{{CEO_NAME}}':        ceo_name,
    '{{CEO_ID}}':          ceo_id,
    '{{CEO_PERSONA}}':     persona,
    '{{OWNER_NAME}}':      owner,
    '{{TIMEZONE}}':        timezone,
    '{{LANGUAGE}}':        language,
    '{{COMPANY_KB}}':      company_kb,
    '{{TALENT_DIR}}':      talent_dir,
    '{{OPENCLAW_CONFIG}}': openclaw,
    '{{INSTALL_DATE}}':    install_date,
}

def apply(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(src, 'r', encoding='utf-8') as f:
        content = f.read()
    for k, v in subs.items():
        content = content.replace(k, v)
    with open(dst, 'w', encoding='utf-8') as f:
        f.write(content)

# ── 1. Workspace ────────────────────────────
os.makedirs(os.path.join(workspace, 'memory'), exist_ok=True)
os.makedirs(os.path.join(workspace, 'company', 'ops'), exist_ok=True)

tpl = os.path.join(plugin_dir, 'templates', 'workspace')
for fname in ['SOUL.md', 'HEARTBEAT.md', 'PERFORMANCE.md']:
    apply(os.path.join(tpl, fname), os.path.join(workspace, fname))
apply(os.path.join(tpl, 'company', 'ops', 'hiring-sop.md'),
      os.path.join(workspace, 'company', 'ops', 'hiring-sop.md'))

# USER.md — built from template with multiline accounts
accounts_md = '\n'.join(f'- {a}' for a in accounts)
with open(os.path.join(tpl, 'USER.md'), 'r', encoding='utf-8') as f:
    user_content = f.read()
for k, v in {**subs, '{{OWNER_ACCOUNTS}}': accounts_md}.items():
    user_content = user_content.replace(k, v)
with open(os.path.join(workspace, 'USER.md'), 'w', encoding='utf-8') as f:
    f.write(user_content)

print(f"  \u2713 Workspace ready: {workspace}")

# ── 2. Company KB ───────────────────────────
for sub in ['deliverables', 'docs', 'reports', 'weekly-reports']:
    os.makedirs(os.path.join(company_kb, sub), exist_ok=True)

kb_tpl = os.path.join(plugin_dir, 'templates', 'company-kb')
for fname in ['taskboard.md', 'leaderboard.md']:
    dst = os.path.join(company_kb, fname)
    if not os.path.exists(dst):
        apply(os.path.join(kb_tpl, fname), dst)
        print(f"  \u2713 Created {dst}")

# ── 3. Talent library ───────────────────────
os.makedirs(talent_dir, exist_ok=True)
cat_path = os.path.join(talent_dir, 'categories.json')
if not os.path.exists(cat_path):
    cats = {"categories": [
        {"id": "business",      "label": "Business & Investment", "color": "blue"},
        {"id": "tech",          "label": "Tech & Engineering",    "color": "purple"},
        {"id": "career",        "label": "Functional Roles",      "color": "green"},
        {"id": "creative",      "label": "Creative & Content",    "color": "pink"},
        {"id": "education",     "label": "Education & Coaching",  "color": "yellow"},
        {"id": "lifestyle",     "label": "Lifestyle & Wellness",  "color": "teal"},
        {"id": "uncategorized", "label": "Uncategorized",         "color": "gray"},
    ], "personas": {}}
    with open(cat_path, 'w', encoding='utf-8') as f:
        json.dump(cats, f, indent=2, ensure_ascii=False)
    print(f"  \u2713 Talent library initialized: {talent_dir}")

# ── 4. agents.list ──────────────────────────
config_path = os.path.join(openclaw, 'openclaw.json')
with open(config_path) as f:
    config = json.load(f)

agents = config.setdefault('agents', {}).setdefault('list', [])
if not any(a.get('id') == ceo_id for a in agents):
    agents.append({"id": ceo_id, "workspace": workspace})
    print(f"  \u2713 CEO added to agents.list")

# ── 5. Cron heartbeat ───────────────────────
cron_path = os.path.join(openclaw, 'cron', 'jobs.json')
if os.path.exists(cron_path):
    with open(cron_path) as f:
        cron = json.load(f)
    jobs = cron.setdefault('jobs', [])
    if not any(j.get('agentId') == ceo_id for j in jobs):
        # Try to reuse any existing sessionKey
        session_key = next((j['sessionKey'] for j in jobs if j.get('sessionKey')), None)
        job = {"id": str(uuid.uuid4()), "agentId": ceo_id,
               "enabled": True, "everyMs": 300000, "workspace": workspace}
        if session_key:
            job["sessionKey"] = session_key
        jobs.append(job)
        with open(cron_path, 'w') as f:
            json.dump(cron, f, indent=2, ensure_ascii=False)
        status = "every 15min" if session_key else "disabled — needs sessionKey"
        print(f"  \u2713 Cron heartbeat added ({status})")

# ── 6. Channel bindings ─────────────────────
bindings = config.setdefault('bindings', [])

def bound(channel, account_id):
    return any(b.get('agentId') == ceo_id and
               b.get('match', {}).get('channel') == channel and
               b.get('match', {}).get('accountId') == account_id
               for b in bindings)

added = []
for acct_id in config.get('channels', {}).get('telegram', {}).get('accounts', {}):
    if not bound('telegram', acct_id):
        bindings.append({"agentId": ceo_id, "match": {"channel": "telegram", "accountId": acct_id}})
        added.append(f"telegram:{acct_id}")

discord = config.get('channels', {}).get('discord', {})
if discord.get('enabled') or discord.get('token'):
    if not bound('discord', 'default'):
        bindings.append({"agentId": ceo_id, "match": {"channel": "discord", "accountId": "default"}})
        added.append("discord:default")

if added:
    print(f"  \u2713 Bound to: {', '.join(added)}")

# ── 7. agentToAgent messaging ───────────────
tools = config.setdefault('tools', {})
tools.setdefault('sessions', {})['visibility'] = 'all'
tools.setdefault('agentToAgent', {})['enabled'] = True
print("  \u2713 Agent-to-agent messaging enabled")

# ── Save config ─────────────────────────────
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print("  \u2713 Config saved")
PYEOF

# ── Done ──────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║      Installation Complete! 🎉       ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  CEO:     ${BOLD}$CEO_NAME${NC}"
echo -e "  Owner:   ${BOLD}$OWNER_NAME${NC}"
echo -e "  KB:      ${BOLD}$COMPANY_KB${NC}"
echo -e "  Talent:  ${BOLD}$TALENT_DIR${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Next: restart OpenClaw to apply changes.${NC}"
echo ""
