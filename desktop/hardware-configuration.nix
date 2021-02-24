# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b866a56d-17c7-4550-936a-8b0d834fe444";
      fsType = "ext4";
    };

  fileSystems."/media/ssd" =
    { device = "/dev/disk/by-uuid/034782cc-bc82-4940-bfa8-be7e656fc9ad";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/A385-5AEF";
      fsType = "vfat";
    };

  fileSystems."/media/hdd" =
    { device = "/dev/disk/by-uuid/cb1cdd76-7b53-4acd-8357-388562abb590";
      fsType = "ext4";
    };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
