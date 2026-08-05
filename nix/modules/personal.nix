{ config, pkgs, ... }:
let
  repoRoot = "${config.users.users.${config.system.primaryUser}.home}/Developer/mac-configuration";
in
{
  environment.variables.MACHINE_PROFILE = "personal";

  age.secrets.openrouter-api-key = {
    file = ../secrets/openrouter-api-key.age;
    mode = "400";
    owner = "kieran";
    group = "staff";
  };

  my.profileFiles.sourceDir = ../../personal;
  my.profileFiles.linkSourceDir = "${repoRoot}/personal";

  environment.systemPackages = with pkgs; [
    # GUI Applications (Personal)
    zoom-us
    vscode

    # Utils
    erlang_28
    corepack_24

    # CLI
    neovim
    docker
    clang-tools
  ];

  homebrew = {
    enable = true;
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
      "comfyui"
      "dolphin"
      "markedit"
      "yaak"
      "qbittorrent"
      "claude-code@latest"
      "anki"
      "the-unarchiver"
      "dbeaver-community"
    ];
    brews = [
      "openfst"
      "openjdk"
      "gemini-cli"
      "lazygit"
      "lazydocker"
      "pandoc"
      "shopify-cli"
    ];
  };
}
