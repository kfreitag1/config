{ pkgs, ... }:
{
  networking.hostName = "kieran-nixos-t2";

  hardware.firmware = [
    (pkgs.stdenvNoCC.mkDerivation (final: {
      name = "brcm-firmware";
      src = ./firmware.tar;

      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/lib/firmware/brcm
        tar -xf ${final.src} -C $out/lib/firmware/brcm
      '';
    }))
  ];

  systemd.services.brcmfmac-suspend = {
    description = "Reload brcmfmac around suspend";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.kmod}/bin/rmmod brcmfmac_wcc 2>/dev/null || true
      ${pkgs.kmod}/bin/rmmod brcmfmac 2>/dev/null || true
    '';
    preStop = ''
      ${pkgs.kmod}/bin/modprobe brcmfmac
    '';
  };

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  hardware.apple-t2.enableIGPU = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  services.udev.extraHwdb = ''
    touchpad:usb:v05acp0280:*
     ID_INPUT_TOUCHPAD_INTEGRATION=internal
  '';

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Apple Internal Trackpad (T2)]
    MatchVendor=0x05AC
    MatchProduct=0x0280
    MatchUdevType=touchpad
    AttrPalmSizeThreshold=1200
  '';

  system.stateVersion = "26.11";
}
