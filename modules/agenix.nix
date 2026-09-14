# Puts each age secret in nix as config.age.secrets.<name>
{
  lib,
  config,
  hostName,
  ...
}:

let
  secrets = import ../secrets/secrets.nix;

  mine = lib.filterAttrs (_: secret: lib.elem hostName secret.hosts) secrets;
in
{
  options.kieran.age.secretDefaults = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = ''
      Attrset merged into every materialized age secret
      (e.g. mode, owner, group)
    '';
  };

  config.age.secrets = lib.mapAttrs' (name: _:
    lib.nameValuePair (lib.removeSuffix ".age" name)
      ({ file = ../secrets/${name}; } // config.kieran.age.secretDefaults)
  ) mine;
}
