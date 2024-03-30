{ config, lib, pkgs, vars, ... }:

{
  environment = {
    etc = {
      # Hardware clock tracking
      "adjtime".source = "/persist/etc/adjtime";
      # Matching journalctl entries
      "machine-id".source = "/persist/etc/machine-id";
      "nix/id_rsa".source = "/persist/etc/nix/id_rsa";
      "ssh/ssh_host_rsa_key".source = "/persist/etc/ssh/ssh_host_rsa_key";
      "ssh/ssh_host_rsa_key.pub".source = "/persist/etc/ssh/ssh_host_rsa_key.pub";
      "ssh/ssh_host_ed25519_key".source = "/persist/etc/ssh/ssh_host_ed25519_key";
      "ssh/ssh_host_ed25519_key.pub".source = "/persist/etc/ssh/ssh_host_ed25519_key.pub";

      # Directories
      "nixos".source = "/persist/etc/nixos/";
      "NetworkManager".source = "/persist/etc/NetworkManager/";
    };
  };

  systemd.tmpfiles.rules = [
    "L /usr/local/bin - - - - /persist/usr/local/bin"
    "L /var/lib/bluetooth - - - - /persist/var/lib/bluetooth"
    "L /var/lib/flatpak - - - - /persist/var/lib/flatpak"
    "L /var/lib/NetworkManager - - - - /persist/var/lib/NetworkManager"
  ];
}
