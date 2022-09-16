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

  security.pam.services.swaylock.text = ''
    # Account management.
    account required pam_unix.so

    # Authentication management.
    auth sufficient pam_unix.so nullok likeauth try_first_pass
    auth optional ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
    auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so
    auth required pam_deny.so

    # Password management.
    password sufficient pam_unix.so nullok sha512

    # Session management.
    session required pam_env.so conffile=/etc/pam/environment readenv=0
    session required pam_unix.so
  '';

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
  };
}
