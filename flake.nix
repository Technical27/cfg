{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-firefox.url = "github:nixos/nixpkgs/259625d3a71a1e984c744b26c4580f3df06335eb";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    cpkgs.url = "github:technical27/pkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };
  outputs = { self, nixpkgs, nixpkgs-firefox, cpkgs, nixos-hardware, home-manager, neovim-nightly-overlay }:
    let
      mkSystem = device: extraModules: (
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ nixpkgs.overlays = [ neovim-nightly-overlay.overlay ]; })
            (./. + "/${device}/hardware-configuration.nix")
            (import ./config.nix device)
            cpkgs.nixosModule
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.aamaruvi = import ./home.nix device;
            }
          ] ++ extraModules;
        }
      );
    in
    {
      nixosConfigurations.laptop = mkSystem "laptop" [
        ({ nixpkgs.overlays = [ (self: super: { firefox-new-bin = nixpkgs-firefox.legacyPackages.x86_64-linux.pkgs.firefox-beta-bin; }) ]; })
      ];
      nixosConfigurations.desktop = mkSystem "desktop" [ ];
    };
}
