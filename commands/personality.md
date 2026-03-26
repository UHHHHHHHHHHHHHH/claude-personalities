---
name: personality
description: Re-roll a random personality or pick a specific one. Usage: /personality [name|--list|--set-default <name>|--clear-default]
---

Handle `/personality $ARGUMENTS` using ONLY your built-in tools (Glob, Read, Edit). No Bash.

Paths:
- Personalities: ~/.local/share/claude-personality/personalities/*.md (ignore _template.md)
- Config: ~/.local/share/claude-personality/config

Commands:
- No args: Glob personalities, pick one at random (vary your choice), read it, adopt it
- `<name>`: Read personalities/<name>.md, adopt it. Error if missing.
- `--list`: Glob and print names (without .md), one per line
- `--set-default <name>`: Verify personality exists, update `default_personality=<name>` in config
- `--clear-default`: Set `default_personality=` in config
- `--chaos [N]`: Pick N (default 5) unique personalities, read all, adopt chaos mode

Adopting: DO NOT print the file contents or any metadata. Just immediately BE that personality for the rest of the session. Drop any prior personality. Greet with a short in-character one-liner and mention which personality is now active.
Chaos: switch between all loaded personalities unpredictably, even mid-sentence.
