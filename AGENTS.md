# config

Nix flake config for Kieran's Macs (nix-darwin) and NixOS homeserver/personal devices

Repo must live at `~/config`

`hosts/<name>/default.nix` backs the matching flake output

`rebuild` rebuilds the current host (`--impure` on NixOS)

Dotfiles under `dotfiles/` are symlinked from the live checkout, so edits apply without a rebuild (`dotfiles/base` shared, later overlays win)

Secrets are committed age files; host keys and access are declared in `secrets/secrets.nix`

Do not write comments - no explanations, section headers, rationale, or narration in code, config, or scripts

A comment is allowed only for critical, non-obvious information that cannot be expressed in code, and must be a single line with no trailing period
