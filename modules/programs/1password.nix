{
  cfgOpts,
  config,
  lib,
  myUser,
  ...
}: let
  cfg = cfgOpts."1password";
in {
  options.myOptions."1password".enable = lib.mkEnableOption "1Password";

  config = lib.mkIf (cfg.enable) {
    # Allow _1password-gui to communicate w/ its browser extension
    environment.etc."1password/custom_allowed_browsers" = {
      mode = "0755";
      text = ''
        ${cfgOpts.browser}
      '';
    };

    home-manager.users.${myUser}.xdg.configFile."autostart/1password.desktop".text = let
      onePassword-pkg = config.programs._1password-gui.package;
    in (lib.strings.replaceStrings
      [ "Exec=1password %U" ]
      [ "Exec=${lib.getExe onePassword-pkg} --silent %U" ]
      (lib.fileContents "${onePassword-pkg}/share/applications/1password.desktop")
    );

    programs = {
      _1password.enable = false; # CLI
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ myUser ];
      };
    };

    users.users.${myUser}.extraGroups = [ "onepassword" ];
  };
}
