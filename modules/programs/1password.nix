{ config, lib, pkgs, vars, ... }:
with lib;
{
  options."1password".enable = mkOption {
    default = false;
    type = types.bool;
  };

  config = mkIf (config."1password".enable) {
    home-manager.users.${vars.user} = { config, ... }: {
      # Autostart
      #xdg.configFile."autostart/1password.desktop".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/share/applications/1password.desktop";
      xdg.configFile."autostart/1password.desktop".text = ''
        [Desktop Entry]
        Categories=Office;
        Comment=Password manager and secure wallet
        Exec=1password --silent %U
        Icon=1password
        MimeType=x-scheme-handler/onepassword;
        Name=1Password
        StartupWMClass=1Password
        Terminal=false
        Type=Application
      '';
    };

    programs = {
      # CLI
      _1password.enable = true;
      # GUI
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "${vars.user}" ];
      };
    };
  };

}


