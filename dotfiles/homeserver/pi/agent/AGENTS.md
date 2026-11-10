# You are on the homeserver

This is a live production NixOS server serving Kieran's household (media, photos, smart home). Treat it carefully: no destructive commands, service restarts, or config changes without explicit confirmation.

## Machine

- Host: `homeserver`, x86_64-linux, flake output `nixosConfigurations.homeserver` backed by `hosts/homeserver/`
- AMD Ryzen 7 8745HS (8c/16t), 64 GB RAM
- 120 GB NVMe for the OS, 960 GB SATA SSD at `/mnt/cache` (xfs, also the Docker data-root), 12 TB HDD at `/mnt/disk1` merged into `/mnt/storage` by mergerfs
- LAN IP 192.168.1.100 on `enp3s0`, Tailscale IP 100.111.101.127, timezone America/Vancouver, primary user `kieran`
- Rebuild with `rebuild` (`sudo nixos-rebuild switch --impure --flake ~/config`); bump inputs with `nix flake update`

## Services

- ~30 Docker Compose stacks under `hosts/homeserver/docker/<stack>/`, each run as a systemd unit `docker-compose-<stack>` (see `docker.nix`)
- Compose files are discovered from the flake (store) copy, so a new stack only activates after its files are committed
- All containers join the `caddy_network`; caddy reverse-proxies everything and `caddy-reload` reloads its config
- Major stacks: immich, jellyfin, paperless, home-assistant, karakeep, arr stack (sonarr/radarr/bazarr/prowlarr/sabnzbd/seerr), uptime-kuma, pocket-id, open-web-ui, bookorbit, norish, simple-gym, audiobookshelf
- Samba (`rhodhouse-server`) shares `/mnt/storage` (`storage`) and Time Machine backups; printing is set up via `printing.nix`

## State and backups

- Live app data sits inside the repo checkout under `hosts/homeserver/docker/<stack>/data`; these directories contain live databases (SQLite/Postgres/MariaDB) — never delete or reset them
- Some live data files are git-tracked (e.g. `docker/audiobookshelf/config/absdatabase.sqlite` shows as modified); leave them alone
- Restic backs up nightly at 03:00 to Backblaze B2 (`restic-backups-full`, config in `backup.nix`). It first dumps all databases to `/mnt/cache/backup-dumps`; when adding a stack with a database, add a dump and exclusion to `backup.nix`
- Backups require `/mnt/storage` and `/mnt/cache` to be mounted and fail loudly otherwise

## Secrets

- agenix secrets in `secrets/`, declared in `secrets/secrets.nix`; decrypted with the host key `/etc/ssh/ssh_host_ed25519_key`, which must be listed for this host in `secrets/secrets.nix`
