#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  Company OS — Staff Management
#  Usage:
#    bash scripts/staff.sh hire <persona-name>
#    bash scripts/staff.sh suspend <agent-id>
#    bash scripts/staff.sh reinstate <agent-id>
#    bash scripts/staff.sh offboard <agent-id>
#    bash scripts/staff.sh list
# ─────────────────────────────────────────────
set -e

OPENCLAW="$HOME/.openclaw"
TALENT_DIR=$(python3 -c "
import json, os
try:
    with open('$OPENCLAW/openclaw.json') as f:
        c = json.load(f)
    print(c.get('plugins', {}).get('company-os', {}).get('talentDir', os.path.expanduser('~/talent-library')))
except:
    print(os.path.expanduser('~/talent-library'))
" 2>/dev/null || echo "$HOME/talent-library")

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; CYAN='\033[0;36m'; NC='\033[0m'

ACTION="$1"
TARGET="$2"

if [ -z "$ACTION" ]; then
  echo -e "${BOLD}Company OS — Staff Manager${NC}"
  echo ""
  echo "Usage:"
  echo "  bash scripts/staff.sh list                    List all staff"
  echo "  bash scripts/staff.sh hire <persona-name>     Deploy from talent library"
  echo "  bash scripts/staff.sh suspend <agent-id>      Suspend (pause heartbeat)"
  echo "  bash scripts/staff.sh reinstate <agent-id>    Reinstate suspended agent"
  echo "  bash scripts/staff.sh offboard <agent-id>     Offboard (remove agent)"
  exit 0
fi

# ── LIST ─────────────────────────────────────
if [ "$ACTION" = "list" ]; then
  python3 - <<PYEOF
import json, os

OPENCLAW = os.path.expanduser("~/.openclaw")

with open(f"{OPENCLAW}/openclaw.json") as f:
    config = json.load(f)

with open(f"{OPENCLAW}/cron/jobs.json") as f:
    cron = json.load(f)

cron_map = {j["agentId"]: j for j in cron.get("jobs", [])}
agents = config.get("agents", {}).get("list", [])

if not agents:
    print("No staff deployed.")
else:
    print(f"{'ID':<30} {'STATUS':<12} {'WORKSPACE'}")
    print("-" * 80)
    for a in agents:
        aid = a.get("id", "")
        job = cron_map.get(aid, {})
        enabled = job.get("enabled", False)
        status = "✅ Active" if enabled else "⏸  Suspended"
        ws = a.get("workspace", "")
        print(f"{aid:<30} {status:<12} {ws}")
PYEOF
  exit 0
fi

# ── Require TARGET for all other actions ──────
if [ -z "$TARGET" ]; then
  echo -e "${RED}Usage: bash scripts/staff.sh $ACTION <name>${NC}"
  exit 1
fi

# ── HIRE ─────────────────────────────────────
if [ "$ACTION" = "hire" ]; then
  python3 - <<PYEOF
import json, os, shutil, uuid

OPENCLAW = os.path.expanduser("~/.openclaw")
TALENT_DIR = "$TALENT_DIR"
PERSONA_NAME = "$TARGET"
agent_id = PERSONA_NAME.lower().replace(" ", "-")
workspace = f"{OPENCLAW}/workspace-{agent_id}"

# Check talent library
src = f"{TALENT_DIR}/{PERSONA_NAME}"
if not os.path.isdir(src):
    print(f"✗ '{PERSONA_NAME}' not found in talent library ({TALENT_DIR})")
    print(f"  Run: bash scripts/import-persona.sh --from-guildex {PERSONA_NAME}")
    exit(1)

# Read config
with open(f"{OPENCLAW}/openclaw.json") as f:
    config = json.load(f)

agents = config.setdefault("agents", {}).setdefault("list", [])
if any(a["id"] == agent_id for a in agents):
    print(f"⚠ Agent '{agent_id}' is already deployed.")
    exit(0)

# Create workspace
os.makedirs(workspace, exist_ok=True)
os.makedirs(f"{workspace}/memory", exist_ok=True)

for fname in os.listdir(src):
    shutil.copy2(f"{src}/{fname}", f"{workspace}/{fname}")

# Add to agents.list
agents.append({"id": agent_id, "workspace": workspace})

with open(f"{OPENCLAW}/openclaw.json", "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

# Add to cron
cron_path = f"{OPENCLAW}/cron/jobs.json"
with open(cron_path) as f:
    cron = json.load(f)

if not any(j["agentId"] == agent_id for j in cron.get("jobs", [])):
    # Reuse main session key if available
    session_key = next((j.get("sessionKey","") for j in cron.get("jobs",[]) if j.get("sessionKey")), "")
    cron.setdefault("jobs", []).append({
        "id": str(uuid.uuid4()),
        "agentId": agent_id,
        "workspace": workspace,
        "everyMs": 900000,
        "enabled": True,
        "sessionKey": session_key
    })
    with open(cron_path, "w") as f:
        json.dump(cron, f, indent=2, ensure_ascii=False)

print(f"✓ Hired: {PERSONA_NAME}")
print(f"  Workspace: {workspace}")
print(f"  Heartbeat: every 15 min")
print(f"  Restart OpenClaw to activate.")
PYEOF
  exit 0
fi

# ── SUSPEND ───────────────────────────────────
if [ "$ACTION" = "suspend" ]; then
  python3 - <<PYEOF
import json, os

OPENCLAW = os.path.expanduser("~/.openclaw")
agent_id = "$TARGET"

cron_path = f"{OPENCLAW}/cron/jobs.json"
with open(cron_path) as f:
    cron = json.load(f)

found = False
for j in cron.get("jobs", []):
    if j.get("agentId") == agent_id:
        j["enabled"] = False
        found = True

if not found:
    print(f"✗ Agent '{agent_id}' not found in cron jobs.")
    exit(1)

with open(cron_path, "w") as f:
    json.dump(cron, f, indent=2, ensure_ascii=False)

print(f"⏸  Suspended: {agent_id}")
print(f"  Heartbeat paused. Workspace preserved.")
PYEOF
  exit 0
fi

# ── REINSTATE ─────────────────────────────────
if [ "$ACTION" = "reinstate" ]; then
  python3 - <<PYEOF
import json, os

OPENCLAW = os.path.expanduser("~/.openclaw")
agent_id = "$TARGET"

cron_path = f"{OPENCLAW}/cron/jobs.json"
with open(cron_path) as f:
    cron = json.load(f)

found = False
for j in cron.get("jobs", []):
    if j.get("agentId") == agent_id:
        j["enabled"] = True
        found = True

if not found:
    print(f"✗ Agent '{agent_id}' not found.")
    exit(1)

with open(cron_path, "w") as f:
    json.dump(cron, f, indent=2, ensure_ascii=False)

print(f"✅ Reinstated: {agent_id}")
print(f"  Heartbeat resumed. Active on next cycle.")
PYEOF
  exit 0
fi

# ── OFFBOARD ──────────────────────────────────
if [ "$ACTION" = "offboard" ]; then
  python3 - <<PYEOF
import json, os

OPENCLAW = os.path.expanduser("~/.openclaw")
agent_id = "$TARGET"

# Remove from agents.list
with open(f"{OPENCLAW}/openclaw.json") as f:
    config = json.load(f)

before = len(config.get("agents", {}).get("list", []))
config["agents"]["list"] = [
    a for a in config.get("agents", {}).get("list", [])
    if a.get("id") != agent_id
]
removed_agent = before > len(config["agents"]["list"])

with open(f"{OPENCLAW}/openclaw.json", "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)

# Remove from cron
cron_path = f"{OPENCLAW}/cron/jobs.json"
with open(cron_path) as f:
    cron = json.load(f)

before_cron = len(cron.get("jobs", []))
cron["jobs"] = [j for j in cron.get("jobs", []) if j.get("agentId") != agent_id]

with open(cron_path, "w") as f:
    json.dump(cron, f, indent=2, ensure_ascii=False)

if removed_agent:
    workspace = f"{OPENCLAW}/workspace-{agent_id}"
    print(f"✓ Offboarded: {agent_id}")
    print(f"  Removed from agents.list and cron.")
    print(f"  Workspace preserved at: {workspace}")
    print(f"  Restart OpenClaw to apply.")
else:
    print(f"✗ Agent '{agent_id}' not found.")
PYEOF
  exit 0
fi

echo -e "${RED}Unknown action: $ACTION${NC}"
echo "Valid actions: list, hire, suspend, reinstate, offboard"
exit 1
