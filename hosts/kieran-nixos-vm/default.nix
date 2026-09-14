{ inputs, config, ... }:
let
  user = config.kieran.primaryUser;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../modules/base.nix
    ../../modules/nixos-desktop.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];

  kieran.age.secretDefaults = {
    owner = user;
  };

  age.identityPaths = [ "/home/${user}/.ssh/id_ed25519" ];
}
