{ config, pkgs, vars, ... }:
let
  inherit (config.nur.repos.rycee) firefox-addons;
in {
  home-manager.users.${vars.user} = {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      profiles.default = {
        id = 0;
        isDefault = true;
        name = "Default";
        #userChrome = builtins.readFile ./userChrome.css;
        #userContent = builtins.readFile ./userContent.css;

        containers = {
          "Amazon" = {
            color = "yellow";
            icon = "cart";
            id = "1";
          };
          "Google" = {
            color = "red";
            icon = "fence";
            id = "0";
          };
          "Banking" = {
            color = "green";
            icon = "dollar";
            id = "2";
          };
        };

        # Search extensions at: https://nur.nix-community.org/repos/rycee/
        extensions = with firefox-addons; [
          #adaptive-tab-bar-color (Not added to repo yet)
          bypass-paywalls-clean
          canvasblocker
          darkreader
          enhancer-for-youtube
          multi-account-containers
          nighttab
          onepassword-password-manager
          #proton-pass
          pywalfox
          simplelogin
          sponsorblock
          ublock-origin
        ];

        search = {
          default = "Startpage";
          force = true;
          privateDefault = "Google";

          engines = {
            "Startpage" = {
              definedAliases = [ "@sp" ];
              icon = "https://www.startpage.com/sp/cdn/favicons/favicon--default.ico";

              urls = [{
                template = "https://www.startpage.com/sp/search";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Google" = {
              definedAliases = [ "@g" ];
              icon = "https://www.google.com/favicon.ico";

              urls = [{
                template = "https://www.google.com/search";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Home Manager Options" = {
              definedAliases = [ "@hm" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

              urls = [{
                template = "https://home-manager-options.extranix.com/";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Nix Packages" = {
              definedAliases = [ "@np" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };

            "Nix Options" = {
              definedAliases = [ "@no" ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "type"; value = "options"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
            };
          };
        };

        settings = {
          # These options are mainly from ArkenFox, with a few modifications here and there
          # https://github.com/arkenfox/user.js/blob/master/user.js

          ##########################################################
          # Address Bar / Search - Suggestions
          ##########################################################
          # 'Use this search engine in Private Windows'
            "browser.search.separatePrivateDefault.ui.enabled" = true;
          # 'Choose a different default search engine for Private Windows only'
            "browser.search.separatePrivateDefault" = true;
            "browser.urlbar.placeholderName.private" = "Google";
          # 'Show search suggestions'
            "browser.search.suggest.enabled" = false;
            "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.quicksuggest.scenario" = "offline";
          # URL bar search shortcuts (*,^,%)
            "browser.urlbar.shortcuts.bookmarks" = false;
            "browser.urlbar.shortcuts.history" = false;
            "browser.urlbar.shortcuts.tabs" = false;
          # 'Show search suggestions ahead of browsing history in address bar results'
            "browser.urlbar.showSearchSuggestionsFirst" = false;
          # FeatureGates
            "browser.urlbar.addons.featureGate" = false;
            "browser.urlbar.clipboard.featureGate" = false;
            "browser.urlbar.richSuggestions.featureGate" = false;
            "browser.urlbar.weather.featureGate" = false;
            "browser.urlbar.yelp.featureGate" = false;
          # 'Address Bar — Firefox Suggest'
            "browser.urlbar.suggest.addons" = false;
            "browser.urlbar.suggest.clipboard" = false;
            "browser.urlbar.suggest.bookmark" = true;
            "browser.urlbar.suggest.engines" = false;
            "browser.urlbar.suggest.history" = false;
            "browser.urlbar.suggest.mdn" = false;
            "browser.urlbar.suggest.openpage" = false;
            # 'Suggestions from Firefox'
              "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            # 'Suggestions from sponsors'
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.suggest.recentsearches" = false;
            "browser.urlbar.suggest.remotetab" = false;
            "browser.urlbar.suggest.topsites" = false;
            "browser.urlbar.suggest.trending" = false;
            "browser.urlbar.suggest.weather" = false;
            "browser.urlbar.suggest.yelp" = false;


          ##########################################################
          # Autofill / Forms
          ##########################################################
          # 'Remember search and form history'
            "browser.formfill.enable" = false;
          "dom.forms.autocomplete.formautofill" = false;
          # 'Save and fill addresses'
            "extensions.formautofill.addresses.enabled" = false;
          # 'Save and fill payment methods'
            "extensions.formautofill.creditCards.enabled" = false;
          # 'Fill usernames and passwords automatically'
            "signon.autofillForms" = false;
          # Formless login capture
            "signon.formlessCapture.enabled" = false;
          "signon.passwordEditCapture.enabled" = false;
          # 'Ask to save passwords' and greys out: Fill user/pass automatically, Suggest strong passwords, Suggest Firefox Relay
            "signon.rememberSignons" = false;


          ##########################################################
          # Cache / History
          ##########################################################
          # Disable cache to disk
            "browser.cache.disk.enable" = false;
            "browser.cache.disk.smart_size.enabled" = false;
          # Keep private media cache in memory
            "browser.privatebrowsing.forceMediaMemoryCache" = true;
            "media.memory_cache_max_size" = 65536;
          # 0=Everywhere, 1=Unencrypted, 2=Nowhere
            "browser.sessionstore.privacy_level" = 2;
          "layout.css.visited_links_enabled" = false;
          # 'Remember browsing and download history'
            "places.history.enabled" = false;
          # Respects site exceptions
            "privacy.clearOnShutdown.cache" = true;
            "privacy.clearOnShutdown.cookies" = true;
            "privacy.clearOnShutdown.downloads" = true;
            "privacy.clearOnShutdown.formdata" = true;
            "privacy.clearOnShutdown.history" = true;
            "privacy.clearOnShutdown.offlineApps" = true;
            "privacy.clearOnShutdown.openWindows" = true;
            "privacy.clearOnShutdown.sessions" = true;
            "privacy.clearOnShutdown.siteSettings" = true;
            "privacy.clearOnShutdown_v2.cache" = true;
            "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
            "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
            "privacy.clearOnShutdown_v2.siteSettings" = true;
          # Ignores site exceptions
            "privacy.cpd.cache" = true;
            "privacy.cpd.cookies" = false;
            "privacy.cpd.downloads" = true;
            "privacy.cpd.formdata" = true;
            "privacy.cpd.history" = true;
            "privacy.cpd.offlineApps" = false;
            "privacy.cpd.openWindows" = false;
            "privacy.cpd.sessions" = true;
            "privacy.cpd.siteSettings" = false;
          "privacy.history.custom" = true;
          "privacy.sanitize.pending" = ''
            [{"id":"shutdown","itemsToClear":["cache","history","formdata","downloads"],"options":{}},{"id":"newtab-container","itemsToClear":[],"options":{}}]
          '';
          "privacy.sanitize.sanitizeOnShutdown" = true;
          "privacy.sanitize.timeSpan" = 0;


          ##########################################################
          # DoH / DNS
          ##########################################################
          "doh-rollout.balrog-migration-done" = true;
          "doh-rollout.disable-heuristics" = true;
          "doh-rollout.doneFirstRun" = true;
          "doh-rollout.home-region" = "US";
          # Limit DNS cache to the past 100 entries
            "network.dnsCacheEntries" = 100;
          # 0=default, 2=TRR first, 3=TRR only, 5=off
            "network.trr.mode" = 3;
          # Make these the same URL
            "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
            "network.trr.uri" = "https://dns.quad9.net/dns-query";


          ##########################################################
          # HTTPS
          ##########################################################
          ## TLS / SSL
            # Advanced info on insecure connection pages
              #"browser.xul.error_pages.expert_bad_cert" = true;
            # Require safe negotiation
              "security.ssl.require_safe_negotiation" = true;
            # Show warning on padlock for broken security
              "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            # 0-Round-trip time
              "security.tls.enable_0rtt_data" = false;

          ## OCSP
            "security.OCSP.enabled" = 1;
            "security.OCSP.require" = true;

          ## CERTS
            # 0=disabled, 1=user, 2=strict
              "security.cert_pinning.enforcement_level" = 2;
            # Enable below crlite filters
              "security.remote_settings.crlite_filters.enabled" = true;
            # 0=disabled, 1=telemetry, 2=enforce both not/revoked, 3=enforce not revoked - defer to ocsp for revoked
              "security.pki.crlite_mode" = 2;

          ## Mixed Content
            # HTTPS-only
              "dom.security.https_only_mode" = true;
            # HTTPS-only private browsing
              #"dom.security.https_only_mode_pbm" = true;
            # Local resources upgraded
              "dom.security.https_only_mode.upgrade_local" = true;
            # If no response in 3 seconds, check if HTTPS is supported. If true, this timeout can take 90 seconds
              "dom.security.https_only_mode_send_http_background_request" = false;
            # Block insecure content on HTTPS pages
              "security.mixed_content.block_display_content" = true;


          ##########################################################
          # Location
          ##########################################################
          # Does this even matter? - Behind a prompt
            "geo.enabled" = false;
          # High accuracy
            "geo.provider.geoclue.always_high_accuracy" = false;
          # Windows
            "geo.provider.ms-windows-location" = false;
          # Provider used instead of Google if enabled
            "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
          # Linux
            "geo.provider.use_geoclue" = false;
            "geo.provider.use_gpsd" = false;
          # MAC LOL
            "geo.provider.use_corelocation" = false;


          ##########################################################
          # Misc
          ##########################################################
          # Improve performance
            "accessibility.force_disabled" = 1;
          # Disable pinch to zoom
            "apz.gtk.touchpad_pinch.enabled" = false;
          # Disable about:config warning
            "browser.aboutConfig.showWarning" = false;
          # First-run
            "browser.aboutwelcome.enabled" = false;
            "browser.startup.firstrunSkipsHomepage" = false;
          # Disable default bookmarks (toolbar, other, etc)
            "browser.bookmarks.restore_default_bookmarks" = false;
          # Enable mobile bookmarks category
            "browser.bookmarks.showMobileBookmarks" = true;
          # Ctrl+tab by tab order instead of use
            "browser.ctrlTab.recentlyUsedOrder" = false;
          # Disable what's new toolbar
            "browser.messaging-system.whatsNewPanel.enabled" = false;
          # Search region
            "browser.search.region" = "US";
          # FF stays open with last tab closed
            #"browser.tabs.closeWindowWithLastTab" = false;
          # Warn about closing FF with multiple tabs open
            "browser.tabs.warnOnClose" = true;
          # Show bookmarks toolbar - always, newtab, never
            "browser.toolbars.bookmarks.visibility" = "never";
          # All instances highlighted on search
            "findbar.highlightAll" = true;
          # Force hardware acceleration/decoding
            "dom.webgpu.enabled" = true;
            "gfx.webrender.all" = true;
            "layers.acceleration.force-enabled" = true;
            "media.ffmpeg.vaapi.enabled" = true;
            # If choppy video, disable
              "layers.gpu-process.enabled" = true;
              "media.gpu-process-decoder" = true;
          # No audio/video autoplay
            "media.autoplay.default" = 5;
          # Allow userChrome customizations
            "svg.context-properties.content.enabled" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          # Switch tabs by scrolling
            "toolkit.tabbox.switchByScrolling" = true;
          # Native Linux file browser
            "widget.use-xdg-desktop-portal.file-picker" = 1;
          # Fix possible Wayland video flickering issue
            #"widget.wayland.opaque-region.enabled" = false;


          ##########################################################
          # New Tab / Startup
          ##########################################################
          "browser.newtab.extensionControlled" = true;
          "browser.newtab.privateAllowed" = false;
          # Clear default sites shortcuts
            "browser.newtabpage.activity-stream.default.sites" = "";
          # Custom shortcuts
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
          # Disable these sections from being shown
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
          # Sponsored stories
            "browser.newtabpage.activity-stream.showSponsored" = false;
          # Sponsored shortcuts
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          # Default start page
            "browser.newtabpage.enabled" = false;
          # about:blank, about:home, custom URL
            # Set home to Nighttab extension
            #"browser.startup.homepage" = "moz-extension://6e52be8f-0de4-48fc-b276-8ee3e68d003c/index.html";
          # 0=blank, 1=home, 2=last visited page, 3=resume previous session
            #"browser.startup.page" = 1;


          ##########################################################
          # Pocket
          ##########################################################
          ## New tab / telemetry
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
            "browser.newtabpage.activity-stream.discoverystream.endpoints" = "";
            "browser.newtabpage.activity-stream.discoverystream.saveToPocketCard.enabled" = false;
            "browser.newtabpage.activity-stream.discoverystream.sendToPocket.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.pocketCta" = "";
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
          "browser.urlbar.pocket.featureGate" = false;
          "browser.urlbar.suggest.pocket" = false;
          "extensions.pocket.api" = "";
          "extensions.pocket.bffApi" = "";
          "extensions.pocket.enabled" = false;
          "extensions.pocket.oAuthConsumerKey" = "";
          "extensions.pocket.oAuthConsumerKeyBff" = "";
          "extensions.pocket.showHome" = false;
          "extensions.pocket.site" = "";


          ##########################################################
          # Privacy
          ##########################################################
          ## Downloads
            # Open download navbar on each download
              "browser.download.alwaysOpenPanel" = true;
            # Do not add downloads to recent file history
              "browser.download.manager.addToRecentDocs" = false;
            # Download file into /tmp, open, and delete when done (PDFs, etc)
              "browser.download.start_downloads_in_tmp_dir" = true;
              "browser.helperApps.deleteTempFileOnExit" = true;

          ## Safe Browsing
            # 'Block dangerous downloads'
              "browser.safebrowsing.downloads.enabled" = false;
            # 'Warn you about unwanted and uncommon software'
              "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
              "browser.safebrowsing.downloads.remote.block_uncommon" = false;
              # Google is used to verify downloads
                #"browser.safebrowsing.downloads.remote.enabled" = false;
                #"browser.safebrowsing.downloads.remote.url" = "";
            # 'Block dangerous and deceptive content'
              "browser.safebrowsing.malware.enabled" = false;
              "browser.safebrowsing.phishing.enabled" = false;

          ## DRM
            # DRM UI
              "browser.eme.ui.enabled" = true;
            # DRM
              "media.eme.enabled" = false;

          ## WebRTC / DRM tracking
            "media.getusermedia.screensharing.enabled" = false;
            "media.gmp-provider.enabled" = false;
            "media.peerconnection.ice.default_address_only" = true;
            "media.peerconnection.ice.no_host" = true;
            "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
            # Pointless?
              #"media.peerconnection.enabled" = false;
              #"media.peerconnection.identity.timeout" = 1;
              #"media.peerconnection.turn.disable" = true;
              #"media.peerconnection.use_document_iceservers" = false;
              #"media.peerconnection.video.use_rtx" = false;
              #"media.peerconnection.video.vp9_enabled" = false;

          ## Captive Portal
            "captivedetect.canonicalURL" = "";
            "network.captive-portal-service.enabled" = false;

          ## Prefetching
            # Disable preloading of bookmarks
              "browser.places.speculativeConnect.enabled" = false;
            # Click tracking
              "browser.send_pings" = false;
            # Disable preloading of autocomplete URLs
              "browser.urlbar.speculativeConnect.enabled" = false;
            "network.dns.disablePrefetch" = true;
            "network.dns.disablePrefetchFromHTTPS" = true;
            # Disable mouseover opening a connection to link
              "network.http.speculative-parallel-limit" = 0;
            "network.predictor.enable-prefetch" = false;
            "network.predictor.enabled" = false;
            "network.prefetch-next" = false;

          ## Proxy
            "network.file.disable_unc_paths" = true;
            "network.gio.supported-protocols" = "";
            "network.proxy.socks_remote_dns" = true;

          ## Referers
            #0=full, 1=scheme+host+port+path, 2=scheme+host+port
              # Whether to send referrer across origins (if sites break, use 1)
                "network.http.referer.XOriginPolicy" = 2;
              # How much referrer to send across origins
                "network.http.referer.XOriginTrimmingPolicy" = 2;

          ## PDFs
            # Display PDFs in browser
              "pdfjs.disabled" = false;
              "pdfjs.enabledCache.state" = true;
            # Disable PDF scripting
              "pdfjs.enableScripting" = false;

          ## Fingerprinting / Tracking
            # 'Send websites a “Do Not Track” request' - Not needed with 'strict' ETP
              #"privacy.donottrackheader.enabled" = true;
            # Fingerprinting - ignored when RFP is enabled
              "privacy.fingerprintingProtection" = true;
              "privacy.fingerprintingProtection.pbmode" = true;
            # Enabling throws off timezone - using CanvasBlocker instead
              "privacy.resistFingerprinting" = false;
              "privacy.resistFingerprinting.pbmode" = true;

          ## Containers
            # Display container tabs
              "privacy.userContext.ui.enabled" = true;
            # 'Enable Container Tabs'
              "privacy.userContext.enabled" = true;
            # Use CanvasBlocker with Containers
              "privacy.userContext.extension" = "CanvasBlocker@kkapsner.de";

          # Website tracking
            "beacon.enabled" = false;
          # 'Enhanced Tracking Protection' - standard or strict
            "browser.contentblocking.category" = "strict";
          # Open links in tabs instead of new windows by default
            "browser.link.open_newwindow" = 3;
          # Page thumbnail generator
            "browser.pagethumbnails.capturing_disabled" = true;
          # Disable middle click opening new tabs with recent clipboard
            "browser.tabs.searchclipboardfor.middleclick" = false;
          # Disable backend so remote sites can't use it
            "browser.uitour.enabled" = false;
            "browser.uitour.url" = "";
          # Disable battery stats sent
            "dom.battery.enabled" = false;
          # Prevent scripts from moving/resizing windows
            "dom.disable_window_move_resize" = true;
          # Site compatibility
            "extensions.webcompat.enable_shims" = true;
            "extensions.webcompat.perform_injections" = true;
            "extensions.webcompat.perform_ua_overrides" = true;
          # Disable spellcheck
            "layout.spellcheckDefault" = 0;
          # Limit HTTP credential auth
            # 0=Don't allow, 1=Don't allow cross-origin, 2=Allow
            "network.auth.subresource-http-auth-allow" = "1";
          # Periodic checks to check network connection
            "network.connectivity-service.enabled" = false;
          # Display characters used in phishing attacks
            "network.IDN_show_punycode" = true;
          # Plz respect my privacy
            "privacy.globalprivacycontrol.enabled" = true;
            "privacy.globalprivacycontrol.functionality.enabled" = true;
          # Yubikey
            "security.webauth.webauthn" = true;
            "security.webauth.webauthn_enable_softtoken" = true;
            "security.webauth.webauthn_enable_usbtoken" = true;
          # 'Show alerts about passwords for breached websites'
            "signon.management.page.breach-alerts.enabled" = false;
          # Disable access to GPU
            "webgl.disable-wgl" = true;
            "webgl.disabled" = true;


          ##########################################################
          # Sync
          ##########################################################
          "identity.fxaccounts.account.device.name" = config.networking.hostName;
          # addons,addresses,bookmarks,creditcards,forms,history,passwords,prefs,tabs
            "services.sync.declinedEngines" = "addons,addresses,creditcards,forms,history,passwords,prefs";
          "services.sync.deletePwdFxA" = true;
          "services.sync.engine.addons" = false;
          "services.sync.engine.addresses" = false;
          "services.sync.engine.bookmarks" = true;
          "services.sync.engine.creditcards" = false;
          "services.sync.engine.history" = false;
          "services.sync.engine.passwords" = false;
          "services.sync.engine.prefs" = false;
          "services.sync.engine.tabs" = true;
          #"services.sync.username" = "";


          ##########################################################
          # Telemetry
          ##########################################################
          ## Studies
          "app.normandy.api_url" = "";
          "app.normandy.enabled" = false;
          "app.normandy.first_run" = false;
          "app.normandy.shieldLearnMoreUrl" = "";
          "app.normandy.user_id" = "0";
          # 'Allow Firefox to install and run studies'
            "app.shield.optoutstudies.enabled" = false;

          ## Crash Reporting
          "breakpad.reportURL" = "";
          # 'Allow Firefox to send backlogged crash reports on your behalf'
            "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
          "browser.crashReports.unsubmittedCheck.enabled" = false;
          "browser.tabs.crashReporting.sendReport" = false;

          ## Recommendations
          # Disabled with health reports disabled
            "browser.discovery.enabled" = false;
          # Recommend extensions as you browse
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          # Recommend features as you browse
            "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          # Recommendation pane in about:addons
            "extensions.getAddons.cache.enabled" = false;
            "extensions.getAddons.showPane" = false;
          # Recommendation pane in about:addons - Extensions/Themes
            "extensions.htmlaboutaddons.recommendations.enabled" = false;

          ## Telemetry
          "browser.contentblocking.report.hide_vpn_banner" = true;
          "browser.newtabpage.activity-stream.feeds.telemetry" = false;
          "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
          "browser.newtabpage.activity-stream.telemetry" = false;
          "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
          "browser.ping-centre.telemetry" = false;
          # Shopping experience
            "browser.shopping.experience2023.ads.enabled" = false;
            "browser.shopping.experience2023.ads.userEnabled" = false;
            "browser.shopping.experience2023.autoOpen.enabled" = false;
            "browser.shopping.experience2023.autoOpen.userEnabled" = false;
            "browser.shopping.experience2023.enabled" = false;
            "browser.shopping.experience2023.survey.enabled" = false;
          "browser.vpn_promo.enabled" = false;
          "datareporting.healthreport.infoURL" = "";
          # 'Allow Firefox to send technical and interaction data to Mozilla'
            "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "dom.security.unexpected_system_load_telemetry_enabled" = false;
          #"identity.fxaccounts.account.telemetry.sanitized_uid" = 0;
          "network.trr.confirmation_telemetry_enabled" = false;
          "security.app_menu.recordEventTelemetry" = false;
          "security.certerrors.recordEventTelemetry" = false;
          "security.protectionspopup.recordEventTelemetry" = false;
          "services.sync.telemetry.maxPayloadCount" = 0;
          "services.sync.telemetry.submissionInterval" = 2147483647;
          "telemetry.fog.test.localhost_port" = -1;
          "telemetry.number_of_site_origin.min_interval" = 2147483647;
          "toolkit.coverage.endpoint.base" = "";
          "toolkit.coverage.opt-out" = true;
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.cachedClientID" = "0";
          "toolkit.telemetry.coverage.opt-out" = true;
          "toolkit.telemetry.dap_helper" = "";
          "toolkit.telemetry.dap_leader" = "";
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;
          "toolkit.telemetry.geckoview.batchDurationMS" = 0;
          "toolkit.telemetry.geckoview.maxBatchStalenessMS" = 0;
          "toolkit.telemetry.ipcBatchTimeout" = 0;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.pioneer-new-studies-available" = false;
          "toolkit.telemetry.previousBuildID" = 2050000000000;
          "toolkit.telemetry.reportingpolicy.firstRun" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.shutdownPingSender.backgroundtask.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabledFirstsession" = false;
          "toolkit.telemetry.testing.overrideProductsCheck" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
        };
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
