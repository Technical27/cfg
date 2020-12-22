device: { config, pkgs, lib, ... }:

let
  isLaptop = device == "laptop";
  isDesktop = device == "desktop";
  mkLaptop = obj: lib.mkIf (isLaptop) obj;
  mkDesktop = obj: lib.mkIf (isDesktop) obj;
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
  in (mkLaptop {
    "/".options = default_opts;
    "/nix".options = default_opts;
    "/var".options = default_opts;
    "/home".options = default_opts;
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

  swapDevices = mkDesktop [{ label = "swap"; }];

  networking.hostName = device;

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams =
    (mkLaptop [ "snd_hda_intel.powersave=1" ])
    // (mkDesktop [ "intel_iommu=on" "kvm.ignore_msrs=1" "kvm_intel.nested=1" ]);

  systemd.network.enable = true;
  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
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

  environment.variables =
    (mkLaptop {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      LIBVA_DRIVER_NAME = "i965";
      MOZ_ENABLE_WAYLAND = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      QT_QPA_PLATFORM = "wayland-egl";
      QT_WAYLAND_FORCE_DPI = "physical";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    })
    // (mkDesktop {
      MOZ_X11_EGL = "1";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    })
    // ({
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

  # Laptop specific things
  boot.plymouth.enable = isLaptop;

  programs.sway.enable = isLaptop;
  programs.dconf.enable = isLaptop;

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

  services.snapper.configs = mkLaptop {
    home = {
      subvolume = "/home";
      extraConfig = ''
        ALLOW_USERS=aamaruvi
        TIMELINE_CREATE=yes
      '';
    };
    root = {
      subvolume = "/";
      extraConfig = "TIMELINE_CREATE=yes";
    };
    var = {
      subvolume = "/var";
      extraConfig = "TIMELINE_CREATE=yes";
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

    (
      pkgs.writeTextFile {
        name = "wgvpn";
        destination = "/bin/wgvpn";
        executable = true;
        text = ''
          #! ${pkgs.fish}/bin/fish
          if test (id -u) = 0
            echo "don't run this script as root, it will call sudo"
            exit 1
          end
          switch $argv[1]
            case up
              if test ! -f /tmp/.wgvpn
                sudo ip rule add not from all fwmark 51000 lookup 1000
                touch /tmp/.wgvpn
              else
                echo "already up"
                exit 1
              end
            case down
              if test -f /tmp/.wgvpn
                sudo ip rule delete not from all fwmark 51000 lookup 1000
                rm /tmp/.wgvpn
              else
                echo "not up"
                exit 1
              end
            case '*'
              echo "use 'up' or 'down' to activate/deactivate the wireguard vpn"
          end
        '';
      }
    )

    (
      pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.fish}/bin/fish

          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          systemctl --user start sway.service

          # poll for sway
          while test (count (pgrep sway)) -gt 1
            sleep 5
          end

          systemctl --user stop kanshi xdg-desktop-portal-wlr
        '';
      }
    )
  ];

  # Desktop specific things
  services.sshd.enable = isDesktop;
  services.fstrim.enable = isDesktop;
  programs.java.enable = isDesktop;
  hardware.openrazer.enable = isDesktop;
  networking.firewall.enable = isDesktop;

  services.xserver = mkDesktop {
    enable = true;
    videoDrivers = [ "nvidia" ];
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
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
    { name = "openrgb"; patch = ./desktop/openrgb.patch; }
    { name = "rdtsc"; patch = ./desktop/rdtsc.patch; }
    { name = "fsync"; patch = ./desktop/fsync.patch; }
  ];

  boot.kernel.sysctl = mkDesktop {
    "net.ipv6.conf.all.forwarding" = "1";
    "net.ipv6.conf.default.forwarding" = "1";
    "net.ipv4.ip_forward" = 1;
    "vm.swappiness" = 10;
  };

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

  nixpkgs.overlays = mkDesktop [
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
        patches = old.patches ++ [ ./desktop/qemu.patch ];
      });
    })
  ];

  services.udev.packages = mkDesktop [ pkgs.nari-pulse-profile ];
}
