{
  description = "Kieran's machines (nix-darwin + NixOS)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, agenix, home-manager }: {
    darwinConfigurations."kieran-m4pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./hosts/kieran-m4pro ];
      specialArgs = { inherit inputs; hostName = "kieran-m4pro"; };
    };

    darwinConfigurations."kieran-work" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./hosts/kieran-work ];
      specialArgs = { inherit inputs; hostName = "kieran-work"; };
    };

    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/homeserver ];
      specialArgs = { inherit inputs; hostName = "homeserver"; };
    };
  };
}
