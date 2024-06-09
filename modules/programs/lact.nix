{ config, lib, pkgs, ... }: with lib; {
  options.lact.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.lact.enable) {
    environment.systemPackages = with pkgs; [ lact ];

    # Create service from package
    systemd.packages = with pkgs; [ lact ];
    # Autostart service at boot
    systemd.services.lactd.wantedBy = [ "multi-user.target" ];
  };

}
