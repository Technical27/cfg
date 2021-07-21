device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  isDesktop = device == "desktop";
  mkLaptop = obj: lib.mkIf (isLaptop) obj;
  mkDesktop = obj: lib.mkIf (isDesktop) obj;
  mkPatch = name: { inherit name; patch = ./desktop + "/${name}.patch"; };
in
{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    binaryCaches = [
      "ssh-ng://nix-ssh@yogs.tech?ssh-key=/home/aamaruvi/.ssh/id_rsa"
    ];
    requireSignedBinaryCaches = false;
    gc = {
      dates = "weekly";
      automatic = true;
    };
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

  swapDevices = [ { device = "/swap/file"; } ];

  networking.hostName = device;

  boot.loader.systemd-boot.enable = true;
  boot.cleanTmpDir = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = []
  ++ (
    lib.optionals isLaptop [
      "resume_offset=18382314"
      "i915.enable_guc=2"
      "mem_sleep_default=s2idle"
    ]
  );

  boot.kernel.sysctl = lib.recursiveUpdate
    (
      mkDesktop {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.ip_forward" = 1;
        "vm.swappiness" = 10;
      }
    ) (
    mkLaptop {
      "vm.swappiness" = 60;
    }
  );

  systemd.network.enable = true;
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
  };
  networking.dhcpcd.denyInterfaces = mkLaptop [ "wg*" "wlan*" ];
  systemd.services.dhcpcd.enable = !isLaptop;
  networking.dhcpcd.enable = lib.mkForce isLaptop;

  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
  };
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
  programs.steam.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MOZ_USE_XINPUT2 = "1";
    MOZ_X11_EGL = "1";
  };

  services.gnome.gnome-keyring.enable = true;
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
    # profiles = import ./apparmor.nix device pkgs;
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
    media-session = mkLaptop {
      config.bluez-monitor.properties = {
        "bluez5.msbc-support" = true;
        "bluez5.sbc-xq-support" = true;
      };
    };
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
    enabled = "fcitx5";
    fcitx5.addons = [ pkgs.fcitx5-m17n ];
  };

  # Laptop specific things
  boot.resumeDevice = mkLaptop "/dev/disk/by-uuid/4a95b4e5-a240-4754-9101-3e966627449d";
  boot.plymouth.enable = isLaptop;

  services.upower.enable = isLaptop;
  services.tlp.enable = isLaptop;
  services.auto-cpufreq.enable = isLaptop;
  services.throttled.enable = false;
  services.blueman.enable = isLaptop;
  services.fwupd.enable = isLaptop;

  hardware.bluetooth.enable = isLaptop;
  hardware.bluetooth.hsphfpd.enable = isLaptop;
  # This is an example service that always fails
  systemd.user.services.telephony_client.enable = false;

  powerManagement.enable = isLaptop;

  programs.sway.enable = isLaptop;

  networking.wireless.iwd.enable = isLaptop;
  networking.hosts."${if isLaptop then "10.200.200.1" else "192.168.1.2"}" = [ "yogs.tech" ];

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
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
    wantedBy = [ "graphical-session.target" ];
  };

  services.snapper.configs = let
    timelineConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  in
    mkLaptop {
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
    wireguardPeers = [
      {
        wireguardPeerConfig = {
          PublicKey = "CqrwDIxsSYFJ+xHFkDotn38wvOMC32qBpcrZHvacsF0=";
          Endpoint = "aamaruvi.ddns.net:51820";
          AllowedIPs = "0.0.0.0/0, ::/0";
        };
      }
    ];
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

    cpkgs.tools.wgvpn
  ];

  # Desktop specific things
  services.sshd.enable = isDesktop;
  services.fstrim.enable = isDesktop;
  programs.java.enable = isDesktop;
  hardware.openrazer.enable = isDesktop;

  networking.firewall = {
    enable = !isLaptop;
    allowedTCPPorts = mkDesktop [ 22 ];
  };
  systemd.network.networks."00-ethernet" = mkDesktop {
    name = "eno1";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
    };
  };

  hardware.nvidia.package = mkDesktop config.boot.kernelPackages.nvidiaPackages.beta;

  services.xserver = mkDesktop {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.defaultSession = "none+i3";
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
    };
    displayManager.sddm = {
      enable = true;
    };
  };

  environment.etc = mkDesktop {
    "X11/xorg.conf.d/10-nvidia.conf".source = ./desktop/10-nvidia.conf;
    "X11/xorg.conf.d/50-mouse-accel.conf".source = ./desktop/50-mouse-accel.conf;
    "X11/xorg.conf.d/90-kbd.conf".source = ./desktop/90-kbd.conf;
  };

  services.picom = mkDesktop {
    enable = true;
    backend = "glx";
    experimentalBackends = true;
    settings = {
      unredir-if-possible = false;
      xrender-sync-fence = true;
    };
  };

  # security.pam.services = mkDesktop {
  #   i3lock.enableGnomeKeyring = true;
  #   i3lock-color.enableGnomeKeyring = true;
  #   login.enableGnomeKeyring = true;
  #   lightdm.enableGnomeKeyring = true;
  # };

  boot.kernelModules = mkDesktop [ "i2c-dev" "i2c-i801" "i2c-nct6775" ];

  boot.kernelPatches = mkDesktop (
    builtins.map mkPatch [
      "openrgb"
      "futex2"
      "winesync"
    ]
  );

  systemd.user.services.rgb-restore = mkDesktop {
    description = "restore rgb effects";
    wants = [ "dbus.service" "openrazer-daemon.service" ];
    after = [ "dbus.service" "openrazer-daemon.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${config.nix.package}/bin/nix-shell --run 'python /home/aamaruvi/git/razer/main.py' /home/aamaruvi/git/razer/shell.nix"
        "${pkgs.openrgb}/bin/openrgb -d 0 -m breathing -c FF0000"
        "${pkgs.openrgb}/bin/openrgb -d 1 -m breathing -c FF0000"
      ];
    };
  };

  nixpkgs.overlays = [
    (
      self: super: {
        cadence = super.cadence.override { libjack2 = super.pipewire.jack; };
      }
    )
  ];

  services.udev = mkDesktop {
    packages = [ pkgs.openrgb ];
    extraRules = ''
      // The nari works with the steelseries arctis profile well
      ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051c", ENV{ACP_PROFILE_SET}="steelseries-arctis-common-usb-audio.conf"
    '';
  };
}
