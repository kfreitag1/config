{ config, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";
in
{
  imports = [ ../../modules/darwin.nix ];

  environment.variables.MACHINE_PROFILE = "work";

  home-manager.users.${config.kieran.primaryUser}.kieran.dotfiles.overlays = [
    {
      sourceDir = ../../dotfiles/work;
      checkout = "${repoRoot}/dotfiles/work";
    }
    {
      sourceDir = ../../dotfiles/darwin;
      checkout = "${repoRoot}/dotfiles/darwin";
    }
  ];

  # nix-daemon is managed by tec, not nix-darwin
  nix.enable = false;

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
