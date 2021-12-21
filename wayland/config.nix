{ lib, pkgs, ... }:

{
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-wlr
  ];

  programs.sway = {
    enable = true;
    # managed with home manager
    extraPackages = lib.mkForce [ ];
  };

  nixpkgs.overlays = [
    (
      self: super: {
        discord = super.discord.overrideAttrs (old: rec {
          preFixup = ''
            gappsWrapperArgs+=(
              --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
            )
          '';
        });
        vscodium = super.vscodium.overrideAttrs (old: rec {
          preFixup = old.preFixup + ''
            gappsWrapperArgs+=(
              --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland"
            )
          '';
        });
      }
    )
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
  };
}
