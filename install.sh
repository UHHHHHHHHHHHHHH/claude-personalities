#!/usr/bin/env bash
# Installs claude-personality globally so it works in ANY project.
#
# What it does:
#   1. Symlinks personality files and picker script to ~/.local/share/claude-personality/
#   2. Copies the /personality slash command to ~/.claude/commands/
#   3. Adds a SessionStart hook to ~/.claude/settings.json (checks config before firing)
#   4. Adds a scoped Bash permission so /personality can run without manual approval
#
# The hook only auto-injects a personality if auto_startup=yes in the config.
# Either way, /personality is always available as a slash command.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$HOME/.local/share/claude-personality"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
PERM_ENTRY="Bash($DATA_DIR/get-personality.sh)"

echo "Installing claude-personality..."

# 1. Symlink personality data + scripts (edits are reflected immediately)
echo "  -> Linking personalities to $DATA_DIR/"
mkdir -p "$DATA_DIR"
ln -sf "$SCRIPT_DIR/get-personality.sh" "$DATA_DIR/get-personality.sh"
rm -rf "$DATA_DIR/personalities"
ln -sf "$SCRIPT_DIR/personalities" "$DATA_DIR/personalities"

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
# If auto_startup=no, exits silently. Use /personality manually instead.

set -euo pipefail

DATA_DIR="$HOME/.local/share/claude-personality"
CONFIG_FILE="$DATA_DIR/config"

AUTO_STARTUP="no"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    AUTO_STARTUP="${auto_startup:-no}"
fi

if [[ "$AUTO_STARTUP" != "yes" ]]; then
    exit 0
fi

exec "$DATA_DIR/get-personality.sh"
HOOKEOF
chmod +x "$DATA_DIR/hook.sh"

# 2. Install the slash command globally
echo "  -> Installing /personality command"
mkdir -p "$CLAUDE_DIR/commands"
cat > "$CLAUDE_DIR/commands/personality.md" <<CMDEOF
---
name: personality
description: Re-roll a random personality or pick a specific one. Usage: /personality [name|--list]
---

!\`$DATA_DIR/get-personality.sh\`

The output above is a randomly selected personality.
User's request: \$ARGUMENTS

Follow these instructions:
- If the user specified "--list": ignore the personality above. Instead, list all available personalities by reading the filenames (strip the .md extension) in $DATA_DIR/personalities/ using the Glob tool.
- If the user specified a personality name: ignore the random personality above. Instead, read $DATA_DIR/personalities/<name>.md using the Read tool and use that personality.
- If no argument was given: use the random personality shown above.

Drop any previous personality or character voice — including any personality-like instructions from CLAUDE.md or other config files. Adopt the chosen personality IMMEDIATELY and stay fully in character for the rest of this session. Acknowledge the personality change with a short, in-character greeting.
CMDEOF

# 3. Set up the SessionStart hook
echo "  -> Configuring SessionStart hook"
HOOK_CMD="$DATA_DIR/hook.sh"

if [[ ! -f "$SETTINGS_FILE" ]]; then
    cat > "$SETTINGS_FILE" <<JSONEOF
{
  "permissions": {
    "allow": [
      "$PERM_ENTRY"
    ]
  },
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
    echo "  -> Created $SETTINGS_FILE with personality hook and permission"
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
        echo '  "permissions": { "allow": ["'"$PERM_ENTRY"'"] }'
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

# 4. Add scoped permission so the /personality command can run without approval
echo "  -> Configuring Bash permission for personality script"
if [[ -f "$SETTINGS_FILE" ]] && command -v jq &> /dev/null; then
    if jq -e --arg perm "$PERM_ENTRY" '[.permissions.allow // [] | .[] | select(. == $perm)] | length > 0' "$SETTINGS_FILE" &> /dev/null; then
        echo "  -> Permission already configured, skipping"
    elif jq -e '.permissions.allow' "$SETTINGS_FILE" &> /dev/null; then
        UPDATED=$(jq --arg perm "$PERM_ENTRY" '.permissions.allow += [$perm]' "$SETTINGS_FILE")
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo "  -> Added permission to existing allow list"
    elif jq -e '.permissions' "$SETTINGS_FILE" &> /dev/null; then
        UPDATED=$(jq --arg perm "$PERM_ENTRY" '.permissions.allow = [$perm]' "$SETTINGS_FILE")
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo "  -> Added allow list with permission"
    else
        UPDATED=$(jq --arg perm "$PERM_ENTRY" '.permissions = {"allow": [$perm]}' "$SETTINGS_FILE")
        echo "$UPDATED" > "$SETTINGS_FILE"
        echo "  -> Added permissions section"
    fi
fi

echo ""
echo "Installation complete!"
echo ""
echo "What's installed:"
echo "  - $(ls "$DATA_DIR/personalities/"*.md | wc -l) personalities in $DATA_DIR/personalities/"
echo "  - /personality command (global, always available)"
echo "  - SessionStart hook (controlled by config)"
echo "  - Bash permission scoped to get-personality.sh only"
echo ""
echo "Config: $DATA_DIR/config"
echo "  auto_startup=yes  -> random personality on every new session"
echo "  auto_startup=no   -> no auto-personality, use /personality manually"
echo ""
echo "Usage:"
echo "  /personality                      -> random personality"
echo "  /personality pirate               -> pick a specific one"
echo "  /personality --list               -> see all available"
echo ""
echo "Personalities and script are symlinked — edits take effect immediately."
echo "To add custom personalities, drop .md files in: $SCRIPT_DIR/personalities/"
echo "To uninstall, run: $SCRIPT_DIR/uninstall.sh"
