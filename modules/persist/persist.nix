{ ... }: {
  environment = {
    etc = {
      # Hardware clock tracking
      "adjtime".source = "/persist/etc/adjtime";
      # Matching journalctl entries
      "machine-id".source = "/persist/etc/machine-id";
    };

    # Persistance module handles directories better than etc.<name>.source
    persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/etc/NetworkManager"
        "/etc/nixos"
        "/var/lib/bluetooth"
        "/var/lib/flatpak"
        "/var/lib/NetworkManager"
      ];
    };
  };

}
