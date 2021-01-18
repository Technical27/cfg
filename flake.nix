{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-libvirt.url = "github:nixos/nixpkgs/066676b839a217f6b1b5d8ab05842604d33b7258";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    cpkgs.url = "github:technical27/pkgs";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = { self, nixpkgs, cpkgs, nixos-hardware, home-manager, nixpkgs-libvirt }: let
    mkSystem = device: extraModules: (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (./. + "/${device}/hardware-configuration.nix")
        (import ./config.nix device)
        cpkgs.nixosModule
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = false;
          home-manager.users.aamaruvi =
            import ./home.nix device;
        }
      ] ++ extraModules;
    });
  in {
    nixosConfigurations.laptop = mkSystem "laptop" [
      cpkgs.nixosModules.auto-cpufreq
      nixos-hardware.nixosModules.dell-xps-13-9370
    ];
    nixosConfigurations.desktop = mkSystem "desktop" [
      ({ ... }: {
        nixpkgs.overlays = [(super: self: { libvirt = nixpkgs-libvirt.legacyPackages.x86_64-linux.libvirt; })];
      })
    ];
  };
}
