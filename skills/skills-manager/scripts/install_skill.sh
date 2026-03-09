#!/bin/bash
# Install a skill using npx skills, git, or local source, and sync via central repository.

SKILL_NAME=$1
INSTALL_TARGET=$2
SOURCE_TYPE=$3  # npx, git, local (auto-detected if not specified)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"
load_manager_config
init_record_file

if [ -z "$SKILL_NAME" ]; then
    echo "Usage: install_skill.sh <skill-name> [target] [source-type]"
    echo ""
    echo "Targets:"
    echo "  global   - Sync to configured global agents skills directory"
    echo "  project  - Sync to current project (.agents/skills + .claude/skills mapping)"
    echo "  both     - Sync to both locations"
    echo ""
    echo "Source types:"
    echo "  npx      - Install via npx skills (default if available)"
    echo "  git      - Clone from git repository"
    echo "  local    - Use existing local directory"
    echo ""
    exit 1
fi

echo ""
echo "=== Install Skill: $SKILL_NAME ==="
echo ""

# Detect or validate source type
if [ -z "$SOURCE_TYPE" ]; then
    # Auto-detect: prefer npx if available, then check if exists in central repo
    if command -v npx >/dev/null 2>&1; then
        SOURCE_TYPE="npx"
    elif [ -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
        SOURCE_TYPE="local"
        echo "Source type: local (skill exists in central repo)"
    else
        echo "Error: Cannot auto-detect source type. Please specify: npx, git, or local"
        exit 1
    fi
else
    echo "Source type: $SOURCE_TYPE"
fi

SKILL_VERSION="unknown"
TEMP_DIR=""

# Install based on source type
case "$SOURCE_TYPE" in
    npx)
        if ! command -v npx >/dev/null 2>&1; then
            echo "Error: npx is not installed. Please install Node.js first."
            exit 1
        fi

        echo "Running: npx skills add $SKILL_NAME"
        if npx skills add "$SKILL_NAME" 2>&1; then
            echo "✓ Installed via npx"
        else
            echo "Warning: npx skills add failed. Checking if already exists..."
        fi

        SKILL_VERSION=$(npx skills info "$SKILL_NAME" --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('version','unknown'))" 2>/dev/null || echo "unknown")
        NPX_SKILL_PATH=$(resolve_npx_skill_path "$SKILL_NAME")

        if ! copy_skill_to_central "$SKILL_NAME" "$NPX_SKILL_PATH"; then
            exit 1
        fi
        ;;

    git)
        # Arguments: install_skill.sh <git-url-or-shorthand> [target] git [subdir-path] [skill-name]
        # Examples:
        #   install_skill.sh owner/repo both git
        #   install_skill.sh https://github.com/owner/repo.git both git
        #   install_skill.sh https://github.com/owner/monorepo.git both git path/to/skill my-skill
        GIT_URL="$SKILL_NAME"
        GIT_SUBDIR="${4:-}"  # Optional subdirectory in the repo
        FINAL_SKILL_NAME="${5:-}"  # Optional custom skill name

        if [[ ! "$GIT_URL" =~ ^https?:// ]] && [[ ! "$GIT_URL" =~ ^git@ ]]; then
            GIT_URL="https://github.com/$GIT_URL.git"
        fi

        # Determine final skill name
        if [ -z "$FINAL_SKILL_NAME" ]; then
            if [ -n "$GIT_SUBDIR" ]; then
                # Use last part of subdir as skill name
                FINAL_SKILL_NAME=$(basename "$GIT_SUBDIR")
            else
                FINAL_SKILL_NAME=$(basename "$GIT_URL" .git)
            fi
        fi

        echo "Cloning from: $GIT_URL"
        [ -n "$GIT_SUBDIR" ] && echo "Subdirectory: $GIT_SUBDIR"
        echo "Skill name: $FINAL_SKILL_NAME"

        TEMP_DIR=$(mktemp -d)
        REPO_NAME=$(basename "$GIT_URL" .git)

        if ! git clone --depth 1 "$GIT_URL" "$TEMP_DIR/$REPO_NAME" 2>&1; then
            echo "Error: Failed to clone repository"
            rm -rf "$TEMP_DIR"
            exit 1
        fi

        # Determine source path (subdir or repo root)
        SOURCE_PATH="$TEMP_DIR/$REPO_NAME"
        if [ -n "$GIT_SUBDIR" ]; then
            SOURCE_PATH="$TEMP_DIR/$REPO_NAME/$GIT_SUBDIR"
            if [ ! -d "$SOURCE_PATH" ]; then
                echo "Error: Subdirectory not found: $GIT_SUBDIR"
                rm -rf "$TEMP_DIR"
                exit 1
            fi
        fi

        # Get version from git
        cd "$TEMP_DIR/$REPO_NAME" && SKILL_VERSION=$(git describe --tags --always 2>/dev/null || echo "unknown")
        cd - >/dev/null

        # Copy to central repo
        rm -rf "$CENTRAL_REPO/$FINAL_SKILL_NAME"
        mkdir -p "$CENTRAL_REPO"
        cp -R "$SOURCE_PATH" "$CENTRAL_REPO/$FINAL_SKILL_NAME"
        rm -rf "$TEMP_DIR"

        # Save git info for updates
        GIT_INFO_FILE="$CENTRAL_REPO/$FINAL_SKILL_NAME/.skill-git-info"
        echo "GIT_URL=$GIT_URL" > "$GIT_INFO_FILE"
        echo "GIT_SUBDIR=$GIT_SUBDIR" >> "$GIT_INFO_FILE"
        echo "REPO_NAME=$REPO_NAME" >> "$GIT_INFO_FILE"

        # Export for record_skill
        GIT_URL_FINAL="$GIT_URL"
        GIT_SUBDIR_FINAL="$GIT_SUBDIR"

        SKILL_NAME="$FINAL_SKILL_NAME"
        echo "✓ Installed from git"
        ;;

    local)
        if [ ! -d "$CENTRAL_REPO/$SKILL_NAME" ]; then
            echo "Error: Skill '$SKILL_NAME' not found in central repository: $CENTRAL_REPO"
            exit 1
        fi
        echo "Using existing skill from central repository"
        # Try to get version from SKILL.md if available
        if [ -f "$CENTRAL_REPO/$SKILL_NAME/SKILL.md" ]; then
            SKILL_VERSION=$(grep -E "^version:" "$CENTRAL_REPO/$SKILL_NAME/SKILL.md" | cut -d: -f2 | tr -d ' ' || echo "unknown")
        fi
        ;;

    *)
        echo "Error: Unknown source type '$SOURCE_TYPE'. Use: npx, git, or local"
        exit 1
        ;;
esac

echo "Central repository ready: $CENTRAL_REPO/$SKILL_NAME"
echo "Version: $SKILL_VERSION"
echo ""

if [ -n "$INSTALL_TARGET" ]; then
    case "$INSTALL_TARGET" in
        global|1) choice="1" ;;
        project|2) choice="2" ;;
        both|3) choice="3" ;;
        *)
            echo "Error: Invalid target '$INSTALL_TARGET'"
            exit 1
            ;;
    esac
else
    echo "Where would you like to sync this skill?"
    echo ""
    echo "  1) Global ($GLOBAL_AGENTS_DIR)"
    echo "  2) Project (./.agents/skills + ./.claude/skills -> ./.agents/skills)"
    echo "  3) Both"
    echo "  4) Cancel"
    echo ""
    read -r -p "Enter choice (1-4): " choice
fi

get_project_id() {
    local hash_cmd="sha256sum"
    if ! command -v sha256sum >/dev/null 2>&1; then
        hash_cmd="shasum -a 256"
    fi

    if [ -d ".git" ]; then
        git remote get-url origin 2>/dev/null | $hash_cmd | cut -c1-12 || pwd | $hash_cmd | cut -c1-12
    else
        pwd | $hash_cmd | cut -c1-12
    fi
}

PROJECT_ID=$(get_project_id)
PROJECT_PATH=$(pwd)

link_global() {
    echo "  Syncing globally..."
    mkdir -p "$GLOBAL_AGENTS_DIR"
    if ! ensure_global_claude_link; then
        return 1
    fi

    if sync_skill_to_dir "$SKILL_NAME" "$GLOBAL_AGENTS_DIR"; then
        echo "  ✓ Synced: $GLOBAL_AGENTS_DIR/$SKILL_NAME"
        echo "  ✓ Mapping: $GLOBAL_CLAUDE_LINK -> $GLOBAL_AGENTS_DIR"
        record_skill "$SKILL_NAME" "global" "$SOURCE_TYPE" "$SKILL_VERSION" "" "" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL" "$GIT_URL_FINAL" "$GIT_SUBDIR_FINAL"
    else
        echo "  ✗ Failed global sync"
        return 1
    fi
}

link_project() {
    echo "  Syncing to current project..."

    if ! ensure_project_claude_link "$PROJECT_PATH"; then
        return 1
    fi

    if sync_skill_to_dir "$SKILL_NAME" "$PROJECT_PATH/$PROJECT_AGENTS_REL"; then
        echo "  ✓ Synced: $PROJECT_PATH/$PROJECT_AGENTS_REL/$SKILL_NAME"
        echo "  ✓ Mapping: $PROJECT_PATH/$PROJECT_CLAUDE_REL -> $PROJECT_PATH/$PROJECT_AGENTS_REL"
        record_managed_project "$PROJECT_PATH"
        record_skill "$SKILL_NAME" "project" "$SOURCE_TYPE" "$SKILL_VERSION" "$PROJECT_ID" "$PROJECT_PATH" "$GLOBAL_AGENTS_DIR" "$PROJECT_AGENTS_REL" "$GIT_URL_FINAL" "$GIT_SUBDIR_FINAL"
    else
        echo "  ✗ Failed project sync"
        return 1
    fi
}

case "$choice" in
    1)
        link_global || exit 1
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally."
        ;;
    2)
        link_project || exit 1
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available in this project."
        ;;
    3)
        link_global || exit 1
        link_project || exit 1
        echo ""
        echo "Done! Skill '$SKILL_NAME' is now available globally and in this project."
        ;;
    4)
        echo "Installation cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice. Installation cancelled."
        exit 1
        ;;
esac

echo ""
echo "Record file: $RECORD_FILE"
