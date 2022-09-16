{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.gnome-clipboard
    gnomeExtensions.freon
    gnomeExtensions.system-action-hibernate
  ];

  services.udev.packages = [ pkgs.gnome.gnome-settings-daemon ];

  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };


  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ uniemoji m17n ];
  };

  environment.gnome.excludePackages = (with pkgs.gnome; [
    cheese # webcam tool
    gnome-terminal # terminal
    epiphany # web browser
    geary # email reader
    gnome-characters
  ]) ++ (with pkgs; [
    gnome-console
    xterm
  ]);

  programs.xwayland.enable = true;

  networking.networkmanager = {
    wifi.backend = "iwd";
    dns = "systemd-resolved";
    wifi = {
      macAddress = "stable";
      powersave = true;
    };
  };

  security.pam.services.gdm-fingerprint.text = ''
    auth     requisite      pam_nologin.so
    auth     required       pam_env.so

    auth     required       pam_succeed_if.so uid >= 1000 quiet
    auth     required       ${pkgs.fprintd}/lib/security/pam_fprintd.so
    auth     optional       ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so

    password required       ${pkgs.fprintd}/lib/security/pam_fprintd.so

    session  optional       pam_keyinit.so revoke
    session  required       pam_limits.so
    session  optional       ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so auto_start
  '';

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
}
