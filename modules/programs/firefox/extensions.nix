let
  mkExt = guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${guid}/latest.xpi";
      installation_mode = "force_installed";
    };
  };
in builtins.listToAttrs [
  # 1Password
  (mkExt "{d634138d-c276-4fc8-924b-40a0ea21d284}")
  # Augmented Steam
  (mkExt "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}")
  # CanvasBlocker
  (mkExt "CanvasBlocker@kkapsner.de")
  # Dark Reader
  (mkExt "addon@darkreader.org")
  # Enhancer for YouTube
  (mkExt "enhancerforyoutube@maximerf.addons.mozilla.org")
  # Firefox Multi-Account Containters
  (mkExt "@testpilot-containers")
  # Proton VPN
  (mkExt "vpn@proton.ch")
  # SimpleLogin
  (mkExt "addon@simplelogin")
  # SponsorBlock
  (mkExt "sponsorBlocker@ajay.app")
  # Tabliss
  (mkExt "extension@tabliss.io")
  # TTV LOL PRO
  (mkExt "{76ef94a4-e3d0-4c6f-961a-d38a429a332b}")
  # uBlock Origin
  (mkExt "uBlock0@raymondhill.net")
]
