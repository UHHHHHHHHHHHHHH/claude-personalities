#!/usr/bin/env bash
# Uninstalls claude-personality — removes the hook, command, and data.

set -euo pipefail

DATA_DIR="$HOME/.local/share/claude-personality"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
COMMAND_FILE="$CLAUDE_DIR/commands/personality.md"
HOOK_CMD="$DATA_DIR/hook.sh"
PERM_ENTRY="Bash($DATA_DIR/get-personality.sh)"

echo "Uninstalling claude-personality..."

# 1. Remove the slash command
if [[ -f "$COMMAND_FILE" ]]; then
    rm "$COMMAND_FILE"
    echo "  -> Removed /personality command"
else
    echo "  -> /personality command not found (already removed?)"
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

# 3. Remove the Bash permission from settings.json
if [[ -f "$SETTINGS_FILE" ]] && command -v jq &> /dev/null; then
    if jq -e --arg perm "$PERM_ENTRY" '[.permissions.allow // [] | .[] | select(. == $perm)] | length > 0' "$SETTINGS_FILE" &> /dev/null; then
        UPDATED=$(jq --arg perm "$PERM_ENTRY" '.permissions.allow = [.permissions.allow[] | select(. != $perm)]' "$SETTINGS_FILE")
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo "  -> Removed personality Bash permission"

        # Clean up empty arrays/objects
        if jq -e '.permissions.allow == []' "$SETTINGS_FILE" &> /dev/null; then
            UPDATED=$(jq 'del(.permissions.allow)' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
        fi
        if jq -e '.permissions == {} or .permissions == null' "$SETTINGS_FILE" &> /dev/null; then
            UPDATED=$(jq 'del(.permissions)' "$SETTINGS_FILE")
            echo "$UPDATED" > "$SETTINGS_FILE"
        fi
    else
        echo "  -> Personality permission not found in settings (already removed?)"
    fi
elif [[ -f "$SETTINGS_FILE" ]]; then
    echo "  WARNING: 'jq' not installed. Please manually remove \"$PERM_ENTRY\" from permissions.allow in $SETTINGS_FILE"
fi

# 4. Remove personality data
if [[ -d "$DATA_DIR" ]]; then
    rm -rf "$DATA_DIR"
    echo "  -> Removed personality data from $DATA_DIR"
else
    echo "  -> Personality data not found (already removed?)"
fi

echo ""
echo "Uninstall complete! Claude Code will use its default personality on next session."
