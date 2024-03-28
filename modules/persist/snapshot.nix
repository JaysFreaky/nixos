{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.snapshot.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.snapshot.enable) {
    fileSystems."/" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

    services.btrfs.autoScrub = {
      fileSystems = [ "/root" ];
    };
  };
}
