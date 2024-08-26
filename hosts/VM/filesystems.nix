{
  disko.devices.disk.vda = {
    type = "disk";
    device = "/dev/vda";
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
            };
          };
        };
      };
    };
  };

}
