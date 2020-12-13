device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  mkLaptop = obj: lib.mkIf isLaptop obj;
  isDesktop = device == "desktop";
  inherit (pkgs) cpkgs;
  # cpkgs = import <custom-pkgs> {};
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.username = "aamaruvi";
  home.homeDirectory = toString /home/aamaruvi;

  home.packages = with pkgs; let
    JBMono = nerdfonts.override { fonts = ["JetBrainsMono"]; };
  in [
    ripgrep
    JBMono
    niv
    nodejs
    xdg_utils
    libnotify
    tldr
    imv

    ranger

    discord
    multimc
    killall
    nix-index
    neofetch
    steam
    jump
    libreoffice
    gimp
    bpytop
    # get libreoffice spellchecking
    hunspellDicts.en-us
  ] ++ lib.optionals isLaptop [
    #sway stuff
    sway-contrib.grimshot
    wofi
    brightnessctl
    pavucontrol
    wl-clipboard
    zoom-us
    teams
  ] ++ lib.optionals isDesktop [
    lutris
    razergenie
    virt-manager
    openrgb
    liquidctl
    obs-studio
    olive-editor
  ];

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications =
    let
      browser = [ "firefox.desktop" ];
      files = [ "ranger.desktop" ];
    in {
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/msteams" = "teams.desktop";
      "inode/directory" = files;
    };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-devicons
      fzf-vim
      vim-polyglot
      gruvbox-community
      undotree
      vim-fugitive
      vim-snippets
      vim-lastplace
      vim-sensible
      lexima-vim
      vim-move
      commentary
      vim-lion
      conjure
      cpkgs.context-vim
      vim-easymotion

      # coc extensions
      coc-nvim
      coc-fzf
      coc-json
      coc-css
      coc-html
      coc-lists
      coc-snippets
      coc-git
      coc-rust-analyzer
      coc-prettier
      coc-tsserver
      coc-tabnine
      coc-eslint
    ];
    withNodeJs = true;
    withPython3 = true;
    extraConfig = import ./nvim.nix;
  };

  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.firefox = {
    enable = true;
    package = cpkgs.firefox-with-extensions;
  };

  programs.zathura = {
    enable = true;
    options = {
      font = "'JetBrains Mono NerdFont' 13";
      default-bg = "#282828";
      statusbar-bg = "#282828";
      statusbar-fg = "#ebdbb2";
      statusbar-home-tilde = true;
      window-title-home-tilde = true;
    };
  };

  programs.mako = mkLaptop {
    enable = true;
    textColor = "#ebdbb2";
    backgroundColor = "#282828";
    borderSize = 5;
    borderColor = "#8ec07c";
    defaultTimeout = 10000;
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

  services.gammastep = mkLaptop {
    enable = true;
    latitude = "33.748";
    longitude = "-84.387";
    temperature.night = 4500;
  };

  programs.starship = {
    enable = true;
    settings = {
      # annoying
      nix_shell.disabled = true;
      # very slow
      haskell.disabled = true;
    };
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
      credential.helper = "/home/aamaruvi/.nix-profile/bin/git-credential-libsecret";
    };

    package = pkgs.gitFull;
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set XDG_DATA_DIRS "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS"

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

      fish_vi_key_bindings
    '';
    interactiveShellInit = "source (jump shell fish | psub)";
    shellAliases = {
      make = "make -j8";
      icat = "kitty +kitten icat";
    };
    functions.fish_greeting = "node ~/git/info/index.js";
  };

  gtk = mkLaptop {
    enable = true;
    iconTheme = { name = "gruvbox-dark"; package = cpkgs.gruvbox-icons; };
    # cursorTheme = { name = "WhiteSur-cursors"; package = null; };
    theme = { name = "gruvbox-dark"; package = cpkgs.gruvbox-gtk; };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = "1";
    };
  };

  wayland.windowManager.sway = mkLaptop {
    package = lib.mkForce null;
    enable = true;
    extraConfig = ''
      seat seat0 xcursor_theme WhiteSur-cursors 48
      default_border none
      for_window [title="^Firefox — Sharing Indicator$"] floating enable
    '';
    wrapperFeatures.gtk = true;
    systemdIntegration = false;

    config = {
      output."eDP-1" = {
        scale = "2";
        bg = "~/Pictures/wallpaper.png fill";
      };
      input."1739:30383:DELL07E6:00_06CB:76AF_Touchpad" = {
        tap = "enabled";
        natural_scroll = "enabled";
        pointer_accel = "0.3";
        dwt = "disabled";
      };
      gaps.inner = 10;
      terminal = "kitty";
      modifier = "Mod4";
      menu = "wofi --show drun | sed 's/%.//g' | xargs swaymsg exec --";
      bars = [{ command = "${pkgs.waybar}/bin/waybar"; }];
      startup = let
        swayidle = "${pkgs.swayidle}/bin/swayidle";
        swaylock = "${pkgs.swaylock-effects}/bin/swaylock --daemonize --screenshots --clock --fade-in 0.2 --effect-blur 7x5";
      in [
        {
          command = ''
            ${swayidle} -w \
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
          command = "blueman-applet";
        }
      ];
      keybindings = let
        amixer = "exec amixer -q set Master";
        brctl = "exec brightnessctl set";
      in lib.mkOptionDefault {
        "XF86AudioRaiseVolume"  = "${amixer} 10%+ unmute";
        "XF86AudioLowerVolume"  = "${amixer} 10%- unmute";
        "XF86AudioMute"         = "${amixer} toggle";

        "XF86MonBrightnessUp"   = "${brctl} 10%+";
        "XF86MonBrightnessDown" = "${brctl} 10%-";

        "Mod4+e" = "exec firefox";
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
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage when a
  # new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
