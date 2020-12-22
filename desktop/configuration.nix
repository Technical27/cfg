# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  networking.hostName = "desktop";


  hardware.cpu.intel.updateMicrocode = true;
  hardware.openrazer.enable = true;
  services.fstrim.enable = true;
  programs.java.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "intel_iommu=on" "kvm.ignore_msrs=1" "kvm_intel.nested=1" ];
  boot.kernelModules = [ "kvm_intel" "i2c-dev" "i2c-i801" "i2c-nct6775" ];
  boot.kernelPatches = [
    { name = "openrgb"; patch = ./openrgb.patch; }
    { name = "rdtsc"; patch = ./rdtsc.patch; }
    { name = "fsync"; patch = ./fsync.patch; }
  ];
  fileSystems."/media/hdd" =
    { device = "/dev/disk/by-uuid/cb1cdd76-7b53-4acd-8357-388562abb590";
      fsType = "ext4";
    };
  fileSystems."/media/ssd" =
    { device = "/dev/disk/by-uuid/034782cc-bc82-4940-bfa8-be7e656fc9ad";
      fsType = "ext4";
    };
  swapDevices = [ { label = "swap"; } ];

  services.gnome3.gnome-keyring.enable = true;

  services.resolved.enable = true;
  systemd.network = {
    enable = true;
    networks."main" = {
      name = "enp1s0";
      DHCP = "yes";
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.overlays = [
    (self: super: { razer-nari-pulseaudio-profile = super.callPackage ./nari.nix {}; })
    (self: super: { pulseaudio = super.pulseaudio.overrideAttrs (old: rec {
      _libOnly = lib.strings.hasInfix "lib" old.name;
      buildInputs =  old.buildInputs ++ lib.optional _libOnly super.razer-nari-pulseaudio-profile;
      # dont modify post install for libpulseaudio
      postInstall = if _libOnly then old.postInstall else old.postInstall + ''
      ln -s ${self.razer-nari-pulseaudio-profile}/razer-nari-input.conf       $out/share/pulseaudio/alsa-mixer/paths/razer-nari-input.conf
      ln -s ${self.razer-nari-pulseaudio-profile}/razer-nari-output-game.conf $out/share/pulseaudio/alsa-mixer/paths/razer-nari-output-game.conf
      ln -s ${self.razer-nari-pulseaudio-profile}/razer-nari-output-chat.conf $out/share/pulseaudio/alsa-mixer/paths/razer-nari-output-chat.conf
      ln -s ${self.razer-nari-pulseaudio-profile}/razer-nari-usb-audio.conf   $out/share/pulseaudio/alsa-mixer/profile-sets/razer-nari-usb-audio.conf
      '';
    }); })
    (self: super: {
      # libXNVCtrl32 = super.pkgsi686Linux.callPackage /home/aamaruvi/pkgs/nvctrl/nvctrl.nix {};
      # libXNVCtrl = super.callPackage /home/aamaruvi/pkgs/nvctrl/nvctrl.nix {};
      # mangohud = super.callPackage /home/aamaruvi/pkgs/mango/combined.nix {};
      OVMF = super.OVMF.overrideAttrs (old: {
        patches = [ ./ovmf.patch ];
      });
      qemu_kvm = super.qemu_kvm.overrideAttrs (old: {
        patches = old.patches ++ [ ./qemu.patch ];
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    curl nano

    # mangohud
    libappindicator-gtk3
  ];

  services.udev.packages = with pkgs; [
    razer-nari-pulseaudio-profile
  ];
  programs.gnupg.agent.enable = true;
  # hardware.pulseaudio.extraModules = with pkgs; [ razer-nari-pulseaudio-profile ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 25565 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable the GNOME Desktop Environment.
  nixpkgs.config.allowUnfree = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = with pkgs; [
    # mangohud
    vaapiVdpau
    libvdpau-va-gl
  ];
  hardware.pulseaudio.support32Bit = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  programs.fish.enable = true;
  users.extraUsers.aamaruvi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "plugdev" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.fish;
  };

  environment.variables = {
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    EDITOR = "nvim";
    MOZ_X11_EGL = "1";
  };

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuPackage = pkgs.qemu_kvm;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
  systemd.services.libvirtd.path = with pkgs; [ kmod killall bash coreutils config.boot.kernelPackages.cpupower ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.ip_forward" = 1;
    "vm.swappiness" = 10;
  };
  services.sshd.enable = true;

  systemd.user.services.razer-kbd = {
    description = "restore openrazer effects";
    wants = [ "dbus.service" ];
    after = [ "dbus.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nixFlakes}/bin/nix-shell --run 'python /home/aamaruvi/git/razer/main.py' /home/aamaruvi/git/razer/shell.nix";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}

