{ config, lib, pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = { config, ... }: {
    # Autostart
    xdg.configFile."autostart/1password.desktop".source = config.lib.file.mkOutOfStoreSymlink "/run/current-system/sw/share/applications/1password.desktop";
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
}


