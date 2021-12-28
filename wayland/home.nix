device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  mkLaptop = obj: lib.mkIf isLaptop obj;
  isDesktop = device == "desktop";
  mkDesktop = obj: lib.mkIf isDesktop obj;
  inherit (pkgs) cpkgs;
in
{
  home.packages = with pkgs; [
    #sway stuff
    sway-contrib.grimshot
    swaylock-effects
    swayidle
    wofi
    brightnessctl
    playerctl
    pulsemixer
    wl-clipboard
    clipman
  ];

  wayland.windowManager.sway = {
    enable = true;
    extraOptions = mkDesktop [ "--my-next-gpu-wont-be-nvidia" ];
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
      export QT_QPA_PLATFORM=wayland-egl
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

      export MOZ_ENABLE_WAYLAND=1
      export MOZ_USE_XINPUT2=1

      # HACK: these both literally suck and shouldn't be required
      ${if isLaptop then "export MOZ_DISABLE_RDD_SANDBOX=1" else ""}
      ${if isDesktop then "export WLR_NO_HARDWARE_CURSORS=1" else ""}
    '';
    extraConfig = ''
      seat seat0 xcursor_theme WhiteSur-cursors 24
      default_border none
    '' + (if isDesktop then
      ''workspace 1 output DP-1
        workspace 2 output DP-1
        workspace 3 output DP-1
        workspace 4 output DP-1
        workspace 5 output DP-1
        workspace 6 output HDMI-A-1 DP-1
        workspace 7 output HDMI-A-1 DP-1
        workspace 8 output HDMI-A-1 DP-1
        workspace 9 output HDMI-A-1 DP-1''
    else "");
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
    systemdIntegration = true;

    config = {
      output = {
        "eDP-1" = mkLaptop {
          mode = "2256x1504@60Hz";
          scale = "1.4";
          subpixel = "rgb";
        };
        "DP-1" = mkDesktop {
          mode = "2560x1440@144Hz";
          subpixel = "rgb";
          position = "0,0";
        };
        "HDMI-A-1" = mkDesktop {
          mode = "1366x768@60Hz";
          subpixel = "rgb";
          position = "2560,672";
        };
        "*".bg = "~/Pictures/wallpaper.png fill";
      };
      input = {
        "2362:628:PIXA3854:00_093A:0274_Touchpad" = mkLaptop {
          tap = "enabled";
          natural_scroll = "enabled";
          pointer_accel = "0.3";
          dwt = "disabled";
          events = "disabled_on_external_mouse";
        };
        "*" = {
          xkb_options = "compose:ralt,caps:swapescape";
          pointer_accel = "0";
        };
      };
      gaps.inner = 10;
      terminal = "kitty";
      modifier = "Mod4";
      menu = "wofi --show drun | sed 's/%.//g' | xargs swaymsg exec --";
      bars = [{ command = "${pkgs.waybar}/bin/waybar"; }];
      floating.criteria = [
        { title = "^Firefox — Sharing Indicator$"; }
        { instance = "origin.exe"; }
      ];
      startup =
        let
          swaylock = "swaylock --daemonize --screenshots --indicator --clock --fade-in 0.2 --effect-blur 7x5";
        in
        [
          {
            command = ''
              swayidle -w \
                timeout 180 'playerctl pause && ${swaylock}' \
                timeout 240 'swaymsg "output * dpms off"' \
                  resume 'swaymsg "output * dpms on"' \
                before-sleep 'playerctl pause && ${swaylock}'
            '';
          }
          {
            command = "${pkgs.udiskie}/bin/udiskie -a -n --appindicator";
          }
          (mkLaptop {
            command = "${pkgs.blueman}/bin/blueman-applet";
          })
          {
            command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          }
          {
            command = "fcitx5";
          }
          {
            command = "wl-paste -t text --watch clipman store --no-persist";
          }
        ];
      keybindings =
        let
          pmixer = str: "exec pulsemixer --max-volume 100 ${str}";
          brctl = str: "exec brightnessctl set ${str}";
          playerctl = str: "exec playerctl ${str}";
        in
        lib.mkOptionDefault {
          "XF86AudioRaiseVolume" = pmixer "--unmute --change-volume +10";
          "XF86AudioLowerVolume" = pmixer "--unmute --change-volume -10";

          "Shift+XF86AudioRaiseVolume" = pmixer "--unmute --change-volume +5";
          "Shift+XF86AudioLowerVolume" = pmixer "--unmute --change-volume -5";

          "XF86AudioMute" = pmixer "--toggle-mute";

          "Mod4+s" = "nop";
          "Mod4+w" = "nop";

          "XF86MonBrightnessUp" = brctl "10%+";
          "XF86MonBrightnessDown" = brctl "10%-";

          "Shift+XF86MonBrightnessUp" = brctl "5%+";
          "Shift+XF86MonBrightnessDown" = brctl "5%-";

          "XF86AudioPlay" = playerctl "play-pause";
          "XF86AudioNext" = playerctl "next";
          "XF86AudioPrev" = playerctl "previous";

          "XF86RFKill" = "rfkill toggle all";
          "Print" = "grimshot copy area";
          "Shift+Print" = "grimshot save area";

          "Mod4+e" = "exec firefox";
          "Mod4+Shift+r" = "exec swaynag -t warning -m 'Do you really want to reboot?' -b 'Yes, reboot' 'systemctl reboot'";
          "Mod4+Shift+o" = "exec swaynag -t warning -m 'Do you really want to hibernate?' -b 'Yes, hibernate' 'systemctl hibernate && pkill swaynag'";
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
    };
  };

  services.kanshi = mkLaptop {
    enable = true;
    systemdTarget = "graphical-session.target";
    profiles = {
      main = {
        outputs = [
          {
            criteria = "eDP-1";
            mode = "2256x1504@60Hz";
            status = "enable";
            scale = 1.4;
          }
        ];
      };
      monitor = {
        outputs = [
          {
            criteria = "eDP-1";
            status = "disable";
          }
          {
            criteria = "Dell Inc. Dell S2716DG #ASPkS9dwX3zd";
            status = "enable";
            scale = 1.0;
            mode = "2560x1440@144Hz";
          }
        ];
      };
    };
  };

  services.gammastep = {
    enable = true;
    latitude = "33.748";
    longitude = "-84.387";
    temperature.night = 4500;
  };

  programs.mako = {
    enable = true;
    borderSize = 5;
    defaultTimeout = 3000;
    textColor = "#ebdbb2";
    backgroundColor = "#282828";
    borderColor = "#8ec07c";
  };

  programs.waybar = {
    enable = true;
    style = builtins.readFile ../themes/waybar/style.css;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [ "sway/workspaces" "sway/window" "sway/mode" ];
        modules-right = [ "idle_inhibitor" "custom/nixos" "network" (mkLaptop "custom/vpn") "cpu" "memory" "temperature" "pulseaudio" (mkLaptop "backlight") (mkLaptop "battery") "clock" "tray" ];
        "sway/workspaces".disable-scroll = true;
        "sway/mode".format = "<span style=\"italic\">{}</span>";
        tray.spacing = 10;
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        clock = {
          format = "{:%I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
          interval = 5;
        };
        memory = {
          format = "{}% ";
          interval = 5;
        };
        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C";
          interval = 5;
          # The actual cpu temperature as reported by BIOS
          hwmon-path = "/sys/class/hwmon/hwmon${if isLaptop then "5" else "3"}/temp1_input";
        };
        backlight = {
          format = "{percent}% {icon}";
          format-icons = [ "" "" ];
        };
        battery = {
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-tooltip = "{time} {icon}";
          format-icons = [ "" "" "" "" "" ];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ifname}: {ipaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          tooltip-format-ethernet = "{ipaddr}";
          tooltip-format-wifi = "{ipaddr} {signaldBm}dBm";
          interface = mkLaptop "wlan0";
          interval = 10;
        };
        pulseaudio = {
          scroll-step = 0;
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };
        "custom/nixos" = {
          return-type = "json";
          interval = 600;
          exec = "${cpkgs.info}/bin/info --waybar";
        };
        "custom/vpn" = {
          return-type = "json";
          interval = 10;
          exec = "${cpkgs.wgvpn}/bin/wgvpn bar";
        };
      }
    ];
  };

  xdg.configFile = {
    "wofi/config" = { text = "drun-print_command=true"; };
    "wofi/style.css" = { source = ../themes/wofi/style.css; };
  };
}
