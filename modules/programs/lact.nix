{ config, lib, pkgs, vars, ... }:
with lib;
{
  options.lact.enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config.lact.enable) {
    environment.systemPackages = with pkgs; [
      lact      # GPU control
    ];

    # Lact does not currently support automatically initializing the daemon
    systemd.services.lactd = {
      after = [ "multi-user.target" ];
      description = "AMDGPU Control Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''${pkgs.lact}/bin/lact daemon'';
        Nice = "-10";
      };
    };
  };

}
