{
  cfgOpts,
  config,
  lib,
  vars,
  ...
}: let
  cfg = cfgOpts."1password";
in {
  options.myOptions."1password".enable = lib.mkEnableOption "1Password";

  config = lib.mkIf (cfg.enable) {
    home-manager.users.${vars.user} = {
      xdg.configFile = let
        onePassword-pkg = config.programs._1password-gui.package;
      in {
        "autostart/1password.desktop".text = (lib.strings.replaceStrings
          [ "Exec=1password %U" ]
          [ "Exec=${lib.getExe onePassword-pkg} --silent %U" ]
          (lib.fileContents "${onePassword-pkg}/share/applications/1password.desktop")
        );
      };
    };

    programs = {
      _1password.enable = false; # CLI
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${vars.user}" ];
      };
    };
  };
}
