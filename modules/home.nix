# Links the dotfiles checkout into ~/.config, one symlink per file
#
# Every file under `shared` (dotfiles/base) is linked; each entry in
# `overlays` (e.g. dotfiles/personal, dotfiles/darwin) overrides files of
# the same relative path, with later entries winning.
# Symlinks point at the checkout, not the Nix store, so edits apply
# without a rebuild. Files created by applications at runtime conflict
# with a repo addition, unless listed in `force` below
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

  # Configs that apps rewrite while running; replace on activation instead of aborting
  force = [
    "karabiner/karabiner.json"
    "pi/agent/settings.json"
    "sunshine/apps.json"
    "sunshine/sunshine.conf"
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
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${checkout}/${rel}";
        force = lib.elem rel force;
      };
    }) (walk srcDir ""));

  overlayLinks = lib.foldl' (acc: o: acc // links o.sourceDir o.checkout) { } cfg.overlays;
in
{
  options.kieran.dotfiles = {
    shared = {
      sourceDir = lib.mkOption {
        type = lib.types.path;
        default = ../dotfiles/base;
        description = "Store copy used to discover the shared dotfiles tree.";
      };
      checkout = lib.mkOption {
        type = lib.types.str;
        description = "Live checkout path of the shared tree (symlink targets).";
      };
    };

    overlays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          sourceDir = lib.mkOption {
            type = lib.types.path;
          };
          checkout = lib.mkOption {
            type = lib.types.str;
          };
        };
      });
      default = [ ];
      description = "Ordered per-machine overlays; later entries override earlier ones.";
    };
  };

  config = {
    home.stateVersion = "25.05";

    xdg.enable = true;
    xdg.configFile = links cfg.shared.sourceDir cfg.shared.checkout // overlayLinks;
  };
}
