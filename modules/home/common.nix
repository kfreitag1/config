# Links the dotfiles checkout into ~/.config, one symlink per file
#
# Every file under `shared` (dotfiles/base) is linked; `overlay` (when set,
# e.g. dotfiles/personal) overrides files of the same relative path.
# Symlinks point at the checkout, not the Nix store, so edits apply
# without a rebuild. Files created by applications at runtime are
# untouched, and conflict with a later repo addition (by design)
{
  config,
  lib,
  ...
}:

let
  cfg = config.kieran.dotfiles;

  ignore = [
    ".DS_Store"
    ".gitignore"
    "result"
  ];

  # Relative paths of all files under `dir` (readDir runs on the flake's
  # store copy, keeping evaluation pure)
  walk =
    dir: prefix:
    lib.concatLists (
      lib.mapAttrsToList
        (name: type:
          let
            rel = if prefix == "" then name else "${prefix}/${name}";
          in
          if lib.elem name ignore then
            [ ]
          else if type == "directory" then
            walk (dir + "/${name}") rel
          else
            [ rel ]
        )
        (builtins.readDir dir)
    );

  links = srcDir: checkout:
    lib.listToAttrs (map (rel: {
      name = rel;
      value.source = config.lib.file.mkOutOfStoreSymlink "${checkout}/${rel}";
    }) (walk srcDir ""));
in
{
  options.kieran.dotfiles = {
    shared = {
      sourceDir = lib.mkOption {
        type = lib.types.path;
        default = ../../dotfiles/base;
        description = "Store copy used to discover the shared dotfiles tree.";
      };
      checkout = lib.mkOption {
        type = lib.types.str;
        description = "Live checkout path of the shared tree (symlink targets).";
      };
    };

    overlay = {
      sourceDir = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
      };
      checkout = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = "Per-machine overlay; files override shared ones.";
      };
    };
  };

  config = {
    home.stateVersion = "25.05";

    xdg.enable = true;
    xdg.configFile =
      links cfg.shared.sourceDir cfg.shared.checkout
      // lib.optionalAttrs (cfg.overlay.sourceDir != null) (
        links cfg.overlay.sourceDir cfg.overlay.checkout
      );
  };
}
