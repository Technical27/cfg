{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    cpkgs.url = "github:technical27/pkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    firefox-nightly.url = "github:/colemickens/flake-firefox-nightly";
  };
  outputs = { self, nixpkgs, cpkgs, nixos-hardware, home-manager, neovim-nightly-overlay, firefox-nightly }:
    let
      mkSystem = device: (
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ nixpkgs.overlays = [ neovim-nightly-overlay.overlay ]; })
            ({
              nixpkgs.overlays = [
                (self: super: {
                  firefox-nightly = firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;
                })
              ];
            })
            (./. + "/${device}/hardware-configuration.nix")
            (import ./config.nix device)
            cpkgs.nixosModule
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.aamaruvi = import ./home.nix device;
            }
          ];
        }
      );
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs [ "laptop" "desktop" ] (mkSystem);
    };
}
