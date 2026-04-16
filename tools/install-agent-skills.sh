#!/usr/bin/env bash
# Copies canonical skills into a target project's .cursor/skills and/or .claude/skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET="."
FLAVOR="both"
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: install-agent-skills.sh [options] [TARGET]

  TARGET              Project root to install into (default: current directory)

Options:
  --source DIR        Repository root containing skills/ (default: parent of tools/)
  --flavor NAME       cursor | claude | both   (default: both)
  --dry-run           Print actions without copying
  -h, --help          Show this help

Legacy positional (optional):
  TARGET FLAVOR       Same as TARGET and --flavor (if no conflicting flags)
EOF
}

# Parse args: support --flags and legacy "path flavor" at end
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_ROOT="$(cd "$2" && pwd)"
            shift 2
            ;;
        --flavor)
            FLAVOR="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            shift 2
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
    TARGET="${POSITIONAL[0]}"
fi
if [[ ${#POSITIONAL[@]} -ge 2 ]]; then
    FLAVOR="$(echo "${POSITIONAL[1]}" | tr '[:upper:]' '[:lower:]')"
fi

case "$FLAVOR" in
    cursor|claude|both) ;;
    *)
        echo "Invalid flavor: $FLAVOR (use cursor, claude, or both)" >&2
        exit 1
        ;;
esac

SKILLS_SRC="${SOURCE_ROOT}/skills"
if [[ ! -d "$SKILLS_SRC" ]]; then
    echo "skills directory not found: $SKILLS_SRC" >&2
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

copy_skill_tree() {
    local from="$1"
    local to="$2"
    if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] $from -> $to"
        return
    fi
    rm -rf "$to"
    mkdir -p "$(dirname "$to")"
    cp -a "$from" "$to"
}

install_skills_to() {
    local rel="$1"
    local dest_root="${TARGET}/${rel}"
    for skill_dir in "${SKILLS_SRC}"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        local dest="${dest_root}/${name}"
        if [[ "$DRY_RUN" == true ]]; then
            echo "[dry-run] copy skill '${name}' -> ${dest}"
        else
            mkdir -p "$dest_root"
            copy_skill_tree "$skill_dir" "$dest"
        fi
    done
}

case "$FLAVOR" in
    cursor) install_skills_to ".cursor/skills" ;;
    claude) install_skills_to ".claude/skills" ;;
    both)
        install_skills_to ".cursor/skills"
        install_skills_to ".claude/skills"
        ;;
esac

if [[ "$DRY_RUN" != true ]]; then
    echo "Done. Skills installed under target: $TARGET"
fi
