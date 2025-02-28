{
  config,
  lib,
  pkgs,
  cfgOpts,
  myUser,
  ...
}: let
  bpc = {
    commit = "21f0500a14885be0030e956e3e7053932b0de7b6";
    sha256 = "sha256-vVo7KlKlQwWt5a3y2ff3zWFl8Yc9duh/jr4TC5sa0Y4=";
    version = "4.0.5.0";
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
        extensions = let
          inherit (pkgs.nur.repos.rycee) firefox-addons;

          # Releases are removed regularly
          bypass-paywalls = firefox-addons.bypass-paywalls-clean.override {
            version = "${bpc.version}";
            url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${bpc.version}.xpi&inline=false&commit=${bpc.commit}";
            sha256 = "${bpc.sha256}";
          };
        in [
          bypass-paywalls
        ] ++ builtins.attrValues {
          #inherit (firefox-addons)
            # Additional non-overridden extensions
          #;
        };
      };

      profiles.vanilla = {
        id = 1;
        name = "Vanilla";
      };
    };
  };
}
