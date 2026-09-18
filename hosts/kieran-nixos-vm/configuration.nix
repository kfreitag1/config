{ pkgs, ... }:
{
  networking.hostName = "kieran-nixos-vm";

  environment.systemPackages = with pkgs; [
    foot
    davfs2
  ];

  services = {
    spice-vdagentd.enable = true;
    spice-webdavd.enable = true;
    qemuGuest.enable = true;
  };

  system.stateVersion = "26.11";
}
