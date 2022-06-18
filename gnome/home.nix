device: { config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    wl-clipboard
    gnome.gnome-tweaks
  ];

  programs.mpv.config.gpu-context = "wayland";
}
