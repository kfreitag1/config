{ config, pkgs, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";
in
{
  imports = [ ../../modules/darwin.nix ];

  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.${config.kieran.primaryUser}.kieran.dotfiles.overlays = [
    {
      sourceDir = ../../dotfiles/personal;
      checkout = "${repoRoot}/dotfiles/personal";
    }
    {
      sourceDir = ../../dotfiles/darwin;
      checkout = "${repoRoot}/dotfiles/darwin";
    }
  ];

  environment.systemPackages = with pkgs; [
    zoom-us
    vscode
    beam28Packages.erlang
    corepack_24
    docker
    clang-tools
  ];

  homebrew = {
    casks = [
      "google-chrome"
      "daisydisk"
      "adguard"
      "claude"
      "dolphin"
      "sf-symbols"
      "conductor"
      "tailscale-app"
      "docker-desktop"
      "blackhole-2ch"
      "whatsapp"
      "comfy"
      "dolphin"
      "markedit"
      "yaak"
      "qbittorrent"
      "anki"
      "the-unarchiver"
      "dbeaver-community"
      "utm"
    ];
    brews = [
      "openfst"
      "openjdk"
      "lazydocker"
      "pandoc"
      "pi-coding-agent"
      "shopify-cli"
    ];
  };
}
