device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  mkLaptop = obj: lib.mkIf isLaptop obj;
  isDesktop = device == "desktop";
  mkDesktop = obj: lib.mkIf isDesktop obj;
  inherit (pkgs) cpkgs;
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = "aamaruvi";
  home.homeDirectory = toString /home/aamaruvi;
  home.sessionVariablesExtra = ''
    export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS"
  '';
  home.sessionVariables.XDG_PICTURES_DIR = "${config.home.homeDirectory}/Pictures";

  home.packages = with pkgs; [
    ripgrep
    nerdfonts
    tldr
    imv
    tectonic
    gcc
    jq
    file
    unzip
    zip
    gh
    xdg_utils

    neovim-nightly
    killall
    nix-index
    neofetch
    bpytop
    sage

    texlive.combined.scheme-small

    noto-fonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-emoji

    discord
    gimp
    cpkgs.grapejuice
    pavucontrol

    easyeffects
    libreoffice
    openscad

    multimc
    mangohud

    # read files from phone
    libimobiledevice
    ifuse
    # get libreoffice spellchecking

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
    hunspellDicts.en-us
  ] ++ lib.optionals isLaptop [
    wireguard-tools
    cpkgs.wgvpn
    # set thermal modes
    libsmbios
    aircrack-ng

    zoom-us
    htop
    qutebrowser

    # VEX
    cpkgs.pros
    gnumake
    gcc-arm-embedded
    chromium

    # FRC
    gradle
    cpkgs.vscodium
    python3
    slack
  ] ++ lib.optionals isDesktop [
    razergenie
    virt-manager
    openrgb
    liquidctl
    obs-studio
    olive-editor
    mumble
    scrot

    lutris
    cpkgs.badlion-client
    freecad
  ];

  xdg.configFile = {
    "wofi/config" = { text = "drun-print_command=true"; };
    "wofi/style.css" = { source = ./themes/wofi/style.css; };

    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/ts.vim".source = ./nvim/ts.vim;
    "nvim/lua/lsp.lua".text = builtins.replaceStrings [
      "@RNIX_PATH@"
      "@RUST_ANALYZER_PATH@"
      "@HLS_PATH@"
      "@CLOJURE_LSP_PATH@"
      "@SVELTE_LANGUAGE_SERVER_PATH@"
      "@TSSERVER_PATH@"
      "@TYPESCIRPT_PATH@"
      "@CCLS_PATH@"
    ] [
      "${pkgs.rnix-lsp}"
      "${pkgs.rust-analyzer}"
      "${pkgs.haskell-language-server}"
      "${pkgs.clojure-lsp}"
      "${pkgs.nodePackages.svelte-language-server}"
      "${pkgs.nodePackages.typescript-language-server}"
      "${pkgs.nodePackages.typescript}"
      "${pkgs.ccls}"
    ]
      (builtins.readFile ./nvim/lsp.lua);
  };

  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.firefox = {
    enable = true;
    package =
      if isLaptop then
        (pkgs.firefox-new-bin.override {
          extraNativeMessagingHosts = [
            cpkgs.robotmeshnative
          ];
        }) else pkgs.firefox-bin;
  };

  programs.zathura = {
    enable = true;
    options = {
      font = "'JetBrains Mono NerdFont' 13";
      statusbar-home-tilde = true;
      window-title-home-tilde = true;
      completion-bg = "#282828";
      completion-fg = "#ebdbb2";
      completion-group-bg = "#282828";
      completion-group-fg = "#ebdbb2";
      completion-highlight-bg = "#ebdbb2";
      completion-highlight-fg = "#282828";
      default-bg = "#282828";
      default-fg = "#ebdbb2";
      highlight-color = "#8ec07c";
      inputbar-bg = "#282828";
      inputbar-fg = "#ebdbb2";
      statusbar-bg = "#282828";
      statusbar-fg = "#ebdbb2";
    };
  };

  programs.mako = {
    enable = true;
    borderSize = 5;
    defaultTimeout = 3000;
    textColor = "#ebdbb2";
    backgroundColor = "#282828";
    borderColor = "#8ec07c";
  };

  xsession.preferStatusNotifierItems = true;
  services.lorri.enable = true;
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

  programs.starship = {
    enable = true;
    # annoying
    settings.nix_shell.disabled = true;
  };

  programs.kitty = with import ./kitty.nix; {
    enable = true;
    inherit keybindings extraConfig;
  };

  programs.git = {
    enable = true;
    userName = "Aamaruvi Yogamani";
    userEmail = "38222826+Technical27@users.noreply.github.com";

    signing = {
      signByDefault = true;
      key = "F930CFBFF5D7FDC3";
    };

    extraConfig = {
      pull.rebase = true;
      credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";
    };

    package = pkgs.gitFull;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set TTY1 (tty)
      if test -z "$DISPLAY"; and test $TTY1 = "/dev/tty1"
        exec sway
      end

      set -g fish_color_autosuggestion '555'  'brblack'
      set -g fish_color_cancel -r
      set -g fish_color_command --bold
      set -g fish_color_comment 'brblack'
      set -g fish_color_cwd green
      set -g fish_color_cwd_root red
      set -g fish_color_end brmagenta
      set -g fish_color_error brred
      set -g fish_color_escape 'bryellow'  '--bold'
      set -g fish_color_history_current --bold
      set -g fish_color_host normal
      set -g fish_color_match --background=brblue
      set -g fish_color_normal normal
      set -g fish_color_operator bryellow
      set -g fish_color_param cyan
      set -g fish_color_quote yellow
      set -g fish_color_redirection brblue
      set -g fish_color_search_match 'bryellow'  '--background=brblack'
      set -g fish_color_selection 'white' '--bold'  '--background=brblack'
      set -g fish_color_user brgreen
      set -g fish_color_valid_path --underline

      set -g fish_cursor_insert line
      set -g fish_cursor_default block
      fish_vi_key_bindings
    '';
    shellAliases = {
      make = "make -j8";
      icat = "kitty +kitten icat";
      cat = "bat";
      grep = "rg";
    };
    functions.fish_greeting = "${cpkgs.info}/bin/info";
  };

  gtk = {
    enable = true;
    theme = {
      name = "gruvbox-dark";
      package = cpkgs.gruvbox.theme;
    };
    iconTheme = {
      name = "gruvbox-dark";
      package = cpkgs.gruvbox.icons;
    };
    gtk3.extraConfig = {
      gtk-cursor-theme-name = "WhiteSur-cursors";
      gtk-cursor-theme-size = 24;
    };
  };

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
    '';
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
                timeout 180 '${swaylock}' \
                timeout 300 'swaymsg "output * dpms off"' \
                timeout 600 'systemctl hibernate' \
                  resume 'swaymsg "output * dpms on"' \
                before-sleep 'playerctl pause' \
                before-sleep '${swaylock}'
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

  programs.rofi = mkDesktop {
    # enable = true;
    font = "JetBrainsMono Nerd Font Mono 13";
    terminal = "kitty";
  };

  xsession.windowManager.i3 = mkDesktop {
    # enable = true;
    package = pkgs.i3-gaps;
    extraConfig = "default_border none";
    config = {
      modifier = "Mod4";
      menu = "rofi -show drun";
      gaps.inner = 10;
      startup = [
        {
          command =
            "${pkgs.xss-lock}/bin/xss-lock --transfer-sleep-lock -- ${pkgs.i3lock}/bin/i3lock --nofork -i ~/Documents/wallpaper.png";
          notification = false;
        }
        {
          command =
            "${pkgs.feh}/bin/feh --no-fehbg --bg-fill ~/Documents/wallpaper.png";
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
      bars = [{ command = "${cpkgs.polybar}/bin/polybar main"; }];
      floating.criteria = [
        { title = "^Firefox — Sharing Indicator$"; }
        { instance = "origin.exe"; }
      ];
    };
  };

  services.dunst = mkDesktop {
    # enable = true;
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

  services.polybar = mkDesktop {
    # enable = true;
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
        monitor = "DP-0";
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
      "module/nixos" = {
        type = "custom/script";
        exec = "${cpkgs.info}/bin/info --polybar";
        interval = 600;
      };
    };
  };
  systemd.user.services.polybar = lib.mkForce { };

  services.mpris-proxy.enable = isLaptop;

  programs.waybar = {
    enable = true;
    style = builtins.readFile ./themes/waybar/style.css;
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

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
    config = {
      hwdec = "vaapi";
      vo = "gpu";
      gpu-context = "wayland";
    };
    bindings = {
      WHEEL_UP = "ignore";
      WHEEL_DOWN = "ignore";
    };
  };


  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage when a
  # new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";
}
