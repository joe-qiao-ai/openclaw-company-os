#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  Company OS — Uninstall
#  Removes CEO agent and config. Does NOT delete
#  company-kb or talent library (data is yours).
# ─────────────────────────────────────────────
set -e

OPENCLAW="$HOME/.openclaw"
RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo ""
echo -e "${RED}${BOLD}Company OS Uninstall${NC}"
echo -e "${YELLOW}This will remove the CEO agent from OpenClaw.${NC}"
echo -e "Your company-kb and talent library will NOT be deleted."
echo ""

# Detect CEO ID
CEO_ID=$(python3 -c "
import json
with open('$OPENCLAW/openclaw.json') as f:
    c = json.load(f)
agents = c.get('agents', {}).get('list', [])
mains = [a['id'] for a in agents if a.get('main')]
print(mains[0] if mains else '')
" 2>/dev/null)

if [ -z "$CEO_ID" ]; then
  echo "No Company OS CEO agent found. Nothing to remove."
  exit 0
fi

echo -e "CEO to remove: ${BOLD}$CEO_ID${NC}"
read -p "Confirm uninstall? [y/N] " CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy] ]] && echo "Aborted." && exit 0

python3 - <<PYEOF
import json

config_path = "$OPENCLAW/openclaw.json"
with open(config_path) as f:
    config = json.load(f)

# Remove from agents.list
agents = config.get('agents', {}).get('list', [])
config['agents']['list'] = [a for a in agents if a.get('id') != '$CEO_ID']

with open(config_path, 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
print("✓ Removed from agents.list")
PYEOF

CRON_FILE="$OPENCLAW/cron/jobs.json"
if [ -f "$CRON_FILE" ]; then
  python3 - <<PYEOF
import json
with open("$CRON_FILE") as f:
    data = json.load(f)
data['jobs'] = [j for j in data.get('jobs', []) if j.get('agentId') != '$CEO_ID']
with open("$CRON_FILE", 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print("✓ Removed cron job")
PYEOF
fi

echo ""
echo "Uninstall complete. Workspace at $OPENCLAW/workspace-$CEO_ID preserved."
