let
  hostKeys = {
    kieran-m4pro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQzXCHZhk/rHUSLI8+E5lNM3O1ZoZWUjyOPZG7Ivb5u kieran@Mac-2.lan";
    kieran-work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKH56JrMAb3Tke2I1Oj1trLEnKwhb4IZDg6eClVQ3NyQ kieran@kieran-work.lan";
    homeserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcM3fGjT0HJ2ApA0m/6oyFJV9HBJk/9JzhB3P0IVdOu root@homeserver";
  };

  all = [ "kieran-m4pro" "kieran-work" "homeserver" ];
  personal = [ "kieran-m4pro" "homeserver" ];

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
    "paseo-password" = personal;
    "hoser-shop-api-secret" = personal;
    "open-webui-oidc-client-secret" = personal;
    "restic-b2-env" = personal;
    "restic-repo-password" = personal;
  };
in
builtins.mapAttrs (_: hosts: {
  inherit hosts;
  publicKeys = map (h: hostKeys.${h}) hosts;
}) secretHosts
