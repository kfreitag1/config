{ pkgs, lib, ... }:
let
  ironbarControl = pkgs.stdenv.mkDerivation {
    pname = "ironbar-control";
    version = "0.1.0";
    src = ./ironbar-control.rs;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.rustc ];
    buildPhase = ''
      runHook preBuild
      rustc -O --edition 2021 -o ironbar-control $src
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 ironbar-control $out/bin/ironbar-control
      runHook postInstall
    '';
    meta.mainProgram = "ironbar-control";
  };

  osd = pkgs.writeShellScriptBin "osd" ''
    export PATH="${lib.makeBinPath [ pkgs.netcat-openbsd pkgs.wireplumber pkgs.brightnessctl pkgs.coreutils ]}:$PATH"
    runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    socket="$runtime/ironbar-control.sock"

    send() {
      [ -S "$socket" ] || return 0
      printf '%s\n' "$1" | timeout 1 nc -U "$socket" >/dev/null 2>&1 || true
    }

    case "''${1:-}" in
      volume-up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0
        send "osd volume"
        ;;
      volume-down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-
        send "osd volume"
        ;;
      volume-mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        send "osd volume"
        ;;
      brightness-up)
        brightnessctl set +5% >/dev/null
        send "osd brightness"
        ;;
      brightness-down)
        brightnessctl set 5%- >/dev/null
        send "osd brightness"
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ pkgs.ironbar osd ];

  systemd.user.services.ironbar = {
    description = "Ironbar";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    requisite = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.networkmanager pkgs.gawk pkgs.gnugrep pkgs.coreutils pkgs.pipewire pkgs.jq ];
    serviceConfig = {
      ExecStart = "${pkgs.ironbar}/bin/ironbar";
      Restart = "always";
      RestartSec = 2;
    };
  };

  systemd.user.services.ironbar-control = {
    description = "Ironbar control";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    requisite = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.niri ];
    serviceConfig = {
      ExecStart = lib.getExe ironbarControl;
      Restart = "always";
      RestartSec = 2;
    };
  };
}
