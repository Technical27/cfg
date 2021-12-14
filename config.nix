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
  hardware.enableRedistributableFirmware = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  services.gnome.gnome-keyring.enable = true;
  services.printing.enable = true;
  systemd.services.cups-browsed.enable = false;
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

  services.earlyoom.enable = true;

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
    lidSwitchExternalPower = "suspend";
    extraConfig = ''
      HandlePowerKey=hibernate
    '';
  };

  systemd.sleep.extraConfig = mkLaptop ''
    HibernateDelaySec=10m
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

  services.throttled.enable = false;
  services.blueman.enable = isLaptop;
  services.fwupd.enable = isLaptop;

  hardware.bluetooth.enable = isLaptop;
  hardware.bluetooth.hsphfpd.enable = isLaptop;
  # This is an example service that always fails
  systemd.user.services.telephony_client.enable = false;

  powerManagement.enable = isLaptop;

  programs.sway = {
    enable = true;
    # managed with home manager
    extraPackages = lib.mkForce [ ];
  };

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

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
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
    };
  };

  hardware.nvidia = mkDesktop {
    modesetting.enable = true;
    powerManagement.enable = true;
    # NOTE: not on a beta now, uncomment when a beta is available
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver = mkDesktop {
    # enable = true;
    videoDrivers = [ "nvidia" ];
    # displayManager.defaultSession = "none+i3";
    # windowManager.i3 = {
    #   enable = true;
    #   package = pkgs.i3-gaps;
    # };
    # displayManager.sddm.enable = true;
  };

  environment.etc =
    if isDesktop then
      ({
        # "X11/xorg.conf.d/10-nvidia.conf".source = ./desktop/10-nvidia.conf;
        # "X11/xorg.conf.d/50-mouse-accel.conf".source = ./desktop/50-mouse-accel.conf;
        # "X11/xorg.conf.d/90-kbd.conf".source = ./desktop/90-kbd.conf;
      }) else
      ({
        "chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/chromium/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";
        "opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json".source = "${pkgs.cpkgs.robotmeshnative}/etc/opt/chrome/native-messaging-hosts/com.robotmesh.robotmeshconnect.json";
      });

  services.picom = mkDesktop {
    # enable = true;
    backend = "glx";
    experimentalBackends = true;
    settings = {
      unredir-if-possible = false;
      xrender-sync-fence = true;
    };
  };

  security.pam.services = mkLaptop {
    login.fprintAuth = lib.mkForce false;
    swaylock.fprintAuth = true;
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

  nixpkgs.overlays = [
    (
      self: super: {
        vscodium = super.vscodium.overrideAttrs (
          old: rec {
            desktopItem = super.makeDesktopItem {
              name = "codium";
              desktopName = "VSCodium";
              comment = "Code Editing. Redefined.";
              genericName = "Text Editor";
              exec = "codium --enable-features=UseOzonePlatform --ozone-platform=wayland %F";
              icon = "code";
              startupNotify = "true";
              categories = "Utility;TextEditor;Development;IDE;";
              mimeType = "text/plain;inode/directory;";
              extraEntries = ''
                StartupWMClass=vscodium
                Actions=new-empty-window;
                Keywords=vscode;
                [Desktop Action new-empty-window]
                Name=New Empty Window
                Exec=codium --new-window --enable-features=UseOzonePlatform --ozone-platform=wayland %F
                Icon=code
              '';
            };
          }
        );
      }
    )
  ];

  services.udev = {
    packages = lib.recursiveUpdate (mkDesktop [ pkgs.openrgb ]) (mkLaptop [ pkgs.cpkgs.robotmeshnative ]);
    extraRules = mkLaptop ''
      // Allows user access so that nspireconnect.ti.com can access the calculator
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="e022", GROUP="users"
    '';
  };
}
