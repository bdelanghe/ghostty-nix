# ghostty-nix

Ghostty's configuration, as a home-manager module.

Extracted 2026-08-28 from `bdelanghe/home`'s `programs/ghostty.nix`, where it
was an inline module in a single-consumer config. It lives here now with
options around it, so the machine-specific parts (the `command`, the font, the
keybinds) are arguments rather than edits.

## What this is not

This does **not** package Ghostty. On macOS the application is not buildable
from nixpkgs, so it comes from the Homebrew cask declared in
`bdelanghe/darwin` (`brew.nix`), and `programs.ghostty.package` is `null`. The
app and its config stay in separate layers on purpose: system vs user.

It also does not write `~/.config/ghostty/config`. Home Manager's own
`programs.ghostty` module does that; this module only supplies its `settings`.

## Use

```nix
{
  inputs.ghostty-nix.url = "github:bdelanghe/ghostty-nix";

  # ... in the home-manager configuration:
  modules = [ ghostty-nix.homeManagerModules.default ];
}
```

```nix
programs.ghostty-nix.enable = true;
```

## Options

| Option | Type | Default |
| --- | --- | --- |
| `programs.ghostty-nix.enable` | bool | `false` |
| `programs.ghostty-nix.command` | str | `"zsh -l -c lobby"` |
| `programs.ghostty-nix.fontFamily` | str | `"JetBrainsMono Nerd Font Mono"` |
| `programs.ghostty-nix.fontSize` | int | `14` |
| `programs.ghostty-nix.padding` | int | `10` |
| `programs.ghostty-nix.keybinds` | list of str | the seven bindings below |

Two notes on the options rather than the defaults. `padding` deliberately
collapses `window-padding-x` and `window-padding-y`, which Ghostty sets
independently; asymmetric padding is still reachable, but through the override
seam below rather than through this option. And `command` can be pointed at a
different program but not removed — the keyValue format has no "unset", so a
configuration that wants Ghostty's default `$SHELL` behaviour should not enable
this module.

Everything else is set with `lib.mkDefault`, so any single key is overridable
at normal priority without `mkForce`:

```nix
programs.ghostty-nix.enable = true;
programs.ghostty.settings.font-size = 16;    # wins over the module's default
programs.ghostty.settings.theme = "nord";    # adds a key the module never sets
```

## The configuration, and why

**`command = "zsh -l -c lobby"`** — every surface opens the lobby roster rather
than a bare shell. The `-l` is load-bearing: Ghostty runs `command` itself, and
a non-login shell never sources `hm-session-vars`, so a lobby started that way
spawns a daemon with no `ANTHROPIC_BASE_URL` and no `OTEL_*`. Every agent
session beneath it would then bypass llm-proxy and export at the 60s default —
and because the daemon is spawned once and its keepers inherit its environment,
that impoverished env outlives the window that created it.

`command` covers every surface (windows, tabs, splits, quick terminal); Ghostty
1.3.1 has no per-surface override. Renaming the key to `initial-command` limits
it to the first surface at startup, if an instant scratch shell on
<code>cmd+`</code> is worth more than a lobby everywhere.

**High contrast** — pure black on white, fully opaque, `minimum-contrast = 3`
so no theme colour can go muddy, `window-colorspace = display-p3`.

**Low motion** — no cursor blink, no resize-overlay flash, zero-duration quick
terminal, `window-save-state = always` for deterministic relaunch.

**Keybinds** — Ghostty is the outermost of three keyboard layers here (Ghostty →
lobby → the terminal application). The innermost application's native bindings
are the fixed point; when one is shadowed, the fix belongs in the outer layer.
Ghostty's `unbind` only forwards a key to the child if it is printable, so
unbinding a chord makes it dead rather than passing it through.

## Related

- `bdelanghe/home` — consumes this module.
- `bdelanghe/darwin` — installs the Ghostty cask.
