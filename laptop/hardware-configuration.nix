{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
      fsType = "btrfs";
      options = [ "subvol=@" "noatime" "compress=zstd:5" "ssd" ]
        ++ (lib.optionals config.boot.initrd.systemd.enable [ "x-systemd.after=local-fs-pre.target" ]);
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
      fsType = "btrfs";
      options = [ "subvol=@home" "noatime" "compress=zstd:5" "ssd" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
      fsType = "btrfs";
      options = [ "subvol=@nix" "noatime" "compress=zstd:5" "ssd" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-uuid/8e823de4-e182-41d0-8793-8f3fe59932da";
      fsType = "btrfs";
      options = [ "subvol=@swap" "noatime" "ssd" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/189D-9B2F";
      fsType = "vfat";
    };

  boot.resumeDevice = config.fileSystems."/swap".device;
  boot.kernelParams = [ "resume_offset=18093312" ];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.cpu.intel.updateMicrocode = true;
  # high-resolution display
  hardware.video.hidpi.enable = true;
}
