{
  config,
  lib,
  pkgs,
  cfgOpts,
  myUser,
  ...
}: let
  cfg = cfgOpts.openrgb;
in {
  options.myOptions.openrgb.enable = lib.mkEnableOption "OpenRGB";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ pkgs.i2c-tools ];

    hardware.i2c.enable = true;

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb.overrideAttrs (_: {
        version = "pipeline-v0.91";
        src = pkgs.fetchFromGitLab {
          owner = "CalcProgrammer1";
          repo = "OpenRGB";
          rev = "a7cdbb384490ad15010754f0d7b8baef3864eff4";
          sha256 = "sha256-+spXyT4Roc6pLAfzTBBPoHIgc69lJ+gYMpiTs+NdTdY=";
        };
        postPatch = ''
          patchShebangs scripts/build-udev-rules.sh
          substituteInPlace scripts/build-udev-rules.sh \
            --replace "/usr/bin/env chmod" "${pkgs.coreutils}/bin/chmod"
        '';
      });
    };

    systemd.user.services.openrgb = {
      enable = false;
      description = "Launch OpenRGB after logon";
      serviceConfig = {
        ExecStart = "${lib.getExe config.services.hardware.openrgb.package} --startminimized";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      wantedBy = [ "graphical-session.target" ];
    };

    users.users.${myUser}.extraGroups = [ "i2c" ];
  };
}
