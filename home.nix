device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  mkLaptop = obj: lib.mkIf isLaptop obj;
  isDesktop = device == "desktop";
  mkDesktop = obj: lib.mkIf isDesktop obj;
  inherit (pkgs) cpkgs;
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = "aamaruvi";
  home.homeDirectory = toString /home/aamaruvi;
  home.sessionVariablesExtra = ''
    export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS"
  '';

  home.packages = with pkgs; [
    ripgrep
    nerdfonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts
    glib
    niv
    xdg_utils
    libnotify
    tldr
    imv
    texlive.combined.scheme-small
    tectonic
    gcc
    jq
    file
    unzip
    zip

    atom

    ranger

    discord

    multimc
    lunar-client
    cpkgs.games.badlion-client

    cpkgs.games.roblox.grapejuice
    cpkgs.games.roblox.rbxfpsunlocker

    neovim-nightly
    rnix-lsp
    rust-analyzer

    mangohud
    killall
    nix-index
    neofetch
    jump
    libreoffice
    gimp
    bpytop
    pavucontrol
    pulsemixer
    pulseeffects-pw
    cadence
    openscad
    freecad

    # set thermal modes
    libsmbios

    # read files from phone
    libimobiledevice
    ifuse
    # get libreoffice spellchecking
    hunspellDicts.en-us
  ] ++ lib.optionals isLaptop [
    libsmbios
    #sway stuff
    sway-contrib.grimshot
    swaylock-effects
    swayidle
    wofi
    brightnessctl
    wl-clipboard
    zoom-us
    teams
    cpkgs.gruvbox-dark-theme
    cpkgs.gruvbox-dark-icons
    cpkgs.gruvbox-light-theme
    cpkgs.gruvbox-light-icons
  ] ++ lib.optionals isDesktop [
    lutris
    razergenie
    virt-manager
    openrgb
    liquidctl
    obs-studio
    olive-editor
    unityhub
    mumble
    libguestfs
    scrot
  ];

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    browser = [ "firefox.desktop" ];
    files = [ "ranger.desktop" ];
  in {
    "text/html" = browser;
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "x-scheme-handler/msteams" = mkLaptop "teams.desktop";
    "inode/directory" = files;
  };

  xdg.configFile = {
    "nvim/coc-settings.json".text = builtins.toJSON (import ./coc.nix pkgs);
    "kitty/gruvbox-dark.conf".source = ./themes/kitty/gruvbox-dark.conf;
    "kitty/gruvbox-light.conf".source = ./themes/kitty/gruvbox-light.conf;
    "zathura/gruvbox-dark.conf".source = ./themes/zathura/gruvbox-dark.conf;
    "zathura/gruvbox-light.conf".source = ./themes/zathura/gruvbox-light.conf;
    "bpytop/gruvbox-dark.theme".source = ./themes/bpytop/gruvbox-dark.theme;
    "bpytop/gruvbox-light.theme".source = ./themes/bpytop/gruvbox-light.theme;

    "wofi/config" = mkLaptop { text = "drun-print_command=true"; };
    "waybar/gruvbox-dark.css" = mkLaptop { source = ./themes/waybar/gruvbox-dark.css; };
    "waybar/gruvbox-light.css" = mkLaptop { source = ./themes/waybar/gruvbox-light.css; };
    "mako/gruvbox-dark.conf" = mkLaptop { source = ./themes/mako/gruvbox-dark.conf; };
    "mako/gruvbox-light.conf" = mkLaptop { source = ./themes/mako/gruvbox-light.conf; };

    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/after/ts.vim".source = ./nvim/ts.vim;
    "nvim/lua/statusline.lua".source = ./nvim/statusline.lua;
  };

  programs.neovim = {
    # enable = true;
    package = pkgs.neovim-unwrapped;
    # plugins = with pkgs.vimPlugins; [
    #   nvim-web-devicons
    #   galaxyline-nvim
    #   telescope-nvim
    #   vim-polyglot
    #   gruvbox-community
    #   undotree
    #   vim-surround
    #   vim-snippets
    #   vim-lastplace
    #   lexima-vim
    #   commentary
    #   vim-lion
    #   vim-easymotion
    #   vimtex
    #   ultisnips
    #   nvim-treesitter
    #   cpkgs.vim.telescope-coc
    #   nvim-bufferline-lua

    #   # coc extensions
    #   coc-nvim
    #   coc-json
    #   coc-css
    #   coc-html
    #   coc-snippets
    #   coc-git
    #   coc-rust-analyzer
    #   coc-prettier
    #   coc-tsserver
    #   coc-tabnine
    #   coc-eslint
    #   nvim-treesitter-context
    # ];
    withNodeJs = true;
    withPython3 = true;
    # extraConfig = builtins.readFile ./init.vim;
  };

  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.firefox = {
    enable = true;
    package = cpkgs.firefox;
  };

  programs.zathura = {
    enable = true;
    options = {
      font = "'JetBrains Mono NerdFont' 13";
      statusbar-home-tilde = true;
      window-title-home-tilde = true;
    };
    extraConfig = "include style.conf";
  };

  programs.mako = mkLaptop {
    enable = true;
    borderSize = 5;
    defaultTimeout = 10000;
    extraConfig = ''
      include=style.conf
    '';
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
            status = "enable";
            scale = 2.0;
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
            criteria = "Dell Inc. Dell S2716DG JCVN089S0K9Q";
            status = "enable";
            scale = 1.0;
            mode = "2560x1440@60Hz";
          }
        ];
      };
    };
  };

  services."${if isLaptop then "gammastep" else "redshift"}" = {
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
    shellInit = ''
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
    interactiveShellInit = "source (jump shell fish | psub)";
    shellAliases = {
      make = "make -j8";
      icat = "kitty +kitten icat";
    };
    functions.fish_greeting = "${cpkgs.tools.info}/bin/info";
  };

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-cursor-theme-name = "WhiteSur-cursors";
      gtk-cursor-theme-size = if isLaptop then 48 else 24;
    };
  };

  wayland.windowManager.sway = mkLaptop {
    enable = true;
    extraSessionCommands = ''
      export _JAVA_AWT_WM_NONREPARENTING=1
      export LIBVA_DRIVER_NAME=i965
      export MOZ_ENABLE_WAYLAND=1
      export XDG_SESSION_TYPE=wayland
      export XDG_CURRENT_DESKTOP=sway
      export QT_QPA_PLATFORM=wayland-egl
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    '';
    extraConfig = ''
      seat seat0 xcursor_theme WhiteSur-cursors 48
      default_border none
    '';
    wrapperFeatures = {
      base = true;
      gtk = true;
    };
    systemdIntegration = true;

    config = {
      output = {
        "eDP-1" = {
          scale = "2";
          subpixel = "rgb";
        };
        "*".bg = "~/Pictures/wallpaper.png fill";
      };
      input = {
        "1739:30383:DELL07E6:00_06CB:76AF_Touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
          pointer_accel = "0.3";
          dwt = "enabled";
        };
        # this will take some getting used too...
        "1:1:AT_Translated_Set_2_keyboard".xkb_options = "compose:ralt,caps:swapescape";
      };
      gaps.inner = 10;
      terminal = "kitty";
      modifier = "Mod4";
      menu = "wofi --show drun | sed 's/%.//g' | xargs swaymsg exec --";
      bars = [{ command = "${pkgs.waybar}/bin/waybar"; }];
      floating.criteria = [{ title = "^Firefox — Sharing Indicator$"; }];
      startup = let
        swaylock = "swaylock --daemonize --screenshots --indicator --clock --fade-in 0.2 --effect-blur 7x5";
      in [
        {
          command = ''
            swayidle -w \
              timeout 300 '${swaylock}' \
              timeout 600 'swaymsg "output * dpms off"' \
                resume 'swaymsg "output * dpms on"' \
              before-sleep '${swaylock}'
          '';
        }
        {
          command = "${pkgs.udiskie}/bin/udiskie -a -n --appindicator";
        }
        {
          command = "${pkgs.blueman}/bin/blueman-applet";
        }
        {
          command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        }
        {
          command = "fcitx5";
        }
        {
          command = "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS SWAYSOCK";
        }
      ];
      keybindings = let
        pmixer = str: "exec pulsemixer --max-volume 100 ${str}";
        brctl = str: "exec brightnessctl set ${str}";
      in lib.mkOptionDefault {
        "XF86AudioRaiseVolume"  = pmixer "--unmute --change-volume +10";
        "XF86AudioLowerVolume"  = pmixer "--unmute --change-volume -10";
        "XF86AudioMute"         = pmixer "--toggle-mute";

        "Mod4+s" = "nop";
        "Mod4+w" = "nop";

        "XF86MonBrightnessUp"   = brctl "10%+";
        "XF86MonBrightnessDown" = brctl "10%-";

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
    enable = true;
    font = "JetBrainsMono Nerd Font Mono 13";
    terminal = "kitty";
  };

  xsession.windowManager.i3 = mkDesktop {
    enable = true;
    package = pkgs.i3-gaps;
    extraConfig = ''
    default_border none

    workspace 1 output primary
    workspace 2 output primary
    workspace 3 output primary
    workspace 4 output primary
    workspace 5 output primary

    workspace 6 output HDMI-0
    workspace 7 output HDMI-0
    workspace 8 output HDMI-0
    workspace 9 output HDMI-0
    workspace 10 output HDMI-0
    '';
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
          command = "${pkgs.udiskie}/bin/udiskie -a -n --appindicator";
          notification = false;
        }
        {
          command = "${cpkgs.tools.polybar}/bin/polybar main";
          notification = false;
        }
        {
          command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          notification = false;
        }
        {
          command = "${pkgs.xorg.setxkbmap}/bin/setxkbmap -option 'caps:swapescape,compose:ralt'";
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
      bars = [];
      floating.criteria = [
        { title = "^Firefox — Sharing Indicator$"; }
        { instance = "origin.exe"; }
      ];
    };
  };

  services.dunst = mkDesktop {
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

  services.polybar = mkDesktop {
    enable = true;
    package = cpkgs.tools.polybar;
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
        exec = "${cpkgs.tools.info}/bin/info --polybar";
        interval = 600;
      };
    };
  };
  systemd.user.services.polybar = lib.mkForce {};

  programs.waybar = mkLaptop {
    enable = true;
    style = builtins.readFile ./themes/waybar/style.css;
    settings = [{
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "sway/workspaces" "sway/window" "sway/mode" ];
      modules-right = [ "idle_inhibitor" "custom/nixos" "network" "cpu" "memory" "temperature" "pulseaudio" "backlight" "battery" "clock" "tray" ];
      modules = {
        "sway/workspaces".disable-scroll = true;
        "sway/mode".format = "<span style=\"italic\">{}</span>";
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        tray.spacing = 10;
        clock = {
          format = "{:%I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
          interval = 2;
        };
        memory = {
          format = "{}% ";
          interval = 2;
        };
        temperature = {
          critical-threshold = 80;
          format = "{temperatureC}°C";
          interval = 5;
          # The actual cpu temperature as reported by BIOS
          hwmon-path = "/sys/class/hwmon/hwmon5/temp1_input";
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
          format-icons = [ ""  ""  ""  ""  "" ];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ifname}: {ipaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          tooltip-format-ethernet = "{ipaddr}";
          tooltip-format-wifi = "{ipaddr} {signaldBm}dBm";
          interval = 5;
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
            default = [ ""  ""  "" ];
          };
          on-click = "pavucontrol";
        };
        "custom/nixos" = {
          return-type = "json";
          interval = 600;
          exec = "${cpkgs.info}/bin/info --waybar";
        };
      };
    }];
  };


  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage when a
  # new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
