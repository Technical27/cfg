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
  };

  fileSystems = let
    default_opts = [
      "noatime"
      "nodiratime"
      "discard=async"
      "compress-force=zstd:5"
      "ssd"
      "space_cache"
      "autodefrag"
    ];
    swap_opts = [
      "noatime"
      "nodiratime"
      "ssd"
      "discard=async"
    ];
  in (mkLaptop {
    "/".options = default_opts;
    "/nix".options = default_opts;
    "/var".options = default_opts;
    "/home".options = default_opts;
    "/swap".options = swap_opts;
  })
  // (mkDesktop {
    "/media/hdd" = {
      device = "/dev/disk/by-uuid/cb1cdd76-7b53-4acd-8357-388562abb590";
      fsType = "ext4";
    };
    "/media/ssd" = {
      device = "/dev/disk/by-uuid/034782cc-bc82-4940-bfa8-be7e656fc9ad";
      fsType = "ext4";
    };
  });

  swapDevices = mkDesktop [{ label = "swap"; }] // mkLaptop [{ device = "/swap/file"; priority = 10; }];

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
      "kvm_intel.nested=1"
    ]);

  boot.kernel.sysctl = mkDesktop {
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
    "net.ipv4.ip_forward" = 1;
    "vm.swappiness" = 10;
  } // mkLaptop {
    "vm.swappiness" = 60;
  };

  systemd.network.enable = true;
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
  };

  # temp fix for systemd-resolved
  systemd.services.systemd-resolved.environment = {
    LD_LIBRARY_PATH = "${lib.getLib pkgs.libidn2}/lib";
  };

  programs.gnupg.agent.enable = true;
  programs.fish.enable = true;

  nixpkgs.config = {
    pulseaudio = true;
    allowUnfree = true;
  };

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraModules = mkLaptop [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
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
      QT_WAYLAND_FORCE_DPI = "physical";
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

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  users.extraUsers.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]
    ++ lib.optionals isLaptop [ "input" ]
    ++ lib.optionals isDesktop [ "plugdev" ];
    shell = pkgs.fish;
  };

  system.stateVersion = "20.09";

  security.apparmor.enable = true;
  programs.dconf.enable = true;

  # Laptop specific things
  boot.resumeDevice = mkLaptop "/dev/disk/by-uuid/4a95b4e5-a240-4754-9101-3e966627449d";
  boot.plymouth.enable = isLaptop;

  programs.sway.enable = isLaptop;

  services.pipewire.enable = isLaptop;
  services.upower.enable = isLaptop;
  services.tlp.enable = isLaptop;
  services.throttled.enable = false;
  services.blueman.enable = isLaptop;
  services.fwupd.enable = isLaptop;

  hardware.bluetooth.enable = isLaptop;

  powerManagement.enable = isLaptop;

  networking.wireless.iwd.enable = isLaptop;
  networking.hosts."10.200.200.1" = mkLaptop [ "yogs.tech" ];

  systemd.user.services.mpris-proxy = mkLaptop {
    description = "bluez mpris-proxy";
    after = [ "network.target" "pulseaudio.service" ];
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
    address = ["10.200.200.2/32" "fd37:994c:6708:de39::2/128"];
    dns = ["10.200.200.1"];
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
  };

  xdg.portal = mkLaptop {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };

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
    name = "enp1s0";
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

  security.pam.services = mkDesktop {
    i3lock.enableGnomeKeyring = true;
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

  boot.kernelPatches = mkDesktop [
    (mkPatch "openrgb")
    (mkPatch "rdtsc")
    (mkPatch "fsync")
  ];

  systemd.user.services.razer-kbd = mkDesktop {
    description = "restore openrazer effects";
    wants = [ "dbus.service" ];
    after = [ "dbus.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.nix.package}/bin/nix-shell --run 'python /home/aamaruvi/git/razer/main.py' /home/aamaruvi/git/razer/shell.nix";
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      neovim-unwrapped = super.neovim-unwrapped.overrideAttrs (old: {
        version = "0.5.0-dev";
        src = super.fetchFromGitHub {
          owner = "neovim";
          repo = "neovim";
          rev = "4cdc8b1efdc7a67d24c7193ef67839924eb7d5c0";
          sha256 = "sha256-nGxJyH+2OBcB6rV7x3mvthUhP9fWaf5Mc0FO99SlGC8=";
        };
        buildInputs = old.buildInputs ++ [ super.tree-sitter ];
      });
    })
  ] ++ lib.optionals isDesktop [
    (self: super: {
      nari-pulse-profile = super.callPackage ./desktop/nari.nix {};
    })
    (self: super: {
      pulseaudio = super.pulseaudio.overrideAttrs (old: rec {
        _libOnly = lib.strings.hasInfix "lib" old.name;
        buildInputs =  old.buildInputs ++ lib.optional _libOnly super.nari-pulse-profile;
        # dont modify post install for libpulseaudio
        postInstall = if _libOnly then old.postInstall else old.postInstall + ''
        ln -s ${self.nari-pulse-profile}/razer-nari-input.conf       $out/share/pulseaudio/alsa-mixer/paths/razer-nari-input.conf
        ln -s ${self.nari-pulse-profile}/razer-nari-output-game.conf $out/share/pulseaudio/alsa-mixer/paths/razer-nari-output-game.conf
        ln -s ${self.nari-pulse-profile}/razer-nari-output-chat.conf $out/share/pulseaudio/alsa-mixer/paths/razer-nari-output-chat.conf
        ln -s ${self.nari-pulse-profile}/razer-nari-usb-audio.conf   $out/share/pulseaudio/alsa-mixer/profile-sets/razer-nari-usb-audio.conf
        '';
      });
      OVMF = super.OVMF.overrideAttrs (old: {
        patches = [ ./desktop/ovmf.patch ];
      });
      qemu_kvm = super.qemu_kvm.overrideAttrs (old: {
        patches = [ ./desktop/qemu.patch ] ++ old.patches;
        enableParallelBuilding = false;
      });
    })
  ];

  services.udev.packages = with pkgs; mkDesktop [ nari-pulse-profile openrgb ];
}
