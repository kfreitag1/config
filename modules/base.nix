# Shared configuration for every machine (macOS and NixOS). Assumes the
# `age` and `home-manager` options are provided by the importing platform
# and that a `kieran` user is declared somewhere in the config
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./agenix.nix ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.kieran = {
      imports = [ ./home/common.nix ];
      kieran.dotfiles.shared.checkout = "${config.users.users.kieran.home}/config/dotfiles/base";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.variables = {
    ZDOTDIR = "$HOME/.config/zsh";
    PI_CODING_AGENT_DIR = "$HOME/.config/pi/agent";
  };

  environment.shellAliases.g = "git";

  environment.systemPackages = with pkgs; [
    neovim
    git
    tmux
    jq
    fzf
    starship
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.enableBashCompletion = true;
}
