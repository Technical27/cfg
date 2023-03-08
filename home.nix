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

  imports = [ (import (if isLaptop then ./wayland/home.nix else ./x11/home.nix) device) ];

  home.username = "aamaruvi";
  home.homeDirectory = toString /home/aamaruvi;
  xdg.userDirs.enable = true;

  xdg.systemDirs.data = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    # TODO: remove when gtk3 gets an update
    "${config.home.homeDirectory}/.local/share"
  ];

  home.packages = with pkgs; [
    ripgrep
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    tldr
    imv
    tectonic

    gcc
    pwndbg
    radare2
    ghidra
    patchelf
    wireshark
    binutils
    virtualenv
    python3Packages.ipython
    python3
    # sageWithDoc
    rustup
    zig
    (lib.setPrio (20) llvmPackages.bintools)
    nodejs
    yarn

    jq
    file
    gh
    xdg-utils
    fd
    exa
    zip
    unzip
    p7zip
    neo
    qmk
    bitwarden-cli
    ffmpeg

    # neovim-nightly
    neovim
    killall
    nix-index
    nurl
    neofetch
    btop

    texlive.combined.scheme-full

    ffmpeg
    hexyl

    noto-fonts
    noto-fonts-extra
    noto-fonts-cjk
    noto-fonts-emoji

    gimp
    grapejuice
    pavucontrol
    discord

    easyeffects
    # cpkgs.soundux
    libreoffice
    openscad

    mangohud

    kdenlive
    # cpkgs.olive
    prismlauncher

    cpkgs.n-link

    # read files from phone
    libimobiledevice
    ifuse
    # get libreoffice spellchecking

    hunspellDicts.en-us
    hashcat
    wireguard-tools
    yt-dlp
    transmission-gtk
    ncdu
    lm_sensors
    gnome.zenity
    gnome.simple-scan

    google-cloud-sdk
    rcon
    lynx
    chromium
    gnome.seahorse

    traceroute
    whois
    nvme-cli
    pciutils
    usbutils

    chocolateDoom
    gzdoom
    mindustry

    libqalculate
    qalculate-gtk

    ranger

    # NOTE: broken again
    # freecad
  ] ++ lib.optionals isLaptop [
    cpkgs.wgvpn
    intel-gpu-tools
    powertop

    aircrack-ng
    iw
    hcxdumptool
    hcxtools
    tcpdump
    metasploit

    gnumake

    gradle
  ] ++ lib.optionals isDesktop [
    razergenie
    openrgb
    liquidctl
    obs-studio
    mumble
    scrot

    lutris
    # cpkgs.badlion-client
  ];

  # xdg.dataFile."fusion360/wine" = {
  #   source = "${cpkgs.fusion360-wine}/bin/wine";
  #   executable = true;
  # };

  xdg.configFile = {
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/lua/config/statusline.lua".source = ./nvim/statusline.lua;
    "nvim/lua/config/bufferline.lua".source = ./nvim/bufferline.lua;
    "nvim/lua/config/cmp.lua".source = ./nvim/cmp.lua;
    "nvim/ts.vim".source = ./nvim/ts.vim;
    "nvim/after/ftplugin/tex.lua".source = ./nvim/tex.lua;
    "nvim/lua/config/lsp.lua".text = builtins.replaceStrings [
      "@RNIX_PATH@"
      "@RUST_ANALYZER_PATH@"
      "@HLS_PATH@"
      "@CLOJURE_LSP_PATH@"
      "@SVELTE_LANGUAGE_SERVER_PATH@"
      "@TSSERVER_PATH@"
      "@TYPESCRIPT_PATH@"
      "@CCLS_PATH@"
      "@PYLSP_PATH@"
    ] [
      "${pkgs.rnix-lsp}"
      "${pkgs.rust-analyzer}"
      "${pkgs.haskell-language-server}"
      "${pkgs.clojure-lsp}"
      "${pkgs.nodePackages.svelte-language-server}"
      "${pkgs.nodePackages.typescript-language-server}"
      "${pkgs.nodePackages.typescript}"
      "${pkgs.ccls}"
      "${pkgs.python3Packages.python-lsp-server}"
    ]
      (builtins.readFile ./nvim/lsp.lua);
  };

  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-nightly;
  };

  programs.neomutt.enable = true;

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

  xsession.preferStatusNotifierItems = true;
  services.lorri.enable = true;
  services.poweralertd.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      # annoying
      nix_shell.disabled = true;

      # symbols
      conda.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      git_branch.symbol = " ";
      golang.symbol = " ";
      hg_branch.symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      memory_usage.symbol = " ";
      nim.symbol = " ";
      package.symbol = " ";
      python.symbol = " ";
      ruby.symbol = " ";
      rust.symbol = " ";
      scala.symbol = " ";
      shlvl.symbol = " ";
    };
  };

  programs.kitty = {
    enable = true;

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
    };

    extraConfig = ''
      font_size 13.0
      disable_ligatures cursor
      cursor_blink_interval 0
      enable_audio_bell no
      shell_integration enabled
      confirm_os_window_close -1
      wayland_titlebar_color background

      ${import ./themes/kitty.nix}
    '';
  };

  programs.git =
    let
      package = pkgs.gitFull;
    in
    {
      enable = true;
      userName = "Aamaruvi Yogamani";
      userEmail = "38222826+Technical27@users.noreply.github.com";

      signing = {
        signByDefault = true;
        key = "F930CFBFF5D7FDC3";
      };

      extraConfig = {
        pull.rebase = true;
        credential.helper = "${package}/bin/git-credential-libsecret";
      };

      inherit package;
    };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      if set -q KITTY_INSTALLATION_DIR
        set --global KITTY_SHELL_INTEGRATION enabled
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
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
      set -ag fish_user_paths '${config.home.homeDirectory}/.cargo/bin'

      set -g fish_cursor_insert line
      set -g fish_cursor_default block
      fish_vi_key_bindings
    ''
    + (if config.wayland.windowManager.sway.enable then ''
      if test -z "$WAYLAND_DISPLAY"; and test (tty) = "/dev/tty1"
        exec sway
      end
    '' else "")
    ;

    shellAliases = {
      make = "make -j8";
      icat = "kitty +kitten icat";
      cat = "bat";
      grep = "rg";
      ls = "exa --git --icons";
      tree = "exa --git --icons --tree";
    };

    functions.fish_title.body = ''
      set -q argv[1]; or set argv fish
      set -l realhome ~
      set -l dir (string replace -r '^'"$realhome"'($|/)' '~$1' $PWD)
      echo "$dir: $argv"
    '';
  };

  gtk = {
    enable = true;
    theme = {
      name = "Fluent";
      package = pkgs.fluent-gtk-theme;
    };
    iconTheme = {
      name = "Fluent-dark";
      package = pkgs.fluent-icon-theme;
    };
    cursorTheme = {
      name = "WhiteSur-cursors";
      size = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  services.mpris-proxy.enable = isLaptop;

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [ mpris ];
    config = {
      hwdec = if isLaptop then "vaapi" else "nvdec";
      vo = "gpu";
      profile = "gpu-hq";
      fullscreen = "yes";
      video-sync = "display-resample-vdrop";
      save-position-on-quit = "yes";
      scale = mkDesktop "ewa_lanczossharp";
      cscale = mkDesktop "ewa_lanczossharp";
      ytdl-format = "bestvideo[height<=?${if isLaptop then "1440" else "2160"}]+bestaudio/best";
    };
    bindings = mkLaptop {
      WHEEL_UP = "ignore";
      WHEEL_DOWN = "ignore";
      WHEEL_LEFT = "ignore";
      WHEEL_RIGHT = "ignore";
      "=" = "playlist-next";
      "-" = "playlist-prev";
      HOME = "seek 0 absolute-percent";
      END = "seek 100 absolute-percent";
    };
    profiles."music" = {
      profile-cond = "string.match(path, 'Music/') ~= nil or string.match(working_directory, '/home/aamaruvi/Music') ~= nil";
      save-position-on-quit = "no";
      resume-playback = "no";
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
