{ config, lib, ... }:

let
  cfg = config.programs.ghostty-nix;
in
{
  # An opinionated Ghostty configuration, expressed as a layer over
  # home-manager's own `programs.ghostty`. This module never writes a file: it
  # only supplies `programs.ghostty.settings`, so the upstream module remains
  # the single thing that owns the package, the keyValue formatter and
  # ~/.config/ghostty/config.
  #
  # Every value below is set with `lib.mkDefault`, which is the whole point of
  # having this as a module rather than a copied file: a consuming
  # configuration overrides any single key by writing
  # `programs.ghostty.settings.<key> = ...` at normal priority, with no
  # `mkForce` and no forking.
  options.programs.ghostty-nix = {
    enable = lib.mkEnableOption "the opinionated Ghostty configuration";

    command = lib.mkOption {
      type = lib.types.str;
      default = "zsh -l -c lobby";
      description = ''
        Ghostty's `command` — what every surface opens instead of a bare shell.

        Override with a different command string to launch something else.
        There is no way to drop the key entirely from here: the keyValue
        format has no "unset" and overriding only replaces the value, so a
        configuration that wants Ghostty's default `$SHELL` behaviour should
        not enable this module.
      '';
    };

    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "JetBrainsMono Nerd Font Mono";
      description = "Ghostty's `font-family`.";
    };

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Ghostty's `font-size`.";
    };

    padding = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Window padding, applied to both `window-padding-x` and `window-padding-y`.";
    };

    keybinds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "global:cmd+grave_accent=toggle_quick_terminal"

        # KEPT, and NOT a duplicate of Ghostty's default — this is the trap.
        # `ghostty +list-keybinds --default` reports `super+c=copy_to_clipboard:mixed`.
        # This line binds plain `copy_to_clipboard`, WITHOUT `:mixed`. Deleting
        # it as "redundant" would not restore a default, it would change copy
        # behaviour. Verified against the installed binary, 2026-09-11.
        "cmd+c=copy_to_clipboard"

        # REMOVED 2026-09-11:
        #
        #   cmd+v=paste_from_clipboard
        #     A true duplicate — the default is `super+v=paste_from_clipboard`,
        #     identical, and super is cmd on macOS. Checked against the binary,
        #     not assumed from its neighbour above.
        #
        #   super+alt+{h,j,k,l}=goto_split:{left,down,up,right}
        #     Dead: nothing here ever creates a split, so all four were bound to
        #     a navigation that had nowhere to go. They also have no future:
        #     lobby owns layout, Ghostty owns pixels, and a second surface is a
        #     second WINDOW rather than a pane. Note Ghostty's `unbind` only
        #     forwards a key to the child if it is printable, so these were not
        #     merely inert — they made four chords dead rather than passing them
        #     through to the application beneath.
      ];
      description = ''
        Ghostty's `keybind` entries, emitted as repeated `keybind = ` lines.

        Ghostty is the outermost of three keyboard layers here (Ghostty →
        lobby → the terminal application). The innermost application's native
        bindings are the fixed point; when one is shadowed, the fix belongs in
        this list or in lobby, not in the application. Note that Ghostty's
        `unbind` only forwards a key to the child if it is printable, so
        unbinding a chord makes it dead rather than passing it through.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      # macOS Ghostty is not buildable from nixpkgs, so the application itself
      # comes from the Homebrew cask and home-manager manages only the config
      # file. Override this (`programs.ghostty.package = pkgs.ghostty;`) on a
      # platform where the package exists.
      package = lib.mkDefault null;

      settings = lib.mapAttrs (_name: lib.mkDefault) {
        # Every surface opens the lobby rather than a bare shell: the roster is
        # where agents are summoned, attached to and killed, so it is what a
        # terminal should be showing.
        #
        # The `zsh -l` is load-bearing, not ceremony. Ghostty runs `command`
        # itself, and a non-login shell never sources hm-session-vars — so a
        # lobby started that way spawns a daemon with no ANTHROPIC_BASE_URL and
        # no OTEL_*, and every claude session beneath it bypasses llm-proxy and
        # exports at the 60s default. The daemon is spawned once and its keepers
        # inherit its environment, so that impoverished env would outlive the
        # window that created it. A login shell is what the bare `$SHELL`
        # default gave us for free, and what this has to keep giving.
        #
        # `command` covers every surface — windows, tabs, splits and the quick
        # terminal; Ghostty 1.3.1 has no per-surface override (`new_window`
        # takes no command argument). If the instant scratch shell on cmd+` is
        # worth more than a lobby everywhere, rename this key to
        # `initial-command`, which applies only to the first surface at startup.
        command = cfg.command;

        font-family = cfg.fontFamily;
        font-size = cfg.fontSize;
        font-thicken = true;

        # High contrast, fully opaque, no blur, and a floor on text contrast so
        # no theme color can go muddy.
        #
        # Near-black and off-white rather than #000000/#ffffff (changed
        # 2026-09-11). Pure black against pure white is the maximum the display
        # can produce, which reads as glare rather than as legibility: on an OLED
        # or a high-brightness panel the #fff glyph edges bloom against a #000
        # field and the text shimmers on long reads. Pulling both ends in one
        # step keeps the contrast ratio far above any legibility threshold —
        # `minimum-contrast = 3` below still holds — while removing the halation.
        background = "#0e0e0e";
        foreground = "#e4e4e4";
        background-opacity = 1.0;
        minimum-contrast = 3;
        window-colorspace = "display-p3";

        window-padding-x = cfg.padding;
        window-padding-y = cfg.padding;
        window-padding-balance = true;
        window-save-state = "always"; # deterministic relaunch

        # Low motion: no blinking cursor, no resize overlay flash, instant quick
        # terminal.
        cursor-style = "block";
        cursor-style-blink = false;
        resize-overlay = "never";
        quick-terminal-position = "top";
        quick-terminal-animation-duration = 0;

        mouse-hide-while-typing = true;
        macos-option-as-alt = true;

        keybind = cfg.keybinds;
      };
    };
  };
}
