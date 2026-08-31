# Kieran's config

Dotfiles + Nix configuration for all machines, managed with [nix flakes](https://zero-to-nix.com/concepts/flakes), [nix-darwin](https://github.com/nix-darwin/nix-darwin), [NixOS](https://nixos.org/), [home-manager](https://nix-community.github.io/home-manager/), and [agenix](https://github.com/ryantm/agenix)

## Usage

Install nix https://nixos.org/download/

Install homebrew https://brew.sh/

Clone repo to `~/config`

macOS:

```bash
sudo nix run --extra-experimental-features "nix-command flakes" nix-darwin/master#darwin-rebuild -- switch --flake ~/config
```

nixOS home server:

```bash
sudo nixos-rebuild switch --flake ~/config
```

Subsequent rebuilds with

```bash
rebuild
```
