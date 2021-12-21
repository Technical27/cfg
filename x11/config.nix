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
    "X11/xorg.conf.d/50-mouse-accel.conf".source = ../desktop/50-mouse-accel.conf;
    "X11/xorg.conf.d/90-kbd.conf".source = ../desktop/90-kbd.conf;
  };

  services.picom = {
    enable = true;
    backend = "glx";
    experimentalBackends = true;
    settings = {
      unredir-if-possible = false;
      xrender-sync-fence = true;
    };
  };
}
