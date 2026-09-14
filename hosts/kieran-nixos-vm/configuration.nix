{ ... }:
{
  networking.hostName = "kieran-nixos-vm";

  virtualisation.rosetta.enable = true;

  services.spice-vdagentd.enable = true;

  system.stateVersion = "26.11";
}
