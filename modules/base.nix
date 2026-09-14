# Shared configuration for every machine (macOS and NixOS). Assumes the
# `age` and `home-manager` options are provided by the importing platform
# and that `kieran.primaryUser` names a user declared somewhere in the config
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./agenix.nix ];

  options.kieran.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "kieran";
    description = "Primary interactive user for this machine.";
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      users.${config.kieran.primaryUser} = {
        imports = [ ./home.nix ];
        kieran.dotfiles.shared.checkout = "${config.users.users.${config.kieran.primaryUser}.home}/config/dotfiles/base";
      };
    };

    nixpkgs.config.allowUnfree = true;

    environment.variables = {
      ZDOTDIR = "$HOME/.config/zsh";
      PI_CODING_AGENT_DIR = "$HOME/.config/pi/agent";
    };

    environment.shellAliases.g = "git";

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];

    environment.systemPackages = with pkgs; [
      neovim
      git
      delta
      tmux
      jq
      fzf
      yazi
      starship
      gh

      # External dependencies required by kickstart.nvim
      ripgrep
      fd
      lazygit
      tree-sitter
      gnumake
      gcc
      unzip
      curl
      wget

      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ] ++ lib.optionals pkgs.stdenv.isLinux [ wl-clipboard ];

    programs.zsh.enable = true;
    programs.zsh.enableCompletion = true;
    programs.zsh.enableBashCompletion = true;
  };
}
