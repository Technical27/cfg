{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.gnome-clipboard
    gnomeExtensions.freon
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
