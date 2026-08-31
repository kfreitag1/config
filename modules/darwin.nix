# Shared macOS configuration
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./base.nix
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
  ];

  environment.shellAliases.rebuild = "sudo -E darwin-rebuild switch --flake ~/config";

  kieran.age.secretDefaults = {
    mode = "400";
    owner = "kieran";
    group = "staff";
  };
  age.identityPaths = [ "/Users/kieran/.ssh/id_ed25519" ];

  system.activationScripts.postActivation.text = ''
    if [ -r ${config.age.secrets.github-token.path} ]; then
      ( umask 077
        printf 'access-tokens = github.com=%s\n' \
          "$(cat ${config.age.secrets.github-token.path})" > /etc/nix/access-tokens.conf )
    fi
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    nodejs_24
    go
    rustup
    gh
    uv
    bun
  ];

  homebrew = {
    enable = true;
    taps = [ ];
    casks = [
      "karabiner-elements"
      "rectangle-pro"
      "ghostty"
      "zed"
      "obsidian"
      "monitorcontrol"
      "lm-studio"
      "1password"
    ];
    brews = [
      "agent-browser"
      "chrome-devtools-mcp"
      "opencode"
      "pi-coding-agent"
      "skills"
      "herdr"
      "git-delta"
      "tree-sitter-cli"
      "ripgrep"
      "fd"
      "restic"
    ];
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.extraFlags = [ "--force-cleanup" ];
  };

  system.defaults = {
    trackpad.FirstClickThreshold = 0;
    dock.showhidden = true;
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.autohide-time-modifier = 0.3;
    dock.show-recents = false;
    loginwindow.GuestEnabled = false;
    finder.FXPreferredViewStyle = "clmv";
    finder.ShowPathbar = true;
    finder._FXSortFoldersFirst = true;
    finder._FXShowPosixPathInTitle = true;
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder.ShowStatusBar = true;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
    NSGlobalDomain.InitialKeyRepeat = 10;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
    NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
    NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
    NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
    NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    screencapture.location = "~/Desktop";
    WindowManager.EnableStandardClickToShowDesktop = false;
    WindowManager.EnableTiledWindowMargins = false;
    WindowManager.EnableTilingByEdgeDrag = false;
    WindowManager.EnableTilingOptionAccelerator = false;
    CustomUserPreferences = {
      "com.apple.Finder" = {
        WarnOnEmptyTrash = false;
      };
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
      "com.apple.screencapture" = {
        location = "~/Desktop";
        type = "png";
      };
      "com.apple.screensaver" = {
        askForPassword = 1;
        askForPasswordDelay = 0;
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = true;
      };
      "com.apple.ImageCapture".disableHotPlug = true;
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
      };
      "com.apple.TextEdit" = {
        CheckSpellingWhileTyping = 0;
        CorrectSpellingAutomatically = 0;
        RichText = 0;
      };
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  system.stateVersion = 6;
  system.primaryUser = "kieran";
  users.users.kieran = {
    name = "kieran";
    home = "/Users/kieran";
  };
}
