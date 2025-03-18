{
  config,
  lib,
  pkgs,
  cfgOpts,
  myUser,
  nix-secrets,
  ...
}: let
  bpc = {
    commit = "21f0500a14885be0030e956e3e7053932b0de7b6";
    sha256 = "sha256-vVo7KlKlQwWt5a3y2ff3zWFl8Yc9duh/jr4TC5sa0Y4=";
    version = "4.0.5.0";
  };

  dohProvider = (
    if (hostName == "Ridge" || hostName == "T1" || hostName == "VM")
      then nix-secrets.dns.doh.int
    else nix-secrets.dns.doh.ext
  ) + hostName;
  hostName = config.networking.hostName;

  userName = config.users.users.${myUser}.description;
in {
  options.myOptions.browser = lib.mkOption {
    default = "floorp";
    description = "Which Firefox-based browser to configure via Home-Manager: Firefox, Floorp, or LibreWolf";
    type = lib.types.str;
  };

  config.home-manager.users.${myUser}.programs.${cfgOpts.browser} = {
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
    policies = import ./policies.nix { inherit dohProvider; };

    profiles.${myUser} = {
      id = 0;
      name = userName;
      isDefault = true;

      containers = import ./containers.nix;
      containersForce = true;
      search = import ./search.nix { inherit pkgs; };
      settings = import ./settings.nix { inherit config dohProvider; };

      # Search extensions at: https://nur.nix-community.org/repos/rycee/
      extensions.packages = let
        inherit (pkgs.nur.repos.rycee) firefox-addons;

        # BPC releases are regularly removed
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
}
