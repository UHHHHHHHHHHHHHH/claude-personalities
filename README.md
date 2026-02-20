# Claude Personalities

Give your Claude Code sessions a random (or chosen) personality. Every new session gets a unique voice — pirate, Gandalf, Gordon Ramsay, passive-aggressive coworker, and 26 more.

## Install

```bash
git clone git@github.com:UHHHHHHHHHHHHHH/claude-personalities.git
cd claude-personalities
./install.sh
```

That's it. Next time you start Claude Code, you'll get a random personality.

## What it does

- **SessionStart hook** — auto-injects a random personality on every new session (if `auto_startup=yes`)
- **`/personality` command** — switch personality mid-session
- **Scoped Bash permission** — only allows running the picker script, nothing else
- **Symlinked** — edit personalities in the repo and changes are live immediately

## Usage

```
/personality              # random personality
/personality pirate       # pick a specific one
/personality --list       # see all available
```

## Available personalities (30)

| | | |
|---|---|---|
| 1920s-gangster | attenborough | bob-ross |
| borat | caveman | cowboy |
| drill-sergeant | enthusiastic-intern | flanders |
| gandalf | godfather | gordon-ramsay |
| mad-scientist | medieval-knight | morgan-freeman |
| motivational-coach | mr-rogers | noir-detective |
| passive-aggressive-coworker | pirate | robot |
| shakespeare | sherlock-holmes | snoop-dogg |
| sports-commentator | steve-irwin | surfer |
| vampire | yoda | zen-monk |

## Add your own

1. Create a `.md` file in `personalities/` (see `_template.md` for the format)
2. That's it — it's symlinked, so it's available immediately

## Config

Edit `~/.local/share/claude-personality/config`:

```bash
auto_startup=yes   # random personality on every new session
auto_startup=no    # no auto-personality, use /personality manually
```

## Uninstall

```bash
./uninstall.sh
```

Removes the hook, permission, command, and data. Your `settings.json` is cleaned up automatically.

## License

MIT
