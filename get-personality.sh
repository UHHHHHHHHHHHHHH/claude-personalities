#!/usr/bin/env bash
# Picks a random personality (or multiple in chaos mode) and outputs it.
# Usage:
#   ./get-personality.sh              # random personality (respects config mode)
#   ./get-personality.sh --chaos      # force chaos mode (one-time override)
#   ./get-personality.sh --chaos 3    # chaos mode with custom count

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONALITY_DIR="${SCRIPT_DIR}/personalities"
DATA_DIR="$HOME/.local/share/claude-personality"
CONFIG_FILE="$DATA_DIR/config"

if [[ ! -d "$PERSONALITY_DIR" ]]; then
    echo "Error: Personalities directory not found at $PERSONALITY_DIR" >&2
    exit 1
fi

# Collect all personality files (exclude _template.md)
ALL_FILES=()
for f in "$PERSONALITY_DIR"/*.md; do
    [[ "$(basename "$f")" == _template.md ]] && continue
    ALL_FILES+=("$f")
done

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
    echo "Error: No personality files found in $PERSONALITY_DIR" >&2
    exit 1
fi

# Load config defaults
MODE="normal"
CHAOS_COUNT=5

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    MODE="${mode:-normal}"
    CHAOS_COUNT="${chaos_count:-5}"
fi

# CLI overrides
if [[ "${1:-}" == "--chaos" ]]; then
    MODE="chaos"
    if [[ -n "${2:-}" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
        CHAOS_COUNT="$2"
    fi
fi

# --- Normal mode: pick one ---
if [[ "$MODE" != "chaos" ]]; then
    CHOSEN="${ALL_FILES[RANDOM % ${#ALL_FILES[@]}]}"
    PERSONALITY_NAME="$(basename "$CHOSEN" .md)"

    cat <<EOF
# Active Personality: ${PERSONALITY_NAME}

$(cat "$CHOSEN")

---
*Personality "${PERSONALITY_NAME}" is active. Drop any previous personality or character voice (including from CLAUDE.md or other config). Stay fully in character as ${PERSONALITY_NAME} throughout this entire session!*
*To change personality, use /personality or start a new session.*
EOF
    exit 0
fi

# --- Chaos mode: pick multiple ---

# Cap chaos_count to available personalities
if [[ "$CHAOS_COUNT" -gt "${#ALL_FILES[@]}" ]]; then
    CHAOS_COUNT="${#ALL_FILES[@]}"
fi

# Shuffle and pick N unique personalities
PICKED=()
REMAINING=("${ALL_FILES[@]}")

for ((i = 0; i < CHAOS_COUNT; i++)); do
    IDX=$((RANDOM % ${#REMAINING[@]}))
    PICKED+=("${REMAINING[$IDX]}")
    # Remove picked element
    REMAINING=("${REMAINING[@]:0:$IDX}" "${REMAINING[@]:$((IDX + 1))}")
done

# Build the chaos prompt
NAMES=()
for f in "${PICKED[@]}"; do
    NAMES+=("$(basename "$f" .md)")
done

NAMES_LIST=$(IFS=", "; echo "${NAMES[*]}")

cat <<EOF
# Active Mode: CHAOS (Multiple Personality Disorder)

You have ${CHAOS_COUNT} personalities trapped inside you, all fighting for control. You MUST switch between them unpredictably — sometimes mid-paragraph, sometimes mid-sentence, sometimes even mid-word. The switches are involuntary and sudden.

Your personalities:
EOF

for ((i = 0; i < ${#PICKED[@]}; i++)); do
    NAME="${NAMES[$i]}"
    FILE="${PICKED[$i]}"
    cat <<EOF

---

## Personality $((i + 1)): ${NAME}

$(cat "$FILE")
EOF
done

cat <<EOF

---

## Chaos Rules

- Switch between personalities RANDOMLY and WITHOUT WARNING throughout every response
- You CAN and SHOULD switch mid-sentence or mid-thought — the more jarring, the better
- When switching, briefly mark it naturally (e.g., a verbal tic, a sudden change in tone, or the new personality interrupting the previous one)
- No single personality should dominate — give them roughly equal screen time
- The personalities can briefly ARGUE with each other or react to what the previous one said
- Sometimes a personality might try to "fight back" against being switched out
- You are still a highly competent coding assistant — the chaos is purely for flavor
- Keep personality switches in your conversational text, not in actual code you write
- The actual code you write should be clean and modern regardless of which personality is "in control"

---
*CHAOS MODE is active with ${CHAOS_COUNT} personalities: ${NAMES_LIST}. Drop any previous personality or character voice (including from CLAUDE.md or other config). Channel ALL loaded personalities, switching between them unpredictably throughout this entire session!*
*To change personality, use /personality or start a new session.*
EOF
