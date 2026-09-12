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

  swaybgBackdrop = pkgs.swaybg.overrideAttrs (prev: {
    pname = "swaybg-backdrop";
    postPatch = ''
      substituteInPlace main.c --replace-fail '"wallpaper"' '"wallpaper-backdrop"'
    '';
  });

  blurredWallpaper = pkgs.runCommand "cat_wallpaper-blur.png" {
    nativeBuildInputs = [ pkgs.ffmpeg-headless ];
  } ''
    ffmpeg -hide_banner -loglevel error -y -i ${../../dotfiles/base/wallpapers/cat_wallpaper.png} -vf gblur=sigma=40 -frames:v 1 $out
  '';
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

  programs.hyprlock.enable = true;

  systemd.user.services.hypridle.path = lib.mkForce [
    pkgs.niri
    config.programs.hyprlock.package
    pkgs.procps
  ];

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

  systemd.user.services.swaybg-backdrop = {
    description = "Blurred wallpaper for the niri overview backdrop";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${swaybgBackdrop}/bin/swaybg -m fill -i ${blurredWallpaper}";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  services.logind.settings.Login.HandlePowerKey = "ignore";

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

  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
  };

  security.polkit.enable = true;
  hardware.apple-t2.enableIGPU = true;

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
    useTextGreeter = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
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
