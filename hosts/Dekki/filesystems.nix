{
  boot = {
    # sudo btrfs inspect-internal map-swapfile -r /.swap/swapfile
    #kernelParams = [ "resume_offset=" ];
    resumeDevice = "/dev/disk/by-label/NixOS";
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "boot";
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };

        root = {
          label = "root";
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [
              "--force"
              "--label NixOS"
            ];
            subvolumes = {
              "root" = {
                mountOptions = [ "compress=zstd" "noatime" ];
                mountpoint = "/";
              };
              "home" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/home";
              };
              "nix" = {
                mountOptions = [ "compress=zstd" "noatime" ];
                mountpoint = "/nix";
              };
              "swap" = {
                mountpoint = "/.swap";
                swap.swapfile.size = "16G";
              };
            };
          };
        };
      };
    };
  };

}
