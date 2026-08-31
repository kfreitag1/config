{ config, pkgs, agenix, lib, ... }:

let
  # Runtime location of the compose stacks in this repo's checkout
  dockerRoot = "/home/kieran/config/hosts/homeserver/docker";

  # Stacks are discovered from the flake (store) copy of ./docker, so the
  # whole config stays pure-evaluable. Keep in mind this means a stack only
  # becomes active once its files are committed to the repo.
  dockerStacks = builtins.attrNames
    (lib.filterAttrs (name: type: type == "directory")
    (builtins.readDir ./docker));

  mkDockerComposeService = stack:
    let
      # Path type so that the compose file gets tracked in the nix store
      composeFile = ./docker + "/${stack}/docker-compose.yaml";
    in
    {
      "docker-compose-${stack}" = {
        description = "Docker Compose - ${stack}";
        after = [ "docker.service" "create-caddy-network.service" ];
        requires = [ "docker.service" "create-caddy-network.service" ];

        serviceConfig = {
          SupplementaryGroups = [ "docker" ];
          Type = "oneshot";
          RemainAfterExit = "yes";
          WorkingDirectory = "${dockerRoot}/${stack}";
          # Need to change the project dir to the current dir so it doesn't try to run in
          # the nix store where the compose files are tracked
          ExecStart = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --project-directory . up -d";
          ExecStop = "${pkgs.docker-compose}/bin/docker-compose -f ${composeFile} --project-directory . down";
        };

        wantedBy = [ "multi-user.target" ];
      };
    };
in
{
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/mnt/cache/docker";
      dns = [ "1.1.1.1" "1.0.0.1" ];
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  systemd.services = lib.mkMerge (
    (map mkDockerComposeService dockerStacks) ++ [
      {
        docker = {
          after = [ "mnt-cache.mount" ];
          requires = [ "mnt-cache.mount" ];
        };
      }
      {
        create-caddy-network = {
          description = "Create Docker network for Caddy";
          after = [ "docker.service" ];
          requires = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Skip if the network already exists
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.docker}/bin/docker network create caddy_network || true'";
          };
        };
      }
    ]
  );
}
