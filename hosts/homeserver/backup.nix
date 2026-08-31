{ config, pkgs, lib, ... }:

let
  dumpDir = "/mnt/cache/backup-dumps";

  docker = "${pkgs.docker}/bin/docker";
  gzip = "${pkgs.gzip}/bin/gzip";
  sqlite = "${pkgs.sqlite}/bin/sqlite3";

  # Produces consistent DB snapshots under ${dumpDir}
  # Uses redirect-then-gzip (not a pipe) so `set -eu` reliably catches dump
  # failures regardless of whether the runner is bash or sh
  backupPrepareCommand = ''
    set -eu
    rm -rf ${dumpDir}
    mkdir -p ${dumpDir}

    # --- PostgreSQL (immich) ---
    ${docker} exec immich_postgres pg_dumpall -U postgres --clean --if-exists > ${dumpDir}/immich-pg.sql
    ${gzip} -f ${dumpDir}/immich-pg.sql

    # --- PostgreSQL (simple-gym) ---
    ${docker} exec simple-gym-postgres-1 pg_dumpall -U gym --clean --if-exists > ${dumpDir}/simple-gym-pg.sql
    ${gzip} -f ${dumpDir}/simple-gym-pg.sql

    # --- Embedded MariaDB (uptime-kuma) ---
    ${docker} exec uptime-kuma sh -c 'mariadb-dump --socket=/app/data/run/mariadb.sock --single-transaction --databases kuma' > ${dumpDir}/uptime-kuma-mariadb.sql
    ${gzip} -f ${dumpDir}/uptime-kuma-mariadb.sql

    # --- PostgreSQL (bookorbit) ---
    ${docker} exec bookorbit-db sh -c 'pg_dumpall -U "$POSTGRES_USER" --clean --if-exists' > ${dumpDir}/bookorbit-pg.sql
    ${gzip} -f ${dumpDir}/bookorbit-pg.sql

    # --- SQLite (consistent online .backup) ---
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/paperless/data/db.sqlite3 ".backup ${dumpDir}/paperless.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/pocket-id/data/pocket-id.db ".backup ${dumpDir}/pocket-id.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/open-web-ui/data/webui.db ".backup ${dumpDir}/open-web-ui.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/hoser-shop-admin/data/sessions.sqlite ".backup ${dumpDir}/hoser-shop-sessions.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/data/jellyfin.db ".backup ${dumpDir}/jellyfin.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/arr/sonarr/config/sonarr.db ".backup ${dumpDir}/arr-sonarr.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/arr/radarr/config/radarr.db ".backup ${dumpDir}/arr-radarr.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/arr/lidarr/config/lidarr.db ".backup ${dumpDir}/arr-lidarr.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/arr/bazarr/config/db/bazarr.db ".backup ${dumpDir}/arr-bazarr.db"
    ${sqlite} /home/kieran/config/hosts/homeserver/docker/arr/prowlarr/config/prowlarr.db ".backup ${dumpDir}/arr-prowlarr.db"
  '';

  backupCleanupCommand = ''
    rm -rf ${dumpDir}
  '';
in
{
  services.restic.backups.full = {
    initialize = true;
    repository = "b2:kieran-freitag-home-server-backup:restic";
    passwordFile = "/run/agenix/restic-repo-password";
    environmentFile = "/run/agenix/restic-b2-env";
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
    paths = [ "/home/kieran/config" "/mnt/storage" dumpDir ];
    exclude = [
      # config repo
      "/home/kieran/config/.git"

      # regenerable docker app data
      "/home/kieran/config/hosts/homeserver/docker/open-web-ui/data/cache"
      "/home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/metadata"
      "/home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/data/trickplay"
      "/home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/data/subtitles"
      "/home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/log"
      "/home/kieran/config/hosts/homeserver/docker/arr/*/config/logs"
      "/home/kieran/config/hosts/homeserver/docker/arr/*/config/Backups"

      # live database data
      "/home/kieran/config/hosts/homeserver/docker/immich/postgres"
      "/home/kieran/config/hosts/homeserver/docker/simple-gym/data"
      "/home/kieran/config/hosts/homeserver/docker/uptime-kuma/data/mariadb"
      "/home/kieran/config/hosts/homeserver/docker/bookorbit/data/postgres"
      "/home/kieran/config/hosts/homeserver/docker/arr/**/*.db*"
      "/home/kieran/config/hosts/homeserver/docker/paperless/data/db.sqlite3*"
      "/home/kieran/config/hosts/homeserver/docker/pocket-id/data/pocket-id.db*"
      "/home/kieran/config/hosts/homeserver/docker/open-web-ui/data/webui.db*"
      "/home/kieran/config/hosts/homeserver/docker/hoser-shop-admin/data/sessions.sqlite*"
      "/home/kieran/config/hosts/homeserver/docker/jellyfin/jellyfin/config/data/jellyfin.db*"

      # large regenerable media
      "/mnt/storage/media/movies"
      "/mnt/storage/media/tv"
      "/mnt/storage/media/usenet"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
      "--keep-yearly 1"
    ];
    runCheck = true;
    progressFps = 1; # one progress line/sec to journald (default is silent in non-TTY)
    extraBackupArgs = [ "--tag=homeserver" ];
    inherit backupPrepareCommand backupCleanupCommand;
  };

  # Fail loudly (rather than backing up empty mountpoints) if the storage or
  # cache pools aren't mounted. The restic module already adds
  # network-online.target; list attrs merge, so this appends to `after`.
  systemd.services.restic-backups-full = {
    after = [ "mnt-storage.mount" "mnt-cache.mount" ];
    requires = [ "mnt-storage.mount" "mnt-cache.mount" ];
  };
}
