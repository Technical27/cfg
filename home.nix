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

  imports = [ (import ./wayland/home.nix device) ];

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
    gh
    xdg_utils
    fd
    exa
    rustup
    ouch
    cpkgs.neo

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

    gimp
    cpkgs.grapejuice
    pavucontrol

    easyeffects
    cpkgs.soundux
    libreoffice
    openscad

    multimc
    mangohud

    kdenlive

    # read files from phone
    libimobiledevice
    ifuse
    # get libreoffice spellchecking

    hunspellDicts.en-us
  ] ++ lib.optionals isLaptop [
    wireguard-tools
    cpkgs.wgvpn
    # set thermal modes
    libsmbios
    aircrack-ng

    discord
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
        (pkgs.firefox.override {
          extraNativeMessagingHosts = [
            cpkgs.robotmeshnative
          ];
        }) else pkgs.firefox;
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

  xsession.preferStatusNotifierItems = true;
  services.lorri.enable = true;

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

  programs.kitty = with import ./kitty.nix; {
    enable = true;
    inherit keybindings extraConfig;
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
      ls = "exa --git --git-ignore --icons";
      tree = "exa --git --git-ignore --icons --tree";
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

  services.mpris-proxy.enable = isLaptop;

  programs.mpv = {
    enable = true;
    scripts = [ pkgs.mpvScripts.mpris ];
    config = {
      hwdec = "vaapi";
      vo = "gpu";
      gpu-context = "wayland";
      profile = "gpu-hq";
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
      keep-open = "yes";
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
