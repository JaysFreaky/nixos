{ config, pkgs, vars, ... }: let
  addons = pkgs.callPackage ./addons.nix {
    inherit (pkgs.nur.repos.rycee.firefox-addons) buildFirefoxXpiAddon;
  };
  bpc = {
    version = "3.7.9.0";
    sha256 = "sha256-2qERhC6qVPbMnnTEG9zdEknZ02cF6LXF7U6hNI1i1Uw=";
  };
  firefox-addons = pkgs.nur.repos.rycee.firefox-addons;
in {
  environment.systemPackages = with pkgs; [
    # Hardware video acceleration
    ffmpeg
  ];

  home-manager.users.${vars.user} = {
    programs.firefox = {
      enable = true;

      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        FirefoxHome = {
          Search = false;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
        };
        UserMessaging = {
          WhatsNew = false;
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          UrlbarInterventions = false;
          SkipOnboarding = true;
          MoreFromMozilla = false;
        };
      };

      profiles.${vars.user} = {
        id = 0;
        isDefault = true;
        name = "${vars.name}";
        #userChrome = builtins.readFile ./userChrome.css;
        #userContent = builtins.readFile ./userContent.css;

        containers = import ./containers.nix;
        containersForce = true;

        # Search extensions at: https://nur.nix-community.org/repos/rycee/
        extensions = with firefox-addons; [
          (bypass-paywalls-clean.override {   # Previous releases can be deleted, so overriding with latest version
            version = bpc.version;
            #url = "https://github.com/bpc-clone/bpc_updates/releases/download/latest/bypass_paywalls_clean-${bpc.version}.xpi";
            url = "https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass_paywalls_clean-${bpc.version}.xpi";
            sha256 = bpc.sha256;
          })
          canvasblocker
          darkreader
          enhancer-for-youtube
          multi-account-containers
          nighttab
          onepassword-password-manager
          simplelogin
          sponsorblock
          ublock-origin
        ] ++ (with addons; [
          ttv-lol-pro
        ]);

        search = import ./search.nix { inherit pkgs; };
        settings = import ./settings.nix { inherit config; };
      };

      profiles.vanilla = {
        id = 1;
        name = "Vanilla";
      };
    };
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = [ "firefox.desktop" ];
  };

}
