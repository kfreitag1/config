{ inputs, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../modules/base.nix
    ./backup.nix
    ./configuration.nix
    ./docker.nix
    ./hardware-configuration.nix
    ./homeserver-hardware.nix
  ];

  kieran.age.secretDefaults = {
    mode = "444";
    owner = "root";
    group = "docker";
  };
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
