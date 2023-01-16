device: { config, pkgs, lib, ... }:

let
  inherit (pkgs) cpkgs;
in
{
  home.packages = [ pkgs.xclip ];

  programs.rofi = {
    enable = true;
    font = "JetBrainsMono Nerd Font Mono 13";
    terminal = "kitty";
  };

  xsession.windowManager.i3 = {
    enable = true;
    extraConfig = "default_border none";
    config = {
      modifier = "Mod4";
      menu = "rofi -show drun";
      gaps.inner = 10;
      startup = [
        {
          command =
            "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY";
          notification = false;
        }
        {
          command =
            "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.i3lock}/bin/i3lock --nofork -i ~/Pictures/wallpaper.png";
          notification = false;
        }
        {
          command =
            "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ~/Pictures/wallpaper.png";
          notification = false;
        }
        {
          command = "udiskie -a -n --appindicator";
          notification = false;
        }
        {
          command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          notification = false;
        }
        {
          command = "${cpkgs.polybar}/bin/polybar main";
          notification = false;
        }
      ];
      keybindings = lib.mkOptionDefault {
        "Mod4+e" = "exec firefox";
        "Mod4+Return" = "exec kitty";

        "Mod4+j" = "focus down";
        "Mod4+k" = "focus up";
        "Mod4+h" = "focus left";
        "Mod4+l" = "focus right";

        "Mod4+v" = "split v";
        "Mod4+b" = "split h";

        "Mod4+s" = "nop";
        "Mod4+w" = "nop";

        "Mod4+Shift+j" = "move down";
        "Mod4+Shift+k" = "move up";
        "Mod4+Shift+h" = "move left";
        "Mod4+Shift+l" = "move right";

        "Mod4+Shift+r" = "exec i3-nagbar -t warning -m 'Do you really want to reboot?' -b 'Yes, reboot' 'systemctl reboot'";
      };
      modes.resize = {
        "h" = "resize shrink width 10 px";
        "j" = "resize shrink height 10 px";
        "k" = "resize grow height 10 px";
        "l" = "resize grow width 10 px";

        "Shift+h" = "resize shrink width 50 px";
        "Shift+j" = "resize shrink height 50 px";
        "Shift+k" = "resize grow height 50 px";
        "Shift+l" = "resize grow width 50 px";

        "Escape" = "mode default";
        "Return" = "mode default";
      };
      bars = [ ];
      floating.criteria = [
        { title = "^Firefox — Sharing Indicator$"; }
        { instance = "origin.exe"; }
      ];
    };
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        geometry = "0x20-10+38";
        font = "13:JetBrainsMono Nerd Font Mono";
        padding = 10;
        horizontal_padding = 10;
        frame_width = 5;
        frame_color = "#8ec07c";
        max_icon_size = 64;
      };
      urgency_normal = {
        background = "#282828";
        foreground = "#ebdbb2";
        timeout = 10;
      };
    };
  };

  services.polybar = {
    enable = true;
    package = cpkgs.polybar;
    config = {
      "bar/main" = {
        width = "100%";
        height = 30;
        radius = 0;
        modules-left = "i3 title";
        modules-right = "nixos cpu memory date";
        font-0 = "JetBrainsMono Nerd Font Mono:size=13;0";
        padding = 1;
        module-margin = 1;
        background = "#282828";
        foreground = "#ebdbb2";
        monitor = "DP-4";
        tray-position = "right";
        tray-detached = false;
        tray-padding = 3;
      };

      "module/i3" = {
        type = "internal/i3";
      };
      "module/cpu" = {
        type = "internal/cpu";
        label = "%percentage%% ";
        interval = 2;
      };
      "module/memory" = {
        type = "internal/memory";
        label = "%percentage_used%% ";
        interval = 2;
      };
      "module/date" = {
        type = "internal/date";
        time = "%I:%M %p";
        time-alt = "%Y-%m-%d";
        label = "%time%";
      };
      "module/title" = {
        type = "internal/xwindow";
        label-maxlen = 100;
      };
      # "module/nixos" = {
      #   type = "custom/script";
      #   exec = "${cpkgs.info}/bin/info --polybar";
      #   interval = 600;
      # };
    };
  };
  systemd.user.services.polybar = lib.mkForce { };
}
