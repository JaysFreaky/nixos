{ config, lib, vars, ... }: with lib; {
  options."1password".enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config."1password".enable) {
    home-manager.users.${vars.user} = {
      xdg.configFile = let
        onePasswordPkg = (config.programs._1password-gui.package);
      in {
        "autostart/1password.desktop".text = replaceStrings [ "Exec=1password %U" ] [ "Exec=${getExe onePasswordPkg} --silent %U" ] (lib.fileContents "${onePasswordPkg}/share/applications/1password.desktop");
      };
    };

    programs = {
      # CLI
      _1password.enable = false;
      # GUI
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${vars.user}" ];
      };
    };

  };
}
