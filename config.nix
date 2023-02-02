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
    # settings = {
    #   substituters = [ "http://yogs.tech:9000/" ];
    #   trusted-public-keys = [ "yogs.tech-1:1GiyAEtYCGV5v2Towsp4P5h4mREIIg+/6f3oDLotDyA=" ];
    # };
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
  # TODO: resume_offset is not supported yet.
  boot.initrd.systemd.enable = isDesktop;
  boot.loader.timeout = 0;
  boot.cleanTmpDir = true;
  boot.kernelPackages = pkgs.linuxKernel.packageAliases.linux_latest;
  boot.extraModulePackages = mkLaptop [ config.boot.kernelPackages.rtl88xxau-aircrack ];
  boot.kernelParams = [ ]
    ++ (
    lib.optionals isLaptop [
      "resume_offset=14316493"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "workqueue.power_efficient=1"
      "nvme.noacpi=1"
      "iwlwifi.power_save=1"
      "iwlmvm.power_scheme=3"
      "snd_hda_intel.power_save=1"
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

  # NOTE: this shouldn't be required
  # hope more things support systemd-resolved for this
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
  # programs.steam.remotePlay.openFirewall = isDesktop;

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
  # NOTE: this dumb thing pulls in every single shared printer
  # from every macbook on a network that has "share this printer" enabled.
  systemd.services.cups-browsed.enable = false;

  services.usbmuxd.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" ]
      ++ lib.optionals isDesktop [ "openrazer" ];
    shell = pkgs.fish;
  };

  system.stateVersion = if isLaptop then "22.05" else "20.09";

  programs.dconf.enable = true;

  services.udisks2.enable = true;

  security.rtkit.enable = true;
  security.wrappers.gamescope = {
    source = "${pkgs.gamescope}/bin/gamescope";
    program = "gamescope";
    capabilities = "cap_sys_nice+ep";
    owner = "root";
    group = "root";
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
    wireplumber.enable = true;
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

      swaylock-effects = super.swaylock-effects.overrideAttrs (old: rec {
        src = super.fetchFromGitHub {
          owner = "jirutka";
          repo = "swaylock-effects";
          rev = "cd07dd1082a2fc1093f1e6f2541811e446f4d114";
          sha256 = "sha256-aK/PvFjZoF8R0llXO+P650vHYLSoGS6dYSk5Pw8DBNY=";
        };
      });

      eclipse = super.writeScriptBin "eclipse" ''
        #!${super.runtimeShell}
        export GDK_BACKEND=x11
        exec ${super.eclipses.eclipse-java}/bin/eclipse "$@"
      '';
    })
  ];

  systemd.sleep.extraConfig = mkLaptop ''
    HibernateDelaySec=30m
  '';

  services.upower.enable = isLaptop;
  services.tlp = mkLaptop {
    enable = true;
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
    extraRemotes = [ "lvfs-testing" ];
  };

  hardware.bluetooth.enable = isLaptop;

  powerManagement.enable = isLaptop;
  hardware.sensor.iio.enable = isLaptop;

  networking.wireless.iwd = mkLaptop {
    enable = true;
    settings = {
      General.AddressRandomization = "network";
      Network.EnableIPv6 = true;
    };
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

  # NOTE: just uses too much cpu for a laptop
  # services.beesd.filesystems = {
  #   root = {
  #     spec = "UUID=8e823de4-e182-41d0-8793-8f3fe59932da";
  #     hashTableSizeMB = 512;
  #     verbosity = "crit";
  #     extraOptions = [ "--loadavg-target" "2.0" ];
  #   };
  # };

  services.snapper.configs =
    let
      timelineConfig = ''
        TIMELINE_CREATE=yes
        TIMELINE_CLEANUP=yes
        TIMELINE_LIMIT_MONTHLY=1
        TIMELINE_LIMIT_YEARLY=0
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

  xdg.portal.enable = true;
  services.flatpak.enable = true;

  environment.systemPackages = [
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

          # accept any localhost/vpn traffic
          iifname { lo, wg0 } accept

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

            udp dport 50000 accept
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
  services.openssh = mkDesktop {
    enable = true;
    banner = ''
          _        _   _              _              _
       __| |___ __| |_| |_ ___ _ __  | |___  __ __ _| |
      / _` / -_|_-< / /  _/ _ \ '_ \_| / _ \/ _/ _` | |
      \__,_\___/__/_\_\\__\___/ .__(_)_\___/\__\__,_|_|
                              |_|
    '';
  };
  services.fstrim.enable = true;
  hardware.openrazer.enable = isDesktop;

  networking.firewall.enable = false;

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
    "fwupd/uefi_capsule.conf" = lib.mkForce ({
      text = ''
        [uefi_capsule]
        OverrideESPMountPoint=${config.boot.loader.efi.efiSysMountPoint}
        DisableCapsuleUpdateOnDisk=true
      '';
    });
  };

  security.pam.services = {
    # get gnome-keyring to unlock on boot
    login.fprintAuth = mkLaptop (lib.mkForce false);
    # correctly order pam_fprintd.so and pam_unix.so so password and fignerprint works
    sudo.fprintAuth = mkLaptop true;
    # times out waiting for fingerprint with no feedback
    cups.fprintAuth = mkLaptop false;

    sddm.enableGnomeKeyring = mkDesktop true;
    login.enableGnomeKeyring = true;
    i3lock.enableGnomeKeyring = mkDesktop true;
    i3lock-color.enableGnomeKeyring = mkDesktop true;
    xscreensaver.enableGnomeKeyring = mkDesktop true;
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
    after = [ "dbus.service" "openrazer-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          openrgb = cmd: "${pkgs.openrgb}/bin/openrgb ${cmd}";
          liquidctl = cmd: "${pkgs.liquidctl}/bin/liquidctl ${cmd}";
        in
        [
          (openrgb "-d 0 -d 1 -m static -c FF0000")
          (openrgb "-d 2 -m static -c FF0000")
          (openrgb "-d 3 -m breathing -c FF0000")
          (liquidctl "initialize all")
          (liquidctl "--match smart set led color breathing ff0000")
          (liquidctl "--match smart set fan1 speed 50")
          (liquidctl "--match smart set fan2 speed 50")
          (liquidctl "--match kraken set ring color breathing ff0000")
          (liquidctl "--match kraken set logo color breathing ff0000")
          (liquidctl "--match kraken set fan speed 20 10 30 30 40 50")
          (liquidctl "--match kraken set pump speed 20 30 30 50 40 80")
        ];
    };

    wantedBy = [ "default.target" ];
  };

  services.udev = {
    packages = mkDesktop [ pkgs.qmk-udev-rules pkgs.openrgb ];
    extraRules = mkLaptop ''
      // Allows user access so that nspireconnect.ti.com can access the calculator
      ATTRS{idVendor}=="0451", ATTRS{idProduct}=="e022", TAG+="uaccess"
      // Allows user rfkill access
      KERNEL=="rfkill", MODE=664, TAG+="uaccess"
    '';
  };
}
