device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  isDesktop = device == "desktop";
  mkLaptop = obj: lib.mkIf (isLaptop) obj;
  mkDesktop = obj: lib.mkIf (isDesktop) obj;
  mkPatch = name: { inherit name; patch = ./desktop + "/${name}.patch"; };
in
{

  imports = [ (if isLaptop then ./wayland/config.nix else ./x11/config.nix) ];

  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      dates = "weekly";
      automatic = true;
    };
    settings = {
      # substituters = [ "http://yogs.tech:9000/" ];
      trusted-public-keys = [ "yogs.tech-1:1GiyAEtYCGV5v2Towsp4P5h4mREIIg+/6f3oDLotDyA=" ];
    };
  };

  fileSystems =
    let
      default_opts = [
        "noatime"
        "compress=zstd:5"
        "ssd"
        "space_cache"
      ];
      swap_opts = [
        "noatime"
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
  boot.loader.timeout = mkLaptop 0;
  boot.cleanTmpDir = true;
  boot.kernelPackages = pkgs.linuxKernel.packageAliases.linux_latest;
  boot.kernelParams = [ ]
    ++ (
    lib.optionals isLaptop [
      "resume_offset=14313573"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "workqueue.power_efficient=1"
      "nvme.noacpi=1"
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

  networking.dhcpcd.enable = false;
  systemd.network.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
    extraConfig = ''
      LLMNR=yes
      MulticastDNS=yes
    '';
  };

  programs.gnupg.agent.enable = true;
  programs.fish.enable = true;

  nixpkgs.config = {
    pulseaudio = true;
    allowUnfree = true;
  };

  hardware.pulseaudio.enable = lib.mkForce false;

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      libvdpau-va-gl
    ] ++ (lib.optionals isLaptop [
      intel-compute-runtime
      intel-media-driver
    ]) ++ (lib.optionals isDesktop [
      nvidia-vaapi-driver
    ]);
  };
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = isDesktop;

  hardware.enableRedistributableFirmware = true;
  hardware.wirelessRegulatoryDatabase = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIX_AUTO_RUN = "1";
    NIX_AUTO_RUN_INTERACTIVE = "1";
  };

  services.gnome.gnome-keyring.enable = true;
  services.printing.enable = true;
  systemd.services.cups-browsed.enable = false;

  services.usbmuxd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  # users.groups.ancs4linux = mkLaptop { };
  users.users.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" ]
      ++ lib.optionals isDesktop [ "openrazer" ]
      # "ancs4linux"
      ++ lib.optionals isLaptop [ "dialout" ];
    shell = pkgs.fish;
  };

  system.stateVersion = if isLaptop then "22.05" else "20.09";

  programs.dconf.enable = true;

  services.udisks2.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    wireplumber.enable = true;
    media-session.enable = false;
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

  # i18n.inputMethod = {
  #   enabled = "fcitx5";
  #   fcitx5.addons = [ pkgs.fcitx5-m17n ];
  # };

  # Laptop specific things
  boot.resumeDevice = mkLaptop "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
  boot.plymouth.enable = isLaptop;
  services.fprintd.enable = isLaptop;

  services.logind = mkLaptop {
    lidSwitch = "suspend";
    extraConfig = ''
      IdleAction=suspend-then-hibernate
      HandlePowerKey=hibernate
      IdleActionSec=300
      HandleLidSwitch=suspend-then-hibernate
      HandleLidSwitchExternalPower=suspend-then-hibernate
    '';
  };

  nixpkgs.overlays = mkLaptop [
    (self: super: {
      steam = super.steam.override { extraPkgs = p: [ p.cups ]; };

      eclipse = super.writeScriptBin "eclipse" ''
        #!${super.runtimeShell}
        export GDK_BACKEND=x11
        exec ${super.eclipses.eclipse-java}/bin/eclipse "$@"
      '';
    })
  ];

  systemd.sleep.extraConfig = mkLaptop ''
    HibernateDelaySec=2h
  '';


  services.upower.enable = isLaptop;
  services.tlp = mkLaptop {
    # enable = true;
    settings = {
      DISK_DEVICES = "nvme0n1";
      PCIE_ASPM_ON_BAT = "powersupersave";
      PCIE_ASPM_ON_AC = "powersupersave";
      NMI_WATCHDOG = 0;
      USB_AUTOSUSPEND = 1;
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_ON_AC = "auto";
      ENERGY_PERF_POLICY_ON_BAT = "powersave";
      SCHED_POWERSAVE_ON_BAT = 1;

      INTEL_GPU_MIN_FREQ_ON_AC = 100;
      INTEL_GPU_MIN_FREQ_ON_BAT = 100;
      INTEL_GPU_MAX_FREQ_ON_AC = 1300;
      INTEL_GPU_MAX_FREQ_ON_BAT = 500;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1100;
    };
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  services.blueman.enable = isLaptop;
  services.fwupd = mkLaptop {
    enable = true;
  };

  hardware.bluetooth.enable = isLaptop;
  hardware.bluetooth.hsphfpd.enable = isLaptop;
  # This is an example service that always fails
  systemd.user.services.telephony_client.enable = false;

  powerManagement.enable = isLaptop;
  hardware.sensor.iio.enable = isLaptop;

  networking.wireless.iwd = mkLaptop {
    enable = true;
    settings = {
      General.AddressRandomization = "network";
      Network.EnableIPv6 = true;
    };
  };
  networking.hosts."${if isLaptop then "10.200.200.1" else "192.168.0.2"}" = [ "yogs.tech" ];

  # systemd.services.autovpn = mkLaptop {
  #   description = "Automatic WireGuard VPN Activation";
  #   after = [ "iwd.service" "systemd-networkd.socket" "dbus.socket" ];
  #   wants = [ "iwd.service" "systemd-networkd.socket" "dbus.socket" ];
  #   environment.RUST_LOG = "warn";
  #   serviceConfig = {
  #     PrivateTmp = true;
  #     NoNewPrivileges = true;
  #     RestrictSUIDSGID = true;
  #     SystemCallArchitectures = "native";
  #     RestrictAddressFamilies = [ "AF_NETLINK" "AF_UNIX" ];
  #     ProtectHostname = true;
  #     ProtectKernelLogs = true;
  #     ProtectKernelModules = true;
  #     ProtectKernelTunables = true;
  #     ProtectControlGroups = true;
  #     RestrictNamespaces = true;
  #     ProtectHome = true;
  #     ProtectSystem = true;
  #     RestrictRealtime = true;
  #     ProtectClock = true;
  #     MemoryDenyWriteExecute = true;
  #     LockPersonality = true;
  #     CapabilityBoundingSet = "CAP_NET_ADMIN";
  #     SystemCallFilter = [ "@system-service" "~@mount" "~@cpu-emulation" "~@debug" "~@keyring" "~@obsolete" "~@privileged" "~@setuid" ];
  #     Type = "simple";
  #     ExecStart = "${pkgs.cpkgs.autovpn}/bin/autovpn";
  #   };
  #   wantedBy = [ "multi-user.target" ];
  # };

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

  # services.beesd.filesystems = {
  #   root = {
  #     spec = "UUID=8e823de4-e182-41d0-8793-8f3fe59932da";
  #     hashTableSizeMB = 4096;
  #     verbosity = "crit";
  #     # extraOptions = [ "--loadavg-target" "5.0" ];
  #   };
  # };

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
      LLMNR = "yes";
      MulticastDNS = "yes";
    };
  };

  systemd.network.netdevs."10-wg0" = {
    netdevConfig = {
      Name = "wg0";
      Kind = "wireguard";
      Description = "WireGuard Tunnel wg0";
    };
    wireguardConfig = {
      PrivateKeyFile = "/etc/wireguard/${device}.key";
      FirewallMark = mkLaptop 51000;
    };
    wireguardPeers = [
      {
        wireguardPeerConfig = {
          PublicKey = "CqrwDIxsSYFJ+xHFkDotn38wvOMC32qBpcrZHvacsF0=";
          Endpoint = "${if isLaptop then "aamaruvi.ddns.net" else "192.168.0.2"}:51820";
          AllowedIPs = if isLaptop then "0.0.0.0/0, ::/0" else "10.200.200.0/24, fd37:994c:6708:de39::/64";
        };
      }
    ];
  };

  systemd.network.networks."10-wg0" = {
    name = "wg0";
    DHCP = "no";
    address = if isLaptop then [ "10.200.200.2/32" "fd37:994c:6708:de39::2/128" ] else [ "10.200.200.7/32" "fd37:994c:6708:de39::7/128" ];
    dns = mkLaptop [ "10.200.200.1" "fd37:994c:6708:de39::1" ];
    routes = [
      {
        routeConfig = mkLaptop {
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
        routeConfig = mkLaptop {
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
      LLMNR = "yes";
      MulticastDNS = "yes";
    };
  };

  xdg.portal.enable = true;
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; mkLaptop [
    cpkgs.robotmeshnative
    # cpkgs.ancs4linux
    config.boot.kernelPackages.turbostat
  ];

  programs.java.enable = true;

  services.jellyfin.enable = isDesktop;

  networking.nftables = {
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
          tcp dport 5355 accept
          udp dport 5355 accept

          ${if isDesktop then ''
            # jellyfin
            tcp dport 8096 accept
            tcp dport 8920 accept
            udp dport 1900 accept
            udp dport 7359 accept

            tcp dport 22 accept
            tcp dport 5100 accept
          '' else ""}

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
    enable = false;
    allowedTCPPorts = mkDesktop [ 22 5100 ];
  };

  systemd.network.networks."00-ethernet" = {
    matchConfig.Type = "ether";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
      LLMNR = "yes";
      MulticastDNS = "yes";
    };
  };

  hardware.nvidia = mkDesktop {
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # NOTE: not on a beta now, uncomment when a beta is available
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  services.xserver.videoDrivers = mkDesktop [ "nvidia" ];

  environment.etc = mkLaptop {
    "chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";
    "opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";

    "fwupd/remotes.d/lvfs-testing.conf" = lib.mkForce ({
      text = ''
        [fwupd Remote]

        # this remote provides metadata and firmware marked as 'testing' from the LVFS
        Enabled=true
        Title=Linux Vendor Firmware Service (testing)
        MetadataURI=https://cdn.fwupd.org/downloads/firmware-testing.xml.gz
        ReportURI=https://fwupd.org/lvfs/firmware/report
        #Username=
        #Password=
        OrderBefore=lvfs,fwupd
        AutomaticReports=false
        ApprovalRequired=false
      '';
    });

    "fwupd/uefi_capsule.conf" = lib.mkForce ({ text = "DisableCapsuleUpdateOnDisk=true"; });
  };

  security.pam.services = {
    # get gnome-keyring to unlock on boot
    login.fprintAuth = mkLaptop (lib.mkForce false);
    # correctly order pam_fprintd.so and pam_unix.so so password and fignerprint works
    sudo.fprintAuth = mkLaptop true;
    # times out waiting for fingerprint with no feedback
    cups.fprintAuth = mkLaptop false;

    sddm.enableGnomeKeyring = mkDesktop true;
    i3lock.enableGnomeKeyring = mkDesktop true;
    i3lock-color.enableGnomeKeyring = mkDesktop true;
  };

  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';

  boot.kernelModules = mkDesktop [ "i2c-dev" "i2c-i801" "i2c-nct6775" ];

  boot.kernelPatches = mkDesktop [
    (mkPatch "openrgb")
  ];

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
    packages = [ ] ++ (lib.optionals isDesktop [ pkgs.qmk-udev-rules pkgs.openrgb ]) ++ (lib.optionals isLaptop [ pkgs.cpkgs.robotmeshnative ]);
    extraRules = mkLaptop ''
      // Allows user access so that nspireconnect.ti.com can access the calculator
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="e022", TAG+="uaccess"
      // Allows user rfkill access
      KERNEL=="rfkill", MODE=664, TAG+="uaccess"
    '';
  };

  # systemd.packages = mkLaptop [ pkgs.cpkgs.ancs4linux ];
  # systemd.services.ancs4linux-advertising.wantedBy = mkLaptop [ "default.target" ];
  # systemd.services.ancs4linux-observer.wantedBy = mkLaptop [ "default.target" ];
  # systemd.user.services.ancs4linux-desktop-integration.wantedBy = mkLaptop [ "graphical-session.target" ];
  # services.dbus.packages = mkLaptop [ pkgs.cpkgs.ancs4linux ];
}
