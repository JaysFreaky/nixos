{ config, lib, vars, ... }: let
  cfg = config.myOptions.syncthing;
in {
  options.myOptions.syncthing.enable = lib.mkEnableOption "Syncthing";

  config = lib.mkIf (cfg.enable) {
    services.syncthing = {
      enable = true;
      configDir = "/home/${vars.user}/.config/syncthing";
      dataDir = "/home/${vars.user}";
      guiAddress = "127.0.0.1:8384";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      user = "${vars.user}";

      settings = {
        options.urAccepted = -1;

        devices = {
          "NAS" = { id = "FN25ISC-P52A3WA-GRV4SIR-YI4KBMM-2I5BECF-32SLV5B-5DADP5B-YSMVIQ4"; };
        };

        folders = {
          "obsidian" = {
            devices = [ "NAS" ];
            label = "Obsidian";
            path = "/home/${vars.user}/Sync/Obsidian";
            versioning = {
              type = "simple";
              params = {
                cleanoutDays = "0";
                cleanInterval = "3600";
                keep = "10";
              };
            };
          };
        };
      };
    };

    users.users.${vars.user}.extraGroups = [ "syncthing" ];

  };
}
