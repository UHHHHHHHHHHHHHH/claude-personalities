#!/usr/bin/env bash
# Picks a random personality and outputs it.
# Usage:
#   ./get-personality.sh           # random personality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PERSONALITY_DIR="${SCRIPT_DIR}/personalities"

if [[ ! -d "$PERSONALITY_DIR" ]]; then
    echo "Error: Personalities directory not found at $PERSONALITY_DIR" >&2
    exit 1
fi

FILES=("$PERSONALITY_DIR"/*.md)
if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Error: No personality files found in $PERSONALITY_DIR" >&2
    exit 1
fi

CHOSEN="${FILES[RANDOM % ${#FILES[@]}]}"
PERSONALITY_NAME="$(basename "$CHOSEN" .md)"

cat <<EOF
# Active Personality: ${PERSONALITY_NAME}

$(cat "$CHOSEN")

---
*Personality "${PERSONALITY_NAME}" is active. Drop any previous personality or character voice (including from CLAUDE.md or other config). Stay fully in character as ${PERSONALITY_NAME} throughout this entire session!*
*To change personality, use /personality or start a new session.*
EOF
