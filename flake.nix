{
  description = "Ghostty terminal configuration as a home-manager module — minimal, high-contrast, low-motion, deterministic";

  # No inputs. This module is pure option plumbing on top of home-manager's own
  # `programs.ghostty` (which owns the package, the keyValue formatter and the
  # config file); the consuming configuration supplies nixpkgs and home-manager.
  # Staying input-free means adding this to a config costs no lock churn and
  # cannot drag a second nixpkgs into the closure.
  outputs = { self }: {
    homeManagerModules.default = import ./modules/ghostty.nix;
    homeManagerModules.ghostty = import ./modules/ghostty.nix;
  };
}
