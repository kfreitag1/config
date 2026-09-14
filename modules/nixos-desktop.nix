{ config, pkgs, lib, ... }:
let
  repoRoot = "${config.users.users.${config.kieran.primaryUser}.home}/config";

  swaybgBackdrop = pkgs.swaybg.overrideAttrs (prev: {
    pname = "swaybg-backdrop";
    postPatch = ''
      substituteInPlace main.c --replace-fail '"wallpaper"' '"wallpaper-backdrop"'
    '';
  });

  blurredWallpaper = pkgs.runCommand "cat_wallpaper-blur.png" {
    nativeBuildInputs = [ pkgs.ffmpeg-headless ];
  } ''
    ffmpeg -hide_banner -loglevel error -y -i ${../dotfiles/base/wallpapers/cat_wallpaper.png} -vf gblur=sigma=40 -frames:v 1 $out
  '';
in
{
  imports = [ ./ironbar.nix ];

  environment.variables.MACHINE_PROFILE = "personal";

  home-manager.users.${config.kieran.primaryUser}.kieran.dotfiles.overlays = [
    {
      sourceDir = ../dotfiles/personal;
      checkout = "${repoRoot}/dotfiles/personal";
    }
    {
      sourceDir = ../dotfiles/nixos;
      checkout = "${repoRoot}/dotfiles/nixos";
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.configurationLimit = 3;

  services.tailscale.enable = true;
  services.openssh.enable = true;

  programs.niri.enable = true;
  programs.hyprlock.enable = true;

  systemd.user.services.hypridle.path = lib.mkForce [
    pkgs.niri
    config.programs.hyprlock.package
    pkgs.procps
  ];

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

  xdg.mime.defaultApplications = {
    "inode/directory" = "org.gnome.Nautilus.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
    "text/html" = "google-chrome.desktop";
    "application/xhtml+xml" = "google-chrome.desktop";
  };

  security.polkit.enable = true;

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main.capslock = "overload(control, esc)";
    };
  };

  services.libinput.enable = true;

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${config.programs.niri.package}/bin/niri-session";
  };
  systemd.user.services.niri.enableDefaultPath = false;

  networking.networkmanager.enable = true;
  networking.networkmanager.settings.main."hostname-mode" = "none";

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.${config.kieran.primaryUser} = {
    isNormalUser = true;
    description = "Kieran Freitag";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" ];
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
    swaybg
    brightnessctl
    nautilus
    google-chrome
    xwayland-satellite
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3";
  };

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --impure --flake ~/config";
    update = "nix flake --extra-experimental-features \"nix-command flakes\" update --flake ~/config/flake.nix";
  };
}
