{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "boot";
          type = "EF00";
          size = "1024MiB";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        root = {
          label = "root";
          size = "90%";
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
            };
          };
        };
      };
    };
  };

}
