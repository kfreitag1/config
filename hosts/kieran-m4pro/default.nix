{ config, pkgs, ... }:
let
  repoRoot = "${config.users.users.${config.system.primaryUser}.home}/config";
in
{
  imports = [ ../../modules/darwin.nix ];

  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.kieran.kieran.dotfiles.overlay = {
    sourceDir = ../../dotfiles/personal;
    checkout = "${repoRoot}/dotfiles/personal";
  };

  environment.systemPackages = with pkgs; [
    zoom-us
    vscode
    beam28Packages.erlang
    corepack_24
    docker
    clang-tools
  ];

  homebrew = {
    taps = [
      {
        name = "shopify/shopify";
        trusted = true;
      }
    ];
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
    ];
    brews = [
      "openfst"
      "openjdk"
      "lazygit"
      "lazydocker"
      "pandoc"
      "shopify-cli"
    ];
  };
}
