{ config, inputs, pkgs, ... }:
let
  homeDir = config.users.users.${config.kieran.primaryUser}.home;
  repoRoot = "${homeDir}/config";
  sunshine = pkgs.callPackage ../../packages/sunshine {
    src = inputs.sunshine;
  };
in
{
  imports = [ ../../modules/darwin.nix ];

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.${config.kieran.primaryUser} = {
    kieran.dotfiles.overlays = [
      {
        sourceDir = ../../dotfiles/personal;
        checkout = "${repoRoot}/dotfiles/personal";
      }
      {
        sourceDir = ../../dotfiles/darwin;
        checkout = "${repoRoot}/dotfiles/darwin";
      }
    ];

    launchd.agents.sunshine = {
      enable = true;
      config = {
        ProgramArguments = [ "${sunshine}/bin/sunshine" ];
        RunAtLoad = true;
        KeepAlive = { SuccessfulExit = false; };
        ProcessType = "Interactive";
        LimitLoadToSessionType = "Aqua";
        WorkingDirectory = homeDir;
        StandardOutPath = "${homeDir}/Library/Logs/sunshine.log";
        StandardErrorPath = "${homeDir}/Library/Logs/sunshine.err.log";
        ThrottleInterval = 10;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    zoom-us
    vscode
    beam28Packages.erlang
    corepack_24
    docker
    clang-tools
    sunshine
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
      "betterdisplay"
    ];
    brews = [
      "openfst"
      "openjdk"
      "lazydocker"
      "pandoc"
      "pi-coding-agent"
      "shopify/shopify/shopify-cli"
      "displayplacer"
    ];
  };
}
