#!/usr/bin/env bash
# Uninstalls claude-personality — removes the hook, command, and data.

set -euo pipefail

DATA_DIR="$HOME/.local/share/claude-personality"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
COMMAND_FILE="$CLAUDE_DIR/commands/personality.md"
HOOK_CMD="$DATA_DIR/hook.sh"

echo "Uninstalling claude-personality..."

# 1. Remove the slash command
if [[ -f "$COMMAND_FILE" ]]; then
    rm "$COMMAND_FILE"
    echo "  -> Removed /personality command"
fi

# 2. Remove the hook from settings.json
if [[ -f "$SETTINGS_FILE" ]] && command -v jq &> /dev/null; then
    if jq -e ".hooks.SessionStart[] | select(.hooks[]?.command == \"$HOOK_CMD\")" "$SETTINGS_FILE" &> /dev/null; then
        UPDATED=$(jq "del(.hooks.SessionStart[] | select(.hooks[]?.command == \"$HOOK_CMD\"))" "$SETTINGS_FILE")
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo "  -> Removed personality hook from settings"

        # Clean up empty arrays/objects
        if jq -e '.hooks.SessionStart == []' "$SETTINGS_FILE" &> /dev/null; then
            UPDATED=$(jq 'del(.hooks.SessionStart)' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
        fi
        if jq -e '.hooks == {}' "$SETTINGS_FILE" &> /dev/null; then
            UPDATED=$(jq 'del(.hooks)' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
        fi
    else
        echo "  -> Personality hook not found in settings (already removed?)"
    fi
elif [[ -f "$SETTINGS_FILE" ]]; then
    echo "  WARNING: 'jq' not installed. Please manually remove the personality hook from $SETTINGS_FILE"
fi

# 3. Remove personality data
if [[ -d "$DATA_DIR" ]]; then
    rm -rf "$DATA_DIR"
    echo "  -> Removed personality data from $DATA_DIR"
else
    echo "  -> Personality data not found (already removed?)"
fi

echo ""
echo "Uninstall complete! Claude Code will use its default personality on next session."
