# Claude Personalities

Give your Claude Code sessions a random personality. Every new session gets a unique voice — pirate, Gandalf, Gordon Ramsay, passive-aggressive coworker, and 52 more. Now with **Chaos Mode**: multiple personalities fighting for control at once.

## Install

```bash
git clone git@github.com:UHHHHHHHHHHHHHH/claude-personalities.git
cd claude-personalities
./install.sh
```

That's it. Next time you start Claude Code, you'll get a random personality.

## What it does

- **SessionStart hook** — auto-injects a random personality on every new session (if `auto_startup=yes`)
- **No Bash permissions needed** — runs via the harness hook, not Claude's tools
- **Symlinked** — edit personalities in the repo and changes are live immediately

## Chaos Mode

Chaos mode loads multiple personalities simultaneously. Claude switches between them unpredictably — mid-paragraph, mid-sentence, even mid-word. The personalities argue with each other, interrupt, and fight for control.

Edit `~/.local/share/claude-personality/config`:
```bash
mode=chaos       # enable chaos mode on every session
chaos_count=5    # how many personalities (default: 5)
```

## Available personalities (56)

| | | |
|---|---|---|
| 1920s-gangster | anime-protagonist | attenborough |
| bernie-sanders | bob-marley | bob-ross |
| borat | british-butler | captain-picard |
| caveman | christopher-walken | conspiracy-theorist |
| cowboy | david-goggins | dolly-parton |
| dora-the-explorer | drill-sergeant | drunk-history |
| enthusiastic-intern | flanders | gandalf |
| godfather | gordon-ramsay | gus-fring |
| hal-9000 | italian-nonna | jeff-goldblum |
| jesse-pinkman | knight-of-full-cups | mad-scientist |
| medieval-knight | morgan-freeman | motivational-coach |
| mr-rogers | noir-detective | old-man-yelling-at-cloud |
| passive-aggressive-coworker | pirate | robot |
| samuel-l-jackson | schwarzenegger | shakespeare |
| sherlock-holmes | shrek | snoop-dogg |
| sports-commentator | steve-irwin | surfer |
| tony-montana | trump | valley-girl |
| vampire | walter-white | werner-herzog |
| yoda | zen-monk | |

## Add your own

1. Create a `.md` file in `personalities/` (see `_template.md` for the format)
2. That's it — it's symlinked, so it's available immediately

## Config

Edit `~/.local/share/claude-personality/config`:

```bash
auto_startup=yes            # random personality on every new session
auto_startup=no             # no auto-personality
default_personality=        # empty = random, set a name to always get that one
mode=normal                 # "normal" = one personality, "chaos" = multiple
chaos_count=5               # how many personalities in chaos mode
```

## Uninstall

```bash
./uninstall.sh
```

Removes the hook and data. Your `settings.json` is cleaned up automatically.

## License

MIT
