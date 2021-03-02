device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  isDesktop = device == "desktop";
  mkLaptop = obj: lib.mkIf (isLaptop) obj;
  mkDesktop = obj: lib.mkIf (isDesktop) obj;
  mkPatch = name: { inherit name; patch = ./desktop + "/${name}.patch"; };
in {
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    binaryCaches = let
      ip = if isLaptop then "10.200.200.1" else "192.168.1.2";
    in [
      "ssh-ng://nix-ssh@${ip}?ssh-key=/home/aamaruvi/.ssh/id_rsa"
    ];
    requireSignedBinaryCaches = false;
  };

  fileSystems = let
    default_opts = [
      "noatime"
      "nodiratime"
      "compress-force=zstd:5"
      "ssd"
      "space_cache"
      "autodefrag"
    ];
    swap_opts = [
      "noatime"
      "nodiratime"
      "ssd"
    ];
  in
  mkLaptop {
    "/".options = default_opts;
    "/nix".options = default_opts;
    "/var".options = default_opts;
    "/home".options = default_opts;
    "/swap".options = swap_opts;
  };

  swapDevices = [{ device = "/swap/file"; }];

  networking.hostName = device;

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = []
    ++ (lib.optionals isLaptop [
      "resume_offset=18382314"
    ])
    ++ (lib.optionals isDesktop [
      "intel_iommu=on"
      "kvm.ignore_msrs=1"
    ]);

  boot.kernel.sysctl = lib.recursiveUpdate
  (mkDesktop {
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
    "vm.swappiness" = 10;
  }) (mkLaptop {
    "vm.swappiness" = 60;
  });

  systemd.network.enable = true;
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
  };
  networking.dhcpcd.denyInterfaces = mkLaptop [ "wg*" "wlan*" ];
  networking.dhcpcd.enable = lib.mkForce isLaptop;

  programs.gnupg.agent.enable = true;
  programs.fish.enable = true;

  nixpkgs.config = {
    pulseaudio = true;
    allowUnfree = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; mkDesktop [
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  environment.variables = lib.recursiveUpdate
    (if isLaptop then {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      LIBVA_DRIVER_NAME = "i965";
      MOZ_ENABLE_WAYLAND = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      QT_QPA_PLATFORM = "wayland-egl";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    } else {
      MOZ_X11_EGL = "1";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    })
    ({
      EDITOR = "nvim";
      VISUAL = "nvim";
      MOZ_USE_XINPUT2 = "1";
    });

  services.gnome3.gnome-keyring.enable = true;
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    reflector = true;
  };

  services.usbmuxd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  users.extraUsers.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]
    ++ lib.optionals isDesktop [ "plugdev" ];
    shell = pkgs.fish;
  };

  system.stateVersion = "20.09";

  security.apparmor = {
    enable = true;
    profiles = import ./apparmor.nix device pkgs;
  };

  programs.dconf.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
  };
  security.pam.loginLimits = [
    {
      domain = "aamaruvi";
      item = "memlock";
      type = "hard";
      value = "128";
    }
    {
      domain = "aamaruvi";
      item = "memlock";
      type = "soft";
      value = "64";
    }
  ];
  systemd.user.services.pipewire-pulse.serviceConfig.LimitMEMLOCK = "131072";

  services.earlyoom.enable = true;

  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = [ pkgs.ibus-engines.m17n ];
  };

  # Laptop specific things
  boot.resumeDevice = mkLaptop "/dev/disk/by-uuid/4a95b4e5-a240-4754-9101-3e966627449d";
  boot.plymouth.enable = isLaptop;

  programs.sway.enable = isLaptop;

  services.upower.enable = isLaptop;
  services.tlp.enable = isLaptop;
  services.auto-cpufreq.enable = isLaptop;
  services.throttled.enable = false;
  services.blueman.enable = isLaptop;
  services.fwupd.enable = isLaptop;

  hardware.bluetooth.enable = isLaptop;
  hardware.bluetooth.hsphfpd.enable = isLaptop;

  # temp fix for bluez
  systemd.services.bluetooth.serviceConfig.ExecStart = let
    inherit (lib) optional concatStringsSep escapeShellArgs;
    cfg = config.hardware.bluetooth;
    package = cfg.package;
    hasDisabledPlugins = builtins.length cfg.disabledPlugins > 0;

    args = [ "-f" "/etc/bluetooth/main.conf" ]
      ++ optional hasDisabledPlugins
      "--noplugin=${concatStringsSep "," cfg.disabledPlugins}";
  in [
    ""
    "${package}/libexec/bluetooth/bluetoothd ${escapeShellArgs args}"
  ];

  powerManagement.enable = isLaptop;

  networking.wireless.iwd.enable = isLaptop;
  networking.hosts."10.200.200.1" = mkLaptop [ "yogs.tech" ];

  systemd.user.services.auto-theme = mkLaptop {
    description = "automatically change theme";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.nix.package}/bin/nix-shell --run 'python /home/aamaruvi/git/theme2/main.py' /home/aamaruvi/git/theme2/shell.nix";
    };
  };

  systemd.user.timers.auto-theme = mkLaptop {
    description = "automatically change theme at 12";
    timerConfig = {
      Unit = "auto-theme.service";
      OnCalendar = [ "*-*-* 18:00:00" "*-*-* 06:00:00" ];
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.user.services.mpris-proxy = mkLaptop {
    description = "bluez mpris-proxy";
    after = [ "network.target" "pipewire-pulse.socket" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };

  systemd.user.services.sway = mkLaptop {
    description = "Sway - Wayland window manager";
    documentation = [ "man:sway(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" "dbus.service" ];
    after = [ "graphical-session-pre.target" "dbus.service" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startsway
    environment.PATH = lib.mkForce null;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.sway}/bin/sway";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  services.snapper.configs = let
    timelineConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  in mkLaptop {
    home = {
      subvolume = "/home";
      extraConfig = "ALLOW_USERS=aamaruvi\n" + timelineConfig;
    };
    root = {
      subvolume = "/";
      extraConfig = timelineConfig;
    };
    var = {
      subvolume = "/var";
      extraConfig = timelineConfig;
    };
  };

  systemd.network.networks."00-wifi" = mkLaptop {
    name = "wlan0";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
    };
  };

  systemd.network.netdevs."10-wg0" = mkLaptop {
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      Description = "WireGuard Tunnel wg0";
    };
    wireguardConfig = {
      PrivateKeyFile = "/etc/wireguard/laptop.key";
      FirewallMark = 51000;
    };
    wireguardPeers = [{
      wireguardPeerConfig = {
        PublicKey = "CqrwDIxsSYFJ+xHFkDotn38wvOMC32qBpcrZHvacsF0=";
        Endpoint = "aamaruvi.ddns.net:51820";
        AllowedIPs = "0.0.0.0/0, ::/0";
      };
    }];
  };

  systemd.network.networks."20-wg0" = mkLaptop {
    name = "wg0";
    DHCP = "no";
    address = [ "10.200.200.2/32" "fd37:994c:6708:de39::2/128" ];
    dns = [ "10.200.200.1" "fd37:994c:6708:de39::1" ];
    routes = [
      {
        routeConfig = {
          Gateway = "10.200.200.1";
          Destination = "0.0.0.0/0";
          GatewayOnLink = true;
          Table = 1000;
        };
      }
      {
        routeConfig = {
          Gateway = "10.200.200.1";
          Destination = "10.200.200.0/24";
          GatewayOnLink = true;
        };
      }
      {
        routeConfig = {
          Gateway = "fd37:994c:6708:de39::1";
          Destination = "::/0";
          GatewayOnLink = true;
          Table = 1000;
        };
      }
      {
        routeConfig = {
          Gateway = "fd37:994c:6708:de39::1";
          Destination = "fd37:994c:6708:de39::/64";
          GatewayOnLink = true;
        };
      }
    ];
    networkConfig.DNSDefaultRoute = "no";
  };

  xdg.portal = mkLaptop {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };
  services.flatpak.enable = isLaptop;

  environment.systemPackages = with pkgs; mkLaptop [
    wireguard
    wireguard-tools
    polkit_gnome

    cpkgs.wgvpn
    cpkgs.startsway
  ];

  # Desktop specific things
  services.sshd.enable = isDesktop;
  services.fstrim.enable = isDesktop;
  programs.java.enable = isDesktop;
  hardware.openrazer.enable = isDesktop;

  networking.firewall.enable = isDesktop;
  systemd.network.networks."00-ethernet" = mkDesktop {
    name = "eno1";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
    };
  };

  services.xserver = mkDesktop {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
  };

  environment.etc = mkDesktop {
    "X11/xorg.conf.d/10-nvidia.conf".source = ./desktop/10-nvidia.conf;
  };

  services.picom = mkDesktop {
    enable = true;
    backend = "glx";
  };

  security.pam.services = mkDesktop {
    i3lock.enableGnomeKeyring = true;
    i3lock-color.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
    lightdm.enableGnomeKeyring = true;
  };

  virtualisation.libvirtd = mkDesktop {
    enable = true;
    qemuOvmf = true;
    qemuPackage = pkgs.qemu_kvm;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  systemd.services.libvirtd.path = with pkgs; mkDesktop [
    kmod killall bash coreutils config.boot.kernelPackages.cpupower
  ];

  boot.kernelModules = mkDesktop [ "i2c-dev" "i2c-i801" "i2c-nct6775" ];

  # boot.kernelPatches = lib.recursiveUpdate (mkDesktop [
  #   (mkPatch "openrgb")
  #   # (mkPatch "rdtsc")
  #   (mkPatch "fsync")
  # ]) (mkLaptop [{
  #   name = "fix-btusb-msbc";
  #   patch = ./laptop/bt-alt-setting-1.patch;
  # }]);
  boot.kernelPatches = mkDesktop [
    (mkPatch "openrgb")
    (mkPatch "fsync")
  ];

  systemd.user.services.rgb-restore = mkDesktop {
    description = "restore rgb effects";
    wants = [ "dbus.service" "openrazer-daemon.service" ];
    after = [ "dbus.service" "openrazer-daemon.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${config.nix.package}/bin/nix-shell --run 'python /home/aamaruvi/git/razer/main.py' /home/aamaruvi/git/razer/shell.nix"
        "${pkgs.openrgb}/bin/openrgb -d 1,2 -m breathing -c FF0000"
      ];
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      neovim-unwrapped = super.cpkgs.neovim-unwrapped;
    })
    (self: super: {
      ibus = super.ibus.override {
        inherit (super) wayland libxkbcommon;
        withWayland = true;
      };
    })
    # temp fix for waybar
    (self: super: {
      waybar = super.waybar.overrideAttrs (old: {
        patches = [ ./laptop/waybar.patch ];
      });
    })
  ] ++ lib.optionals isDesktop [
    (self: super: {
      # OVMF = super.OVMF.overrideAttrs (old: {
      #   patches = [ ./desktop/ovmf.patch ];
      # });
      # qemu_kvm = super.qemu_kvm.overrideAttrs (old: {
      #   patches = [ ./desktop/qemu.patch ] ++ old.patches;
      #   enableParallelBuilding = false;
      # });
    })
  ];

  services.udev.packages = mkDesktop [ pkgs.openrgb ];
  services.udev.extraRules = mkDesktop ''
    // The nari works with the steelseries arctis profile well
    ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051c", ENV{ACP_PROFILE_SET}="steelseries-arctis-common-usb-audio.conf"
  '';
}
