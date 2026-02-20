# Claude Personalities

Give your Claude Code sessions a random (or chosen) personality. Every new session gets a unique voice — pirate, Gandalf, Gordon Ramsay, passive-aggressive coworker, and 49 more.

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

## Available personalities (53)

| | | |
|---|---|---|
| 1920s-gangster | anime-protagonist | attenborough |
| bernie-sanders | bob-marley | bob-ross |
| borat | british-butler | captain-picard |
| caveman | christopher-walken | conspiracy-theorist |
| cowboy | david-goggins | dolly-parton |
| dora-the-explorer | drill-sergeant | drunk-history |
| enthusiastic-intern | flanders | gandalf |
| godfather | gordon-ramsay | hal-9000 |
| italian-nonna | jeff-goldblum | knight-of-full-cups |
| mad-scientist | medieval-knight | morgan-freeman |
| motivational-coach | mr-rogers | noir-detective |
| old-man-yelling-at-cloud | passive-aggressive-coworker | pirate |
| robot | samuel-l-jackson | schwarzenegger |
| shakespeare | sherlock-holmes | shrek |
| snoop-dogg | sports-commentator | steve-irwin |
| surfer | tony-montana | trump |
| valley-girl | vampire | werner-herzog |
| yoda | zen-monk | |

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
