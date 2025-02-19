{
  cfgOpts,
  config,
  lib,
  myUser,
  pkgs,
  ...
}: let
  bpc = {
    commit = "c6a7d5a36efe41db1a248637d6694f68c30a55e1";
    sha256 = "sha256-mXDE02yM78nv3UBkAP9JNFsm+Gz2bFDhENZjiaLRZ4w=";
    version = "4.0.2.4";
  };
  browser = cfgOpts.browser;
  userName = config.users.users.${myUser}.description;
in {
  options.myOptions.browser = lib.mkOption {
    default = "floorp";
    description = "Whether to use the Firefox or Floorp Home-Manager option";
    type = lib.types.str;
  };

  config.home-manager.users.${myUser} = {
    programs.${browser} = {
      enable = true;
      nativeMessagingHosts = (
        lib.optionals (cfgOpts.desktops.gnome.enable) [
          pkgs.gnome-browser-connector
        ]
      ) ++ (
        lib.optionals (cfgOpts.desktops.kde.enable) [
          pkgs.kdePackages.plasma-browser-integration
        ]
      );
      policies = import ./policies.nix;

      profiles.${myUser} = {
        id = 0;
        name = userName;
        isDefault = true;

        containers = import ./containers.nix;
        containersForce = true;
        search = import ./search.nix { inherit pkgs; };
        settings = import ./settings.nix { inherit config; };

        # Search extensions at: https://nur.nix-community.org/repos/rycee/
        extensions = with pkgs.nur.repos.rycee.firefox-addons; let
          bypass-paywalls = bypass-paywalls-clean.override {
            version = "${bpc.version}";
            url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${bpc.version}.xpi&inline=false&commit=${bpc.commit}";
            sha256 = "${bpc.sha256}";
          };
        in [
          bypass-paywalls   # Previous releases get deleted regularly
        ];
      };

      profiles.vanilla = {
        id = 1;
        name = "Vanilla";
      };
    };
  };
}
