{ lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
    displayManager.sddm.enable = true;
  };

  environment.etc = {
    "X11/xorg.conf.d/10-nvidia.conf".source = ../desktop/10-nvidia.conf;
    "X11/xorg.conf.d/50-mouse-accel.conf".source = ./50-mouse-accel.conf;
    "X11/xorg.conf.d/90-kbd.conf".source = ./90-kbd.conf;
  };

  environment.sessionVariables = {
    "MOZ_X11_EGL" = "1";
    "MOZ_DISABLE_RDD_SANDBOX" = "1";
    "LIBVA_DRIVER_NAME" = "nvidia";
  };

  services.picom = {
    enable = true;
    backend = "glx";
    settings = {
      vsync = true;
      refresh-rate = "144";
    };
  };

  security.pam.services = {
    sddm.enableGnomeKeyring = true;
    i3lock.enableGnomeKeyring = true;
    i3lock-color.enableGnomeKeyring = true;
    xscreensaver.enableGnomeKeyring = true;
  };
}
