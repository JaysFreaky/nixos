{ config, ... }: {
  boot.kernelParams = [ "resume_offset=7873792" ];
  boot.resumeDevice = "/dev/disk/by-uuid/aef4d7e2-c2c6-4e02-a9ef-3502218d5f89";
  fileSystems."/swap" = { device = "/dev/mapper/cryptroot"; fsType = "btrfs"; options = [ "subvol=swap" "compress=no" "noatime" ]; };
  swapDevices = [ { device = "/swap/swapfile"; } ];
}
