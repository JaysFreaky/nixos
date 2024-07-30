{ buildFirefoxXpiAddon, lib }: {
  ttv-lol-pro = buildFirefoxXpiAddon rec {
    pname = "ttv-lol-pro";
    version = "2.3.7";
    addonId = "{76ef94a4-e3d0-4c6f-961a-d38a429a332b}";
    url = "https://addons.mozilla.org/firefox/downloads/file/4280177/ttv-lol-pro-${version}.xpi";
    sha256 = "2e71c1fa3f5108cf77b1ca8b5a32955584be893ae151a27cd32d10073ae56820";
    meta = with lib; {
      homepage = "https://github.com/younesaassila/ttv-lol-pro";
      description = "TTV LOL PRO removes most livestream ads from Twitch.";
      license = licenses.gpl3;
      mozPermissions = [
        "proxy"
        "storage"
        "webRequest"
        "webRequestBlocking"
        "https://*.live-video.net/*"
        "https://*.ttvnw.net/*"
        "https://*.twitch.tv/*"
        "https://perfprod.com/ttvlolpro/telemetry"
        "https://www.twitch.tv/*"
        "https://m.twitch.tv/*"
      ];
      platforms = platforms.all;
    };
  };

}
