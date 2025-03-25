{
  disko.devices.disk.sda = {
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
            };
          };
        };
      };
    };
  };

  fileSystems."/mnt/nas" = {
    device = "oscuras:/mnt/user";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=5s"
    ];
  };

}
