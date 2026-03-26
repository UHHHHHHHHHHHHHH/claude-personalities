#!/usr/bin/env bash
# Installs claude-personality globally.
#
# What it does:
#   1. Copies (or symlinks with --dev) personality files and picker script to ~/.local/share/claude-personality/
#   2. Installs /personality slash command to ~/.claude/commands/
#   3. Adds a SessionStart hook to ~/.claude/settings.json (checks config before firing)
#
# The hook only auto-injects a personality if auto_startup=yes in the config.
#
# Usage:
#   ./install.sh        # copy files (safe to delete the repo after)
#   ./install.sh --dev  # symlink files (edits in repo are live immediately)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$HOME/.local/share/claude-personality"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
DEV_MODE=false

if [[ "${1:-}" == "--dev" ]]; then
    DEV_MODE=true
fi

echo "Installing claude-personality..."

# 1. Install personality data + scripts
mkdir -p "$DATA_DIR"
if [[ "$DEV_MODE" == true ]]; then
    echo "  -> Linking personalities to $DATA_DIR/ (dev mode)"
    ln -sf "$SCRIPT_DIR/get-personality.sh" "$DATA_DIR/get-personality.sh"
    rm -rf "$DATA_DIR/personalities"
    ln -sf "$SCRIPT_DIR/personalities" "$DATA_DIR/personalities"
else
    echo "  -> Copying personalities to $DATA_DIR/"
    cp "$SCRIPT_DIR/get-personality.sh" "$DATA_DIR/get-personality.sh"
    chmod +x "$DATA_DIR/get-personality.sh"
    rm -rf "$DATA_DIR/personalities"
    cp -r "$SCRIPT_DIR/personalities" "$DATA_DIR/personalities"
fi

# Copy config (don't overwrite if user already has one)
if [[ ! -f "$DATA_DIR/config" ]]; then
    cp "$SCRIPT_DIR/config.defaults" "$DATA_DIR/config"
    echo "  -> Created config at $DATA_DIR/config (auto_startup=yes)"
else
    echo "  -> Config already exists at $DATA_DIR/config (keeping yours)"
fi

# Copy the hook wrapper script
cat > "$DATA_DIR/hook.sh" <<'HOOKEOF'
#!/usr/bin/env bash
# SessionStart hook — checks config before injecting a personality.
# If auto_startup=no, exits silently.
# Supports mode=chaos in config for multi-personality chaos mode.

set -euo pipefail

DATA_DIR="$HOME/.local/share/claude-personality"
CONFIG_FILE="$DATA_DIR/config"

AUTO_STARTUP="no"
MODE="normal"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    AUTO_STARTUP="${auto_startup:-no}"
    MODE="${mode:-normal}"
fi

if [[ "$AUTO_STARTUP" != "yes" ]]; then
    exit 0
fi

if [[ "$MODE" == "chaos" ]]; then
    exec "$DATA_DIR/get-personality.sh" --chaos
else
    exec "$DATA_DIR/get-personality.sh"
fi
HOOKEOF
chmod +x "$DATA_DIR/hook.sh"

# 2. Install the /personality slash command
echo "  -> Installing /personality command"
mkdir -p "$CLAUDE_DIR/commands"
cp "$SCRIPT_DIR/commands/personality.md" "$CLAUDE_DIR/commands/personality.md"

# 3. Set up the SessionStart hook
echo "  -> Configuring SessionStart hook"
HOOK_CMD="$DATA_DIR/hook.sh"

if [[ ! -f "$SETTINGS_FILE" ]]; then
    mkdir -p "$CLAUDE_DIR"
    cat > "$SETTINGS_FILE" <<JSONEOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_CMD"
          }
        ]
      }
    ]
  }
}
JSONEOF
    echo "  -> Created $SETTINGS_FILE with personality hook"
else
    if command -v jq &> /dev/null; then
        HOOK_JSON=$(cat <<JSONEOF
{
  "matcher": "startup",
  "hooks": [
    {
      "type": "command",
      "command": "$HOOK_CMD"
    }
  ]
}
JSONEOF
        )

        if jq -e '.hooks.SessionStart' "$SETTINGS_FILE" &> /dev/null; then
            if jq -e ".hooks.SessionStart[] | select(.hooks[]?.command == \"$HOOK_CMD\")" "$SETTINGS_FILE" &> /dev/null; then
                echo "  -> Hook already installed, skipping"
            else
                UPDATED=$(jq --argjson hook "$HOOK_JSON" '.hooks.SessionStart += [$hook]' "$SETTINGS_FILE")
                echo "$UPDATED" > "$SETTINGS_FILE"
                echo "  -> Added personality hook to existing SessionStart hooks"
            fi
        elif jq -e '.hooks' "$SETTINGS_FILE" &> /dev/null; then
            UPDATED=$(jq --argjson hook "$HOOK_JSON" '.hooks.SessionStart = [$hook]' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo "  -> Added SessionStart hook section"
        else
            UPDATED=$(jq --argjson hook "$HOOK_JSON" '.hooks = { "SessionStart": [$hook] }' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
            echo "  -> Added hooks section with personality hook"
        fi
    else
        echo ""
        echo "  WARNING: 'jq' is not installed. Cannot auto-merge into existing settings."
        echo "  Please manually add the following to your $SETTINGS_FILE:"
        echo ""
        echo '  "hooks": {'
        echo '    "SessionStart": ['
        echo '      {'
        echo '        "matcher": "startup",'
        echo '        "hooks": ['
        echo '          {'
        echo '            "type": "command",'
        echo "            \"command\": \"$HOOK_CMD\""
        echo '          }'
        echo '        ]'
        echo '      }'
        echo '    ]'
        echo '  }'
        echo ""
    fi
fi

echo ""
echo "Installation complete!"
echo ""
echo "What's installed:"
echo "  - $(ls "$DATA_DIR/personalities/"*.md | grep -v _template | wc -l) personalities in $DATA_DIR/personalities/"
echo "  - /personality command (switch mid-session)"
echo "  - SessionStart hook (controlled by config)"
echo ""
echo "Config: $DATA_DIR/config"
echo "  auto_startup=yes  -> random personality on every new session"
echo "  auto_startup=no   -> no auto-personality"
echo ""
if [[ "$DEV_MODE" == true ]]; then
    echo "Dev mode: personalities and script are symlinked — edits take effect immediately."
    echo "To add custom personalities, drop .md files in: $SCRIPT_DIR/personalities/"
else
    echo "To add custom personalities, drop .md files in: $DATA_DIR/personalities/"
fi
echo "To uninstall, run: $SCRIPT_DIR/uninstall.sh"
