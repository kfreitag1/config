let
  hostKeys = {
    kieran-m4pro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQzXCHZhk/rHUSLI8+E5lNM3O1ZoZWUjyOPZG7Ivb5u kieran@Mac-2.lan";
    kieran-nixos-t2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfcv3tXDczgQ9+uWF2cHpIGEhkiYfJGzdH8O+W/EspV kieran@kieran-nixos";
    kieran-nixos-vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQzXCHZhk/rHUSLI8+E5lNM3O1ZoZWUjyOPZG7Ivb5u kieran@Mac-2.lan";
    kieran-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKH56JrMAb3Tke2I1Oj1trLEnKwhb4IZDg6eClVQ3NyQ kieran@kieran-work.lan";
    homeserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcM3fGjT0HJ2ApA0m/6oyFJV9HBJk/9JzhB3P0IVdOu root@homeserver";
  };

  personal = [ "kieran-m4pro" "kieran-nixos-t2" "kieran-nixos-vm" "homeserver" ];
  all = [ "kieran-work" ] ++ personal;

  secretHosts = {
    "github-token" = all;
    "openrouter-api-key" = personal;

    "cloudflare-api-key" = personal;
    "pocket-id-encryption-key" = personal;
    "actual-budget-oidc-client-secret" = personal;
    "admin-apps-oidc-client-secret" = personal;
    "immich-db-pass" = personal;
    "simple-gym-pass" = personal;
    "simple-gym-oidc-client-secret" = personal;
    "paperless-oidc-client-secret" = personal;
    "profilarr-oidc-client-secret" = personal;
    "paseo-password" = personal;
    "hoser-shop-api-secret" = personal;
    "open-webui-oidc-client-secret" = personal;
    "restic-b2-env" = personal;
    "restic-repo-password" = personal;
  };
in
builtins.listToAttrs (map (name: {
  name = "${name}.age";
  value = {
    hosts = secretHosts.${name};
    publicKeys = map (h: hostKeys.${h}) secretHosts.${name};
  };
}) (builtins.attrNames secretHosts))
