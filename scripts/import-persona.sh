#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  Company OS — Import Persona
#  Usage:
#    bash import-persona.sh /path/to/persona-folder
#    bash import-persona.sh persona.zip
#    bash import-persona.sh --from-guildex PersonaName
#    bash import-persona.sh --search keyword
# ─────────────────────────────────────────────
set -e

OPENCLAW="$HOME/.openclaw"
GUILDEX_REPO="https://github.com/joe-qiao-ai/guildex-ai-talent"
GUILDEX_RAW="https://raw.githubusercontent.com/joe-qiao-ai/guildex-ai-talent/main"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; CYAN='\033[0;36m'; NC='\033[0m'

# ── Detect talent library path ──
TALENT_DIR=$(python3 -c "
import json, os
try:
    with open('$OPENCLAW/openclaw.json') as f:
        c = json.load(f)
    print(c.get('plugins', {}).get('company-os', {}).get('talentDir', os.path.expanduser('~/talent-library')))
except:
    print(os.path.expanduser('~/talent-library'))
" 2>/dev/null || echo "$HOME/talent-library")

# ── Arg check ────────────────────────────────
if [ -z "$1" ]; then
  echo -e "${BOLD}Guildex Persona Importer${NC}"
  echo ""
  echo "Usage:"
  echo "  bash import-persona.sh /path/to/folder     Import from local folder"
  echo "  bash import-persona.sh persona.zip         Import from zip"
  echo "  bash import-persona.sh --from-guildex Name  Pull from Guildex GitHub"
  echo "  bash import-persona.sh --search keyword     Search Guildex GitHub"
  echo ""
  echo "Browse all personas: $GUILDEX_REPO"
  exit 1
fi

# ── Handle --search ───────────────────────────
if [ "$1" = "--search" ]; then
  if [ -z "$2" ]; then
    echo -e "${RED}Usage: bash scripts/import-persona.sh --search <keyword>${NC}"
    exit 1
  fi
  KEYWORD="$2"
  echo -e "${CYAN}Searching Guildex for \"$KEYWORD\"...${NC}"
  echo ""
  python3 - <<PYEOF
import urllib.request, json

keyword = "$KEYWORD".lower()
base_url = "https://api.github.com/repos/joe-qiao-ai/guildex-ai-talent/contents"
headers = {"User-Agent": "company-os-importer"}

def fetch(url):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())

try:
    # Get root categories
    root = fetch(base_url)
    categories = [i for i in root if i["type"] == "dir"]
    matches = []

    for cat in categories:
        try:
            personas = fetch(cat["url"])
            for p in personas:
                if p["type"] == "dir" and keyword in p["name"].lower():
                    matches.append((cat["name"], p["name"]))
        except:
            pass

    if matches:
        print(f"Found {len(matches)} match(es):\n")
        for cat, name in matches:
            print(f"  [{cat}]  {name}")
        print(f"\nTo import:")
        for _, name in matches[:3]:
            print(f"  bash scripts/import-persona.sh --from-guildex \"{name}\"")
    else:
        print(f"No matches for '{keyword}'.")
        print(f"Browse: $GUILDEX_REPO")
except Exception as e:
    print(f"Could not reach GitHub: {e}")
    print(f"Browse manually: $GUILDEX_REPO")
PYEOF
  exit 0
fi

# ── Handle --from-guildex ─────────────────────
if [ "$1" = "--from-guildex" ]; then
  if [ -z "$2" ]; then
    echo -e "${RED}Usage: bash scripts/import-persona.sh --from-guildex <PersonaName>${NC}"
    exit 1
  fi
  PERSONA_NAME="$2"
  echo -e "${CYAN}Pulling ${BOLD}$PERSONA_NAME${NC}${CYAN} from Guildex...${NC}"

  TMP_DIR=$(mktemp -d)
  PERSONA_DIR="$TMP_DIR/$PERSONA_NAME"
  mkdir -p "$PERSONA_DIR"

  # Auto-find which category the persona lives in
  CATEGORY=$(python3 - <<PYEOF
import urllib.request, json

headers = {"User-Agent": "company-os-importer"}
name = "$PERSONA_NAME".lower()

def fetch(url):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())

try:
    root = fetch("https://api.github.com/repos/joe-qiao-ai/guildex-ai-talent/contents")
    for cat in root:
        if cat["type"] != "dir": continue
        try:
            personas = fetch(cat["url"])
            for p in personas:
                if p["type"] == "dir" and p["name"].lower() == name:
                    print(cat["name"])
                    exit()
        except:
            pass
except:
    pass
PYEOF
)

  if [ -z "$CATEGORY" ]; then
    echo -e "${RED}✗ Persona '$PERSONA_NAME' not found in Guildex.${NC}"
    echo -e "  Try: bash scripts/import-persona.sh --search <keyword>"
    echo -e "  Browse: ${CYAN}$GUILDEX_REPO${NC}"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  echo -e "  ${CYAN}Found in category: $CATEGORY${NC}"

  # Download each standard file from the correct path
  SUCCESS=0
  for FILE in SOUL.md SKILLS.md EXAMPLES.md TESTS.md README.md; do
    if python3 - <<PYEOF 2>/dev/null | grep -q "ok"
import urllib.request, urllib.parse
category = "$CATEGORY"
persona  = "$PERSONA_NAME"
fname    = "$FILE"
dest     = "$PERSONA_DIR/$FILE"
encoded  = urllib.parse.quote(persona)
url      = f"$GUILDEX_RAW/{urllib.parse.quote(category)}/{encoded}/{fname}"
try:
    urllib.request.urlretrieve(url, dest)
    print("ok")
except:
    print("skip")
PYEOF
    then
      echo -e "  ${GREEN}✓${NC} $FILE"
      SUCCESS=$((SUCCESS + 1))
    fi
  done

  if [ $SUCCESS -eq 0 ]; then
    echo -e "${RED}✗ Could not download files for '$PERSONA_NAME'.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
  fi

  SOURCE="$PERSONA_DIR"
fi

SOURCE="${SOURCE:-$1}"

# ── Unzip if needed ───────────────────────────
if [[ "$SOURCE" == *.zip ]]; then
  TMP_DIR=$(mktemp -d)
  echo "Extracting $SOURCE..."
  unzip -q "$SOURCE" -d "$TMP_DIR"
  # Find the actual persona folder inside
  PERSONA_DIR=$(find "$TMP_DIR" -name "SOUL.md" -maxdepth 3 | head -1 | xargs dirname 2>/dev/null)
  if [ -z "$PERSONA_DIR" ]; then
    echo -e "${RED}✗ Could not find SOUL.md inside the zip${NC}"
    rm -rf "$TMP_DIR"
    exit 1
  fi
else
  PERSONA_DIR="$SOURCE"
fi

# ── Validate ─────────────────────────────────
if [ ! -f "$PERSONA_DIR/SOUL.md" ]; then
  echo -e "${RED}✗ SOUL.md not found in $PERSONA_DIR${NC}"
  exit 1
fi

PERSONA_NAME=$(basename "$PERSONA_DIR")
DEST="$TALENT_DIR/$PERSONA_NAME"

if [ -d "$DEST" ]; then
  echo -e "${YELLOW}⚠ Persona '$PERSONA_NAME' already exists in talent library${NC}"
  read -p "Overwrite? [y/N] " OVERWRITE
  [[ ! "$OVERWRITE" =~ ^[Yy] ]] && echo "Skipped." && exit 0
  rm -rf "$DEST"
fi

# ── Copy to talent library ────────────────────
cp -r "$PERSONA_DIR" "$DEST"
echo -e "${GREEN}✓ Imported: ${BOLD}$PERSONA_NAME${NC}${GREEN} → $DEST${NC}"

# ── Check completeness ───────────────────────
MISSING=()
for f in SOUL.md SKILLS.md EXAMPLES.md TESTS.md README.md; do
  [ ! -f "$DEST/$f" ] && MISSING+=("$f")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "${YELLOW}  ⚠ Incomplete persona — missing: ${MISSING[*]}${NC}"
  echo -e "    Can still deploy, but some capabilities may be limited."
else
  echo -e "${GREEN}  ✓ Complete persona package (5/5 files)${NC}"
fi

# ── Add to categories.json if not present ─────
CATEGORIES_FILE="$TALENT_DIR/categories.json"
if [ -f "$CATEGORIES_FILE" ]; then
  python3 - <<PYEOF
import json

with open("$CATEGORIES_FILE", 'r') as f:
    data = json.load(f)

personas = data.get('personas', {})
if "$PERSONA_NAME" not in personas:
    personas["$PERSONA_NAME"] = "uncategorized"
    data['personas'] = personas
    with open("$CATEGORIES_FILE", 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("  ✓ Added to talent library index (uncategorized — set category in Dashboard)")
else:
    print("  ✓ Already in talent library index")
PYEOF
fi

# Cleanup temp dir if we extracted a zip
[ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"

echo ""
echo -e "${BOLD}Done. Open Dashboard → 人才库 to set category and deploy.${NC}"
