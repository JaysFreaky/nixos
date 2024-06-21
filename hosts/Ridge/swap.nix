{ config, ... }: {
  boot.kernelParams = [ "resume_offset=8922368" ];
  boot.resumeDevice = "/dev/disk/by-uuid/c2a9583b-f601-469a-a14e-8cbe9700227e";
  fileSystems."/swap" = { device = "/dev/disk/by-partlabel/root"; fsType = "btrfs"; options = [ "subvol=swap" "compress=no" "noatime" ]; };
  swapDevices = [ { device = "/swap/swapfile"; } ];
}
