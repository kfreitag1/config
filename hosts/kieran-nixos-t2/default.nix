{ inputs, config, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../modules/base.nix
    ../../modules/nixos-desktop.nix
    ./configuration.nix
    ./hardware-configuration.nix
    "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }}/apple/t2"
  ];

  kieran.age.secretDefaults = {
    owner = config.kieran.primaryUser;
  };
}
