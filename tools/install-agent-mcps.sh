#!/usr/bin/env bash
# Merges canonical MCP entries from mcps/servers.json into .cursor/mcp.json and/or .mcp.json.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET="."
TARGET_SET_BY_FLAG=false
FLAVOR="both"
FLAVOR_EXPLICIT=false
DRY_RUN=false
NO_INTERACTIVE=false

usage() {
    cat <<'EOF'
Usage: install-agent-mcps.sh [options] [TARGET]

  TARGET              Project root to install into (default: current directory)

Options:
  --source DIR        Repository root containing mcps/servers.json (default: parent of tools/)
  --target DIR        Same as TARGET (overrides positional TARGET if both given)
  --flavor NAME       cursor | claude | both (omit on a TTY to choose interactively)
  --no-interactive    Skip menu; use both if --flavor omitted (also AGENT_SKILLS_NONINTERACTIVE=1)
  --dry-run           Print actions without writing files
  -h, --help          Show this help

Legacy positional (optional):
  TARGET FLAVOR       Same as TARGET and --flavor (if no conflicting flags)
EOF
}

prompt_flavor() {
    echo "Where should MCP config be merged?" >&2
    echo "  1) Cursor  (.cursor/mcp.json)" >&2
    echo "  2) Claude  (.mcp.json)" >&2
    echo "  3) Both" >&2
    while true; do
        read -r -p "Choice [1-3] (default 3): " choice || true
        case "${choice:-3}" in
            1) FLAVOR="cursor"; break ;;
            2) FLAVOR="claude"; break ;;
            3|"") FLAVOR="both"; break ;;
            *)
                echo "Invalid choice: enter 1, 2, or 3." >&2
                ;;
        esac
    done
}

merge_mcp_json() {
    local canonical_path="$1"
    local dest_path="$2"
    python3 - "$canonical_path" "$dest_path" <<'PY'
import json
import sys

canonical_path, dest_path = sys.argv[1], sys.argv[2]
managed = {"docs-langchain", "browser-use"}

with open(canonical_path, encoding="utf-8") as f:
    canon = json.load(f)
if "mcpServers" not in canon:
    sys.exit("Canonical file missing mcpServers: " + canonical_path)

ms = {}
try:
    with open(dest_path, encoding="utf-8") as f:
        existing = json.load(f)
except FileNotFoundError:
    existing = {}
for k, v in existing.get("mcpServers", {}).items():
    if k not in managed:
        ms[k] = v
for k in managed:
    if k not in canon["mcpServers"]:
        sys.exit("Canonical mcpServers missing key: " + k)
    ms[k] = canon["mcpServers"][k]

out = {"mcpServers": ms}
with open(dest_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
PY
}

# Parse args
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_ROOT="$(cd "$2" && pwd)"
            shift 2
            ;;
        --target)
            TARGET="$2"
            TARGET_SET_BY_FLAG=true
            shift 2
            ;;
        --flavor)
            FLAVOR="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            FLAVOR_EXPLICIT=true
            shift 2
            ;;
        --no-interactive)
            NO_INTERACTIVE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

while [[ $# -gt 0 ]]; do
    POSITIONAL+=("$1")
    shift
done

if [[ ${#POSITIONAL[@]} -ge 1 ]]; then
    if [[ "$TARGET_SET_BY_FLAG" == true ]]; then
        echo "error: pass either --target or a positional TARGET, not both." >&2
        exit 1
    fi
    TARGET="${POSITIONAL[0]}"
fi
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
    FLAVOR="$(echo "${POSITIONAL[1]}" | tr '[:upper:]' '[:lower:]')"
    FLAVOR_EXPLICIT=true
fi

if [[ "${AGENT_SKILLS_NONINTERACTIVE:-}" == "1" ]]; then
    NO_INTERACTIVE=true
fi

if [[ "$FLAVOR_EXPLICIT" == false ]]; then
    if [[ -t 0 ]] && [[ "$NO_INTERACTIVE" != true ]]; then
        prompt_flavor
    else
        FLAVOR="both"
    fi
fi

case "$FLAVOR" in
    cursor|claude|both) ;;
    *)
        echo "Invalid flavor: $FLAVOR (use cursor, claude, or both)" >&2
        exit 1
        ;;
esac

CANON="${SOURCE_ROOT}/mcps/servers.json"
if [[ ! -f "$CANON" ]]; then
    echo "MCP manifest not found: $CANON" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 is required to merge MCP JSON (install Python 3 or use install-agent-mcps.ps1 on Windows)." >&2
    exit 1
fi

if [[ ! -d "$TARGET" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "Target project path does not exist: $TARGET (create it first, or omit --dry-run to create it)" >&2
        exit 1
    fi
    mkdir -p "$TARGET"
fi
TARGET="$(cd "$TARGET" && pwd)"

install_one() {
    local rel="$1"
    local dest="${TARGET}/${rel}"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] merge MCP servers -> ${dest}"
        return
    fi
    local parent
    parent="$(dirname "$dest")"
    if [[ "$parent" != "." ]] && [[ "$parent" != "$TARGET" ]]; then
        mkdir -p "$parent"
    fi
    merge_mcp_json "$CANON" "$dest"
    echo "Updated: ${dest}"
}

case "$FLAVOR" in
    cursor) install_one ".cursor/mcp.json" ;;
    claude) install_one ".mcp.json" ;;
    both)
        install_one ".cursor/mcp.json"
        install_one ".mcp.json"
        ;;
esac

if [[ "$DRY_RUN" != true ]]; then
    echo "Done. MCP defaults merged under target: $TARGET"
fi
