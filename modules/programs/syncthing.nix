{
  cfgOpts,
  config,
  lib,
  myUser,
  ...
}: let
  cfg = cfgOpts.syncthing;
in {
  options.myOptions.syncthing.enable = lib.mkEnableOption "Syncthing";

  config = lib.mkIf (cfg.enable) {
    services.syncthing = {
      enable = true;
      configDir = "/home/${myUser}/.config/syncthing";
      dataDir = "/home/${myUser}";
      guiAddress = "127.0.0.1:8384";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      user = myUser;
      settings = {
        devices."NAS".id = "FN25ISC-P52A3WA-GRV4SIR-YI4KBMM-2I5BECF-32SLV5B-5DADP5B-YSMVIQ4";
        folders = {
          "music" = lib.mkIf (config.networking.hostName == "FW13") {
            enable = true;
            devices = [ "NAS" ];
            label = "Music";
            path = "/home/${myUser}/Music";
          };

          "obsidian" = {
            enable = true;
            devices = [ "NAS" ];
            label = "Obsidian";
            path = "/home/${myUser}/Obsidian";
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
        options.urAccepted = -1;
      };
    };

    users.users.${myUser}.extraGroups = [ "syncthing" ];
  };
}
