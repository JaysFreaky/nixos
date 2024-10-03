{ config, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.openrgb;
in {
  options.myOptions.openrgb.enable = lib.mkEnableOption "OpenRGB";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ i2c-tools ];

    hardware.i2c.enable = true;

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb;

      /*package = pkgs.openrgb.overrideAttrs (_: {
        version = "pipeline";
        src = pkgs.fetchFromGitLab {
          owner = "CalcProgrammer1";
          repo = "OpenRGB";
          rev = "98eab49e999635cdf4764e3e8f986d6faa84e173";
          sha256 = "sha256-MDDcZamDo7dMEwVsLftXYZLmz+FD6ALbf00t987Woj4=";
        };
        postPatch = ''
          patchShebangs scripts/build-udev-rules.sh
          substituteInPlace scripts/build-udev-rules.sh \
            --replace "/usr/bin/env chmod" "${pkgs.coreutils}/bin/chmod"
        '';
      });*/
    };

    users.users.${vars.user}.extraGroups = [ "i2c" ];

  };
}
