#!/usr/bin/env bash
# Downloads this repository from GitHub (tar.gz), extracts, and runs install-agent-mcps.sh
# so you do not need a local clone.
set -euo pipefail

REPO="${AGENT_SKILLS_GITHUB_REPO:-}"
REF="main"
TARGET="."
FLAVOR=""
FLAVOR_SPECIFIED=false
DRY_RUN=false
KEEP_DOWNLOAD=false
NO_INTERACTIVE=false

usage() {
    cat <<'EOF'
Usage: install-mcps-from-github.sh --repo OWNER/REPO [options]

Required:
  --repo OWNER/REPO     GitHub repository (or set AGENT_SKILLS_GITHUB_REPO)

Options:
  --ref REF             Branch or tag (default: main)
  --target DIR          Project to install into (default: .)
  --flavor NAME         cursor | claude | both (omit on a TTY to choose interactively)
  --no-interactive      Skip menu; use both if --flavor omitted (also AGENT_SKILLS_NONINTERACTIVE=1)
  --dry-run
  --keep-download       Do not delete temp extract
  -h, --help

Example:
  curl -fsSL https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-mcps-from-github.sh | bash -s -- --repo DrivestreamInc/agent-skills --target .
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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --ref)
            REF="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --flavor)
            FLAVOR="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            FLAVOR_SPECIFIED=true
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
        --keep-download)
            KEEP_DOWNLOAD=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$REPO" ]]; then
    echo "Pass --repo OWNER/REPO or set AGENT_SKILLS_GITHUB_REPO." >&2
    exit 1
fi

if [[ "$REPO" != */* ]] || [[ "$REPO" == */*/* ]]; then
    echo "Repository must be exactly OWNER/REPO (got: $REPO)" >&2
    exit 1
fi

if [[ "${AGENT_SKILLS_NONINTERACTIVE:-}" == "1" ]]; then
    NO_INTERACTIVE=true
fi

if [[ "$FLAVOR_SPECIFIED" == false ]]; then
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

REF_ENC="${REF//\//%2F}"
URL="https://github.com/${REPO}/archive/refs/heads/${REF_ENC}.tar.gz"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-mcps-dl.XXXXXX")"
ARCHIVE="${TMP}/repo.tar.gz"

cleanup() {
    if [[ "$KEEP_DOWNLOAD" != true ]]; then
        rm -rf "$TMP"
    else
        echo "Kept download at: $TMP" >&2
    fi
}
trap cleanup EXIT

echo "Downloading ${URL}" >&2
curl -fsSL "$URL" -o "$ARCHIVE"

TOP_NAME="$(tar -tzf "$ARCHIVE" | head -1 | sed 's|/$||')"
if [[ -z "$TOP_NAME" ]]; then
    echo "Empty archive or unexpected layout." >&2
    exit 1
fi

tar -xzf "$ARCHIVE" -C "$TMP"
SRC="${TMP}/${TOP_NAME}"
INSTALL_SH="${SRC}/tools/install-agent-mcps.sh"

if [[ ! -f "$INSTALL_SH" ]]; then
    echo "Archive did not contain tools/install-agent-mcps.sh (got top: $TOP_NAME)" >&2
    exit 1
fi

DRY_FLAG=()
if [[ "$DRY_RUN" == true ]]; then
    DRY_FLAG=(--dry-run)
fi

bash "$INSTALL_SH" --source "$SRC" --target "$TARGET" --flavor "$FLAVOR" --no-interactive "${DRY_FLAG[@]}"
