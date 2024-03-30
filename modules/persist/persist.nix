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
    };

    # Persistance module handles directories better than etc.<name>.source
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager"
        "/etc/nixos"
        "/usr/local/bin"
        "/var/lib/bluetooth"
        "/var/lib/flatpak"
        "/var/lib/NetworkManager"
      ];
    };
  };
}
