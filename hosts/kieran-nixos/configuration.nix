{ config, pkgs, lib, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";

  niriOverviewBar = pkgs.writeShellApplication {
    name = "niri-overview-bar";
    runtimeInputs = [ pkgs.niri pkgs.waybar pkgs.gnugrep ];
    text = ''
      waybar &
      waybar_pid=$!
      trap 'kill "$waybar_pid" 2>/dev/null || true' EXIT

      # Wait for waybar's layer before forwarding signals: a signal sent
      # before it installs its handlers would kill it instead.
      until niri msg --json layers | grep -q '"namespace":"waybar"'; do
        kill -0 "$waybar_pid" 2>/dev/null || exit 1
        sleep 0.1
      done

      shown=0
      while IFS= read -r line; do
        case "$line" in
          *OverviewOpenedOrClosed*'"is_open":true'*)
            kill -USR1 "$waybar_pid" || exit 1
            shown=1
            ;;
          *OverviewOpenedOrClosed*'"is_open":false'*)
            [ "$shown" = 1 ] || continue
            kill -USR2 "$waybar_pid" || exit 1
            shown=0
            ;;
        esac
      done < <(niri msg --json event-stream)
    '';
  };
in
{
  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.${config.kieran.primaryUser}.kieran.dotfiles.overlays = [
    {
      sourceDir = ../../dotfiles/personal;
      checkout = "${repoRoot}/dotfiles/personal";
    }
    {
      sourceDir = ../../dotfiles/kieran-nixos;
      checkout = "${repoRoot}/dotfiles/kieran-nixos";
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

  systemd.user.services.niri-overview-bar = {
    description = "Waybar, shown only while the niri overview is open";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    requisite = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = lib.getExe niriOverviewBar;
      Restart = "always";
      RestartSec = 2;
    };
  };

  systemd.user.services.swaybg = {
    description = "Wallpaper (swaybg)";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i %h/.config/wallpapers/cat_wallpaper.png";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  services.logind.settings.Login.HandlePowerKey = "ignore";

  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  security.pam.services.hyprlock = { };

  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
  };

  security.polkit.enable = true;
  hardware.apple-t2.enableIGPU = true;

  environment.etc."niri/default-config.kdl".source = pkgs.writeText "niri-default-config.kdl" (
    lib.replaceStrings
      [
        ''// This line starts waybar, a commonly used bar for Wayland compositors.\n''
        ''spawn-at-startup "waybar"\n''
      ]
      [ "" "" ]
      (builtins.readFile "${config.programs.niri.package.src}/resources/default-config.kdl")
  );

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };

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
    ghostty
    fuzzel
    waybar
    swaybg
    hyprlock
    nautilus
    google-chrome
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
