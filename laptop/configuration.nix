# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
   };

  # change btrfs options for subvolumes
  fileSystems = let
   default_opts = [ "noatime" "nodiratime" "discard=async" "compress-force=zstd:5" "ssd" "space_cache" "autodefrag" ];
  in {
   "/".options = default_opts;
   "/nix".options = default_opts;
   "/var".options = default_opts;
   "/home".options = default_opts;
 };

  boot.kernelParams = [ "snd_hda_intel.powersave=1" ];

  services.snapper.configs = {
    home = {
      subvolume = "/home";
      extraConfig = ''
        ALLOW_USERS=aamaruvi
        TIMELINE_CREATE=yes
      '';
    };
    root = {
      subvolume = "/";
      extraConfig = ''
        TIMELINE_CREATE=yes
      '';
    };
    var = {
      subvolume = "/var";
      extraConfig = ''
        TIMELINE_CREATE=yes
      '';
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot = {
    enable = true;
    editor = false;
  };
  services.blueman.enable = true;
  boot.plymouth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableAllFirmware = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.fwupd.enable = true;

  networking.firewall.enable = false;
  networking.wireless.iwd.enable = true;
  networking.hostName = "laptop";
  systemd.network.enable = true;

  services.resolved = {
    enable = true;
    dnssec = "allow-downgrade";
  };

  networking.hosts = {
    "10.200.200.1" = [ "yogs.tech" ];
  };

  systemd.network.networks."00-wifi" = {
    name = "wlan0";
    DHCP = "yes";
    networkConfig = {
      IPv6AcceptRA = "yes";
      IPv6PrivacyExtensions = "yes";
    };
  };

  systemd.network.netdevs."10-wg0" = {
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

  systemd.network.networks."20-wg0" = {
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
    # old routing rule, now created dynamically with wgvpn
    # routingPolicyRules = [{
    #   routingPolicyRuleConfig = {
    #     FirewallMark = 51000;
    #     InvertRule = true;
    #     Table = 1000;
    #     # Priority = 10;
    #   };
    # }];
  };

  programs.dconf.enable = true;
  services.gnome3.gnome-settings-daemon.enable = true;
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  programs.gnupg.agent.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  security.apparmor.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    reflector = true;
  };
  services.upower.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraModules = [ pkgs.pulseaudio-modules-bt ];
    package = pkgs.pulseaudioFull;
  };
  hardware.bluetooth.enable = true;

  nixpkgs.config = {
    pulseaudio = true;
    allowUnfree = true;
  };

  # sway
  programs.sway.enable = true;

  environment.systemPackages = with pkgs; [
    gsettings-desktop-schemas
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

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  programs.fish.enable = true;

  users.groups."storage" = {};
  users.users.aamaruvi = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "video" "input" "storage" ]; # Enable ‘sudo’ for the user.
  };

  # gnome keyring
  services.gnome3.gnome-keyring.enable = true;
  services.pipewire.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

  systemd.user.services.mpris-proxy = {
    description = "bluez mpris-proxy";
    after = [ "network.target" "pulseaudio.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };

  systemd.user.services.sway = {
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

  services.tlp.enable = true;
  powerManagement.enable = true;
  services.throttled.enable = false;

  environment.variables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    LIBVA_DRIVER_NAME = "i965";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    QT_QPA_PLATFORM = "wayland-egl";
    QT_WAYLAND_FORCE_DPI = "physical";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    EDITOR = "nvim";
  };
}

