{
  inputs = {
    nixpkgs.url = "github:technical27/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    cpkgs.url = "github:technical27/pkgs";
    home-manager.url = "github:nix-community/home-manager";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixpkgs-kitty.url = "github:/nixos/nixpkgs/a0e9b56439ffd54c42f4f60466168f78fad87b7e";
    firefox-nightly.url = "github:/colemickens/flake-firefox-nightly";
  };
  outputs = { self, nixpkgs, cpkgs, nixos-hardware, home-manager, neovim-nightly-overlay, nixpkgs-kitty, firefox-nightly }:
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
            ({
              nixpkgs.overlays = [
                (self: super: {
                  # TODO: remove this later
                  kitty = nixpkgs-kitty.legacyPackages.x86_64-linux.kitty;
                  remarshal = super.remarshal.overrideAttrs (old: rec {
                    postPatch = ''
                      substituteInPlace pyproject.toml \
                        --replace "poetry.masonry.api" "poetry.core.masonry.api" \
                        --replace 'PyYAML = "^5.3"' 'PyYAML = "*"' \
                        --replace 'tomlkit = "^0.7"' 'tomlkit = "*"'
                    '';
                  });
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
