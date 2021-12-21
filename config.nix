device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  isDesktop = device == "desktop";
  mkLaptop = obj: lib.mkIf (isLaptop) obj;
  mkDesktop = obj: lib.mkIf (isDesktop) obj;
  mkPatch = name: { inherit name; patch = ./desktop + "/${name}.patch"; };
in
{

  imports = [ ./wayland/config.nix ];

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    binaryCaches = [
      "http://yogs.tech:9000/"
    ];
    binaryCachePublicKeys = [
      "yogs.tech-1:1GiyAEtYCGV5v2Towsp4P5h4mREIIg+/6f3oDLotDyA="
    ];
    requireSignedBinaryCaches = false;
    gc = {
      dates = "weekly";
      automatic = true;
    };
  };

  fileSystems =
    let
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
      "/home".options = default_opts;
      "/swap".options = swap_opts;
    };

  swapDevices = [{ device = "/swap/file"; }];

  networking.hostName = device;

  boot.loader.systemd-boot.enable = true;
  boot.cleanTmpDir = true;
  boot.kernelPackages = pkgs.linuxKernel.packageAliases.linux_latest;
  boot.kernelParams = [ ]
    ++ (
    lib.optionals isLaptop [
      # "resume_offset=18382314"
      "resume_offset=14313573"
      "i915.enable_guc=2"
      # "mem_sleep_default=deep"
    ]
  );

  boot.kernel.sysctl = lib.recursiveUpdate
    (mkDesktop {
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
      "net.ipv4.ip_forward" = 1;
    })
    {
      "vm.swappiness" = 10;
    };

  systemd.network.enable = true;
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    extraConfig = "MulticastDNS=yes";
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
    extraPackages = with pkgs; [
      intel-media-driver
      libvdpau-va-gl
      vaapiVdpau
      intel-ocl
    ];
  };
  programs.steam.enable = true;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  services.gnome.gnome-keyring.enable = true;
  services.printing.enable = true;
  systemd.services.cups-browsed.enable = false;

  services.usbmuxd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  users.extraUsers.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]
      ++ lib.optionals isDesktop [ "openrazer" ]
      ++ lib.optionals isLaptop [ "dialout" ];
    shell = pkgs.fish;
  };

  system.stateVersion = if isLaptop then "22.05" else "20.09";

  security.apparmor.enable = true;

  programs.dconf.enable = true;
  programs.tilp2.enable = true;

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

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = [ pkgs.fcitx5-m17n ];
  };

  # Laptop specific things
  boot.resumeDevice = mkLaptop "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
  boot.plymouth.enable = isLaptop;
  services.fprintd.enable = isLaptop;

  services.logind = mkLaptop {
    lidSwitch = "suspend-then-hibernate";
    extraConfig = ''
      HandlePowerKey=hibernate
    '';
  };

  systemd.sleep.extraConfig = mkLaptop ''
    HibernateDelaySec=30m
  '';


  services.upower.enable = isLaptop;
  services.tlp = mkLaptop {
    enable = true;
    settings = {
      DISK_DEVICES = "nvme0n1";
      PCIE_ASPM_ON_BAT = "powersupersave";
      NMI_WATCHDOG = 0;
      USB_AUTOSUSPEND = 1;
      RUNTIME_PM_ON_BAT = "auto";
      ENERGY_PERF_POLICY_ON_BAT = "powersave";
      SCHED_POWERSAVE_ON_BAT = 1;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
    };
  };

  services.blueman.enable = isLaptop;
  services.fwupd.enable = isLaptop;

  hardware.bluetooth.enable = isLaptop;
  hardware.bluetooth.hsphfpd.enable = isLaptop;
  # This is an example service that always fails
  systemd.user.services.telephony_client.enable = false;

  powerManagement.enable = isLaptop;

  networking.wireless.iwd = mkLaptop {
    enable = true;
    settings = {
      General.AddressRandomization = "network";
      Network.EnableIPv6 = true;
    };
  };
  networking.hosts."${if isLaptop then "10.200.200.1" else "192.168.0.2"}" = [ "yogs.tech" ];

  systemd.services.autovpn = mkLaptop {
    description = "Automatic WireGuard VPN Activation";
    after = [ "iwd.service" "systemd-networkd.socket" ];
    wants = [ "iwd.service" "systemd-networkd.socket" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.cpkgs.autovpn}/bin/autovpn";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.user.services.mpris-proxy = mkLaptop {
    description = "bluez mpris-proxy";
    after = [ "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
    wantedBy = [ "graphical-session.target" ];
  };

  services.snapper.configs =
    let
      timelineConfig = ''
        TIMELINE_CREATE=yes
        TIMELINE_CLEANUP=yes
      '';
    in
    mkLaptop {
      home = {
        subvolume = "/home";
        extraConfig = ''
          ${timelineConfig}
          ALLOW_USERS=aamaruvi
        '';
      };
      root = {
        subvolume = "/";
        extraConfig = timelineConfig;
      };
    };

  systemd.network.networks."00-wifi" = mkLaptop {
    name = "wlan0";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
      MulticastDNS = "yes";
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

  systemd.network.networks."10-ethernet" = mkLaptop {
    name = "enp*";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
      MulticastDNS = "yes";
    };
  };

  systemd.network.networks."10-wg0" = mkLaptop {
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
    networkConfig = {
      DNSDefaultRoute = "no";
      MulticastDNS = "yes";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; mkLaptop [
    cpkgs.robotmeshnative
  ];

  programs.java = {
    enable = true;
    package = mkLaptop pkgs.jdk11;
  };

  networking.nftables = mkLaptop {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0;

          # accept any localhost traffic
          iifname lo accept

          # accept traffic originated from us
          ct state {established, related} accept

          ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
          ip protocol icmp icmp type { destination-unreachable, router-advertisement, time-exceeded, parameter-problem } accept

          ip6 nexthdr icmpv6 icmpv6 type echo-request accept
          ip protocol icmp icmp type echo-request accept

          udp dport 5353 accept

          counter drop
        }

        chain output {
          type filter hook output priority 0;
          accept
        }

        chain forward {
          type filter hook forward priority 0;
          counter drop
        }
      }
    '';
  };

  # Desktop specific things
  services.sshd.enable = isDesktop;
  services.fstrim.enable = isDesktop;
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
      MulticastDNS = "yes";
    };
  };

  hardware.nvidia = mkDesktop {
    modesetting.enable = true;
    powerManagement.enable = true;
    # NOTE: not on a beta now, uncomment when a beta is available
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = mkDesktop [ "nvidia" ];

  environment.etc = mkLaptop {
    "chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";
    "opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";
  };

  security.pam.services = mkLaptop {
    # get gnome-keyring to unlock on boot
    login.fprintAuth = lib.mkForce false;
    # correctly order pam_fprintd.so and pam_unix.so so password and fignerprint works
    swaylock.text = ''
      # Account management.
      account required pam_unix.so

      # Authentication management.
      auth sufficient pam_unix.so nullok likeauth try_first_pass
      auth optional ${pkgs.gnome.gnome-keyring}/lib/security/pam_gnome_keyring.so
      auth sufficient ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth required pam_deny.so

      # Password management.
      password sufficient pam_unix.so nullok sha512

      # Session management.
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required pam_unix.so
    '';
    sudo.fprintAuth = true;
  };

  boot.kernelModules = mkDesktop [ "i2c-dev" "i2c-i801" "i2c-nct6775" ];

  boot.kernelPatches = mkDesktop (
    builtins.map mkPatch [
      "openrgb"
      "futex_waitv"
    ]
  );

  systemd.user.services.rgb-restore = mkDesktop {
    description = "restore rgb effects";
    wants = [ "dbus.service" "openrazer-daemon.service" ];
    after = [ "dbus.service" "openrazer-daemon.service" "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.openrgb}/bin/openrgb -d 0 -m breathing -c FF0000"
        "${pkgs.openrgb}/bin/openrgb -d 1 -m breathing -c FF0000"
      ];
    };
  };

  services.udev = {
    packages = lib.recursiveUpdate (mkDesktop [ pkgs.openrgb ]) (mkLaptop [ pkgs.cpkgs.robotmeshnative ]);
    extraRules = mkLaptop ''
      // Allows user access so that nspireconnect.ti.com can access the calculator
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="e022", GROUP="users"
      // Allows user rfkill access
      KERNEL=="rfkill", MODE="0664", TAG+="uaccess"
    '';
  };
}
