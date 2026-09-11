{ config, pkgs, lib, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";
in
{
  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.${config.kieran.primaryUser}.kieran.dotfiles.overlays = [
    {
      sourceDir = ../../dotfiles/personal;
      checkout = "${repoRoot}/dotfiles/personal";
    }
  ];

  # Wifi
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  services.tailscale = {
    enable = true;
  };

  services.openssh.enable = true;

  # Niri + graphics config
  programs.niri.enable = true;
  security.polkit.enable = true;
  hardware.apple-t2.enableIGPU = true;

  environment.etc."niri/default-config.kdl".source =
    "${config.programs.niri.package.src}/resources/default-config.kdl";

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };

  services.udev.extraHwdb = ''
    touchpad:usb:v05acp0340:*
     ID_INPUT_TOUCHPAD_INTEGRATION=internal
  '';

  environment.etc."libinput/local-overrides.quirks".text = ''
    [Apple Internal Trackpad (T2)]
    MatchVendor=0x05AC
    MatchProduct=0x0340
    MatchUdevType=touchpad
    AttrPalmSizeThreshold=1200
  '';

  services.libinput.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${config.programs.niri.package}/bin/niri-session";
      user = config.kieran.primaryUser;
    };
  };
  systemd.user.services.niri.enableDefaultPath = false;

  networking.hostName = "kieran-nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.${config.kieran.primaryUser} = {
    isNormalUser = true;
    description = "Kieran Freitag";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    xfsprogs
    mergerfs
    mergerfs-tools
    sqlite
    radeontop
    postgresql
    vim
    go
    pi-coding-agent
    restic
    alacritty
    fuzzel
    xwayland-satellite
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3";
  };

  boot.loader.systemd-boot.configurationLimit = 3;

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --impure --flake ~/config";
    update = "nix flake --extra-experimental-features \"nix-command flakes\" update --flake ~/config/flake.nix";
  };

  system.stateVersion = "26.11";
}
