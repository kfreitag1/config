{ config, pkgs, ... }:
let
  repoRoot = "${config.users.users.${config.system.primaryUser}.home}/config";
in
{
  imports = [ ../../modules/darwin.nix ];

  environment.variables.MACHINE_PROFILE = "work";

  home-manager.users.kieran.kieran.dotfiles.overlay = {
    sourceDir = ../../dotfiles/work;
    checkout = "${repoRoot}/dotfiles/work";
  };

  # nix-daemon is managed by tec, not nix-darwin
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    lazygit
  ];

  homebrew = {
    brews = [
      "yarn"
      "ykman"
      "docker"
      "colima"
      "docker-compose"
      "ruby"
      "pnpm"
      "redis"
    ];
    casks = [
      "google-cloud-sdk"
      "proxyman"
      "keycastr"
      "redisinsight"
    ];
  };
}
