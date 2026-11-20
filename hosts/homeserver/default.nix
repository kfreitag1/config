{ inputs, config, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.rex.nixosModules.default
    ../../modules/base.nix
    ./backup.nix
    ./configuration.nix
    ./docker.nix
    ./hardware-configuration.nix
    ./printing.nix
    ./homeserver-hardware.nix
  ];

  kieran.age.secretDefaults = {
    mode = "444";
    owner = "root";
    group = "docker";
  };
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  home-manager.users.${config.kieran.primaryUser} = {
    kieran.dotfiles.overlays = [
      {
        sourceDir = ../../dotfiles/homeserver;
        checkout = "${repoRoot}/dotfiles/homeserver";
      }
    ];
    programs.ssh.enable = true;
    programs.rex = {
      enable = true;
      config = ../../dotfiles/base/rex/init.lua;
    };
  };
}
