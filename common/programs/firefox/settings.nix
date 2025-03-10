{
  config,
  dohProvider,
  ...
}: {
  /****************************************************************************
   * Betterfox                                                                *
   * "Ad meliora"                                                             *
   * version: 126                                                             *
   * url: https://github.com/yokoffing/Betterfox                              *
  ****************************************************************************/

  /****************************************************************************
   * SECTION: FASTFOX                                                         *
  ****************************************************************************/
  /** GENERAL ***/
  "content.notify.interval" = 100000;

  /** GFX / HW DECODING ***/
  "gfx.canvas.accelerated" = true;
  "gfx.canvas.accelerated.cache-items" = 4096;
  "gfx.canvas.accelerated.cache-size" = 512;
  "gfx.content.skia-font-cache-size" = 20;
  "gfx.webrender.all" = true;
  "gfx.webrender.compositor.force-enabled" = true;
  "gfx.webrender.dcomp-video-hw-overlay-win" = true;
  "gfx.webrender.dcomp-video-hw-overlay-win-force-enabled" = true;
  "gfx.webrender.dcomp-video-sw-overlay-win" = true;
  "gfx.webrender.dcomp-video-sw-overlay-win-force-enabled" = true;
  "layers.gpu-process.force-enabled" = true;
  "layers.mlgpu.enabled" = true;
  "media.av1.enabled" = false;
  "media.ffmpeg.vaapi.enabled" = true;
  "media.hardware-video-decoding.force-enabled" = true;

  /** DISK CACHE ***/
  "browser.cache.disk.enable" = false;
  "browser.cache.jsbc_compression_level" = 3;

  /** MEMORY CACHE ***/
  # default=-1 (auto based on RAM; 256000=256 MB; 512000=500 MB; 1048576=1GB, 2097152=2GB
    "browser.cache.memory.capacity" = -1;
  # default=5120 (5 MB)
    "browser.cache.memory.max_entry_size" = 10240;
  # default=-1 (auto); amount of back/forward cached pages stored in memory for each tab
    "browser.sessionhistory.max_total_viewers" = 4;

  /** MEDIA CACHE ***/
  "media.cache_readahead_limit" = 7200;
  "media.cache_resume_threshold" = 3600;
  "media.memory_cache_max_size" = 65536;

  /** IMAGE CACHE ***/
  "image.mem.decode_bytes_at_a_time" = 32768;

  /** NETWORK ***/
  # keep cache for an hour
    "network.dnsCacheExpiration" = 3600;
  "network.http.max-connections" = 1800;
  "network.http.max-persistent-connections-per-server" = 10;
  "network.http.max-urgent-start-excessive-connections-per-host" = 5;
  "network.http.pacing.requests.enabled" = false;
  "network.ssl_tokens_cache_capacity" = 10240;

  /** SPECULATIVE LOADING ***/
  # don't preload bookmarks
    "browser.places.speculativeConnect.enabled" = false;
  # don't preload urlbar
    "browser.urlbar.speculativeConnect.enabled" = false;
  "network.dns.disablePrefetch" = true;
  "network.dns.disablePrefetchFromHTTPS" = true;
  # Handled via policies.NetworkPrediction?
    "network.http.speculative-parallel-limit" = 0;
    "network.prefetch-next" = false;
    "network.predictor.enabled" = false;
  "network.predictor.enable-prefetch" = false;

  /** EXPERIMENTAL ***/
  "dom.enable_web_task_scheduling" = true;
  "dom.security.sanitizer.enabled" = true;
  "layout.css.grid-template-masonry-value.enabled" = true;

  /** TAB UNLOAD ***/
  # default=5
    "browser.low_commit_space_threshold_percent" = 20;

  /****************************************************************************
   * SECTION: SECUREFOX                                                       *
  ****************************************************************************/
  /** TRACKING PROTECTION ***/
  "browser.contentblocking.category" = "strict";
  "browser.download.start_downloads_in_tmp_dir" = true;
  "browser.helperApps.deleteTempFileOnExit" = true;
  "browser.uitour.enabled" = false;
  "browser.uitour.url" = "";
  "network.cookie.sameSite.noneRequiresSecure" = true;
  # Settings->P&S->Website Privacy Preferences->'Tell websites not to sell or share my data'
    "privacy.globalprivacycontrol.enabled" = true;
  # Settings->P&S->Website Privacy Preferences->'Send websites a "Do Not Track" request'
    "privacy.donottrackheader.enabled" = true;

  /** OCSP & CERTS / HPKP ***/
  "security.OCSP.enabled" = 0;
  # 0=disabled, 1=user/MitM (default), 2=strict
    "security.cert_pinning.enforcement_level" = 2;
  # 0=disabled, 1=telemetry, 2=enforce both/not revoked, 3=enforce not revoked
    "security.pki.crlite_mode" = 2;
  "security.remote_settings.crlite_filters.enabled" = true;

  /** SSL / TLS ***/
  "browser.xul.error_pages.expert_bad_cert" = true;
  "security.ssl.require_safe_negotiation" = true;
  "security.ssl.treat_unsafe_negotiation_as_broken" = true;
  "security.tls.enable_0rtt_data" = false;

  /** DISK AVOIDANCE ***/
  "browser.pagethumbnails.capturing_disabled" = true;
  "browser.privatebrowsing.forceMediaMemoryCache" = true;
  "browser.sessionstore.interval" = 60000;
  # 0=everywhere (default), 1=unencrypted, 2=nowhere
    "browser.sessionstore.privacy_level" = 2;

  /** CLEARING DATA DEFAULTS ***/
  # ignores cookie site exceptions (manually clear history)
    "privacy.cpd.offlineApps" = true;
    "privacy.cpd.openWindows" = true;
    "privacy.cpd.sessions" = true;
    "privacy.cpd.siteSettings" = true;
  # history items to clear
    "privacy.sanitize.pending" = ''
      [{"id":"newtab-container","itemsToClear":[],"options":{}},{"id":"shutdown","itemsToClear":["cache","cookies","offlineApps","history","formdata","downloads"],"options":{}}]
    '';
  # 0=everything, 1=last hour, 2=last 2 hours, 3=last 4 hours
  # 4=today, 5=last 5 minutes, 6=last 24 hours
    "privacy.sanitize.timeSpan" = 0;

  /** SHUTDOWN & SANITIZING ***/
  # respects cookie site exceptions
    "privacy.clearOnShutdown.offlineApps" = true;
    "privacy.clearOnShutdown.downloads" = true;
    "privacy.clearOnShutdown.formdata" = true;
    #"privacy.clearOnShutdown.history" = true;
  # Settings->P&S->History->'Firefox will: Use custom settings for history'
    "privacy.history.custom" = true;
  # Settings->P&S->History->'Remember browsing and download history'
    "places.history.enabled" = false;
  # Settings->P&S->History->'Remember search and form history'
    "browser.formfill.enable" = false;
  # Settings->P&S->History->'Clear history when Firefox closes'
    "privacy.sanitize.sanitizeOnShutdown" = true;

  /** SEARCH / URL BAR ***/
  # Settings->Search->Default Search Engine->'Use this search engine in Private Windows'
    "browser.search.separatePrivateDefault.ui.enabled" = true;
  # Settings->Search->Default Search Engine->'Choose a different default search engine for Private Windows only'
    "browser.urlbar.placeholderName.private" = "Google";
  # Settings->Search->Search Suggestions->'Show search suggestions'
    "browser.search.suggest.enabled" = false;
  # Settings->Search->Search Suggestions->'Show search suggestions ahead of browsing history in address bar results'
    "browser.urlbar.showSearchSuggestionsFirst" = false;
  "browser.urlbar.autoFill" = false;
  "browser.urlbar.trimHttps" = true;
  "browser.urlbar.update2.engineAliasRefresh" = true;
  # display phishing characters
    "network.IDN_show_punycode" = true;
  "security.insecure_connection_text.enabled" = true;
  "security.insecure_connection_text.pbmode.enabled" = true;

  /** HTTPS-FIRST POLICY ***/
  "dom.security.https_first" = true;
  "dom.security.https_first_schemeless" = true;

  /** HTTPS-ONLY MODE ***/
  "dom.security.https_only_mode" = true;
  "dom.security.https_only_mode_error_page_user_suggestions" = true;

  /** DNS-over-HTTPS ***/
  "network.dns.skipTRR-when-parental-control-enabled" = false;
  # 0=default, 2=DoH first, 3=DoH only, 5=off
    "network.trr.mode" = 3;
  "network.trr.uri" = dohProvider;
  "network.trr.custom_uri" = dohProvider;

  /** PROXY / SOCKS / IPv6 ***/
  "network.file.disable_unc_paths" = true;
  "network.gio.supported-protocols" = ""; 
  "network.proxy.socks_remote_dns" = true;

  /** PASSWORDS ***/
  # Settings->P&S->Passwords->'Ask to save passwords'
    "signon.rememberSignons" = false;
  # Settings->P&S->Passwords->'Fill usernames and passwords automatically'
    "signon.autofillForms" = false;
  # Settings->P&S->Passwords->'Suggest strong passwords'
    "signon.generation.enabled" = false;
  # Settings->P&S->Passwords->'Suggest Firefox Relay email masks to protect your email address'
    "signon.firefoxRelay.feature" = "";
  # Settings->P&S->Passwords->'Show alerts about passwords for breached websites'
    "signon.management.page.breach-alerts.enabled" = false;
    "signon.management.page.breachAlertUrl" = "";
  "browser.contentblocking.report.lockwise.enabled" = false;
  "browser.contentblocking.report.lockwise.how_it_works.url" = "";
  "editor.truncate_user_pastes" = false;
  # 0=don't allow, 1=no cross-origin, 2=allow
    "network.auth.subresource-http-auth-allow" = 1;
  "signon.formlessCapture.enabled" = false;
  "signon.privateBrowsingCapture.enabled" = false;
  "signon.storeWhenAutocompleteOff" = false;

  /** ADDRESS + CREDIT CARD MANAGER ***/
  # Settings->P&S->Autofill->'Save and fill addresses'
    "extensions.formautofill.addresses.enabled" = false;
  # Settings->P&S->Autofill->'Save and fill payment methods'
    "extensions.formautofill.creditCards.enabled" = false;

  /** MIXED CONTENT + CROSS-SITE ***/
  "browser.tabs.searchclipboardfor.middleclick" = false;
  "extensions.postDownloadThirdPartyPrompt" = false;
  "pdfjs.enableScripting" = false;
  "security.mixed_content.block_display_content" = true;
  "security.mixed_content.upgrade_display_content" = true;
  "security.mixed_content.upgrade_display_content.image" = true;

  /** HEADERS / REFERERS ***/
  "network.http.referer.defaultPolicy.trackers" = 1;
  "network.http.referer.defaultPolicy.trackers.pbmode" = 1;
  "network.http.referer.XOriginTrimmingPolicy" = 2;

  /** CONTAINERS ***/
  # Settings->General->Tabs->'Enable Container Tabs'
    "privacy.userContext.ui.enabled" = true;
    "privacy.userContext.enabled" = true;
  "privacy.userContext.extension" = "CanvasBlocker@kkapsner.de";
  #"privacy.userContext.newTabContainerOnLeftClick.enabled" = true;

  /** WEBRTC ***/
  "media.peerconnection.ice.default_address_only" = true;
  "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

  /** PLUGINS ***/
  # Settings->General->Digital Rights Management (DRM) Content
    "browser.eme.ui.enabled" = true;
  # Settings->General->DRM Content->Play DRM-controlled content
    "media.eme.enabled" = false;
  "media.gmp-provider.enabled" = false;

  /** VARIOUS ***/
  "network.ftp.enabled" = true;

  /** SAFE BROWSING ***/
  "browser.safebrowsing.downloads.remote.enabled" = false;

  /** MOZILLA ***/
  # disabling accessibility improves performance
    "accessibility.force_disabled" = 1;
    "devtools.accessibility.enabled" = false;
  "browser.firefox-view.feature-tour" = ''
    {"screen":"","complete":true}
  '';
  #"browser.search.region" = "US";
  "extensions.quarantinedDomains.enabled" = false;
  "permissions.manager.defaultsUrl" = "";
  "webchannel.allowObject.urlWhitelist" = "";
  # 0=always ask (default), 1=allow, 2=block
    # Settings->P&S->Permissions->Location
      "permissions.default.geo" = 2;
      "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
      "geo.provider.use_geoclue" = false;
      "geo.provider.use_gpsd" = false;
      "browser.region.update.enabled" = false;
      "browser.region.network.url" = "";
    # Settings->P&S->Permissions->Notifications`
      "permissions.default.desktop-notification" = 0;
    "permissions.default.shortcuts" = 2;

  /** DATA COLLECTION ***/
  # Settings->P&S->Firefox Data Collection and Use->'Allow Firefox to send technical and interaction data to Mozilla'
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.healthreport.infoURL" = "";
    "toolkit.telemetry.archive.enabled" = false;
  # Settings->P&S->Firefox Data Collection and Use->'Allow Firefox to make personalized extension recommendations'
    "browser.discovery.enabled" = false;
  # Settings->P&S->Firefox Data Collection and Use->'Allow Firefox to install and run studies'
    "apImprove the Firefox Suggest experiencep.shield.optoutstudies.enabled" = false;
    # studies - recommend extensions as you browse
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
    # studies - recommend features as you browse
      "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
  # Settings->P&S->Firefox Data Collection and Use->'Allow Firefox to send backlogged crash reports on your behalf'
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
  # Settings->P&S->Firefox Data Collection and Use->'Improve the Firefox Suggest experience'
    "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.quicksuggest.scenario" = "offline";

  /** TELEMETRY ***/
  "browser.newtabpage.activity-stream.feeds.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry" = false;
  "browser.newtabpage.activity-stream.telemetry.structuredIngestion.endpoint" = "";
  "toolkit.coverage.opt-out" = true;
  "toolkit.coverage.endpoint.base" = "";
  "toolkit.telemetry.enabled" = false;
  "toolkit.telemetry.bhrPing.enabled" = false;
  "toolkit.telemetry.coverage.opt-out" = true;
  "toolkit.telemetry.firstShutdownPing.enabled" = false;
  "toolkit.telemetry.newProfilePing.enabled" = false;
  "toolkit.telemetry.pioneer-new-studies-available" = false;
  "toolkit.telemetry.reportingpolicy.firstRun" = false;
  "toolkit.telemetry.server" = "data:,";
  "toolkit.telemetry.shutdownPingSender.enabled" = false;
  "toolkit.telemetry.unified" = false;
  "toolkit.telemetry.updatePing.enabled" = false;

  /** EXPERIMENTS ***/
  "app.normandy.enabled" = false;
  "app.normandy.api_url" = "";

  /** DETECTION ***/
  "captivedetect.canonicalURL" = "";
  "network.captive-portal-service.enabled" = false;
  # disable network checks
    "network.connectivity-service.enabled" = false;
  # ensure DoH isn't auto enabled
    "doh-rollout.disable-heuristics" = true;
  "dom.security.unexpected_system_load_telemetry_enabled" = false;
  "messaging-system.rsexperimentloader.enabled" = false;
  "network.trr.confirmation_telemetry_enabled" = false;
  "privacy.trackingprotection.emailtracking.data_collection.enabled" = false;
  "security.app_menu.recordEventTelemetry" = false;
  "security.certerrors.mitm.priming.enabled" = false;
  "security.certerrors.recordEventTelemetry" = false;
  "security.protectionspopup.recordEventTelemetry" = false;
  "signon.recipes.remoteRecipes.enabled" = false;

  /****************************************************************************
   * SECTION: PESKYFOX                                                        *
  ****************************************************************************/
  /** MOZILLA UI ***/
  # Mozilla vpn-related
    "browser.contentblocking.report.hide_vpn_banner" = true;
    "browser.privatebrowsing.vpnpromourl" = "";
    "browser.vpn_promo.enabled" = false;
  # about:addons recommendation pane
    "extensions.getAddons.showPane" = false;
  # about:addons extensions/themes recommendation pane
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
  "browser.aboutConfig.showWarning" = false;
  # first run
    "browser.aboutwelcome.enabled" = false;
    "browser.startup.firstrunSkipsHomepage" = true;
  # disable what's new toolbar
    "browser.messaging-system.whatsNewPanel.enabled" = false;
  "browser.preferences.moreFromMozilla" = false;
  "browser.shell.checkDefaultBrowser" = false;
  "browser.tabs.tabmanager.enabled" = false;
  "browser.tabs.warnOnClose" = true;

  /** THEME ADJUSTMENTS ***/
  # userChrome.css/userContent.css
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  "browser.compactmode.show" = true;
  "browser.display.focus_ring_on_anything" = true;
  "browser.display.focus_ring_style" = 0;
  "browser.display.focus_ring_width" = 0;
  # 0=dark, 1=light, 2=system-theme, 3=browser-theme
    "layout.css.prefers-color-scheme.content-override" = 2;
  "layout.css.visited_links_enabled" = false;

  /** COOKIE BANNER HANDLING ***/
  "cookiebanners.service.mode" = 1;
  "cookiebanners.service.mode.privateBrowsing" = 1;

  /** FULLSCREEN NOTICE ***/
  "full-screen-api.warning.delay" = -1;
  "full-screen-api.warning.timeout" = 0;
  "full-screen-api.transition-duration.enter" = "0 0";
  "full-screen-api.transition-duration.leave" = "0 0";

  /** URL BAR ***/
  # these three are URL bar search shortcuts (*,^,%)
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
  # Settings->Search->Address Bar - Firefox Suggest
    "browser.urlbar.suggest.addons" = false;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.clipboard" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.mdn" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.pocket" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.recentsearches" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.trending" = false;
    "browser.urlbar.suggest.weather" = false;
    "browser.urlbar.suggest.yelp" = false;
    "browser.urlbar.unitConversion.enabled" = true;
  # featuregates
    "browser.urlbar.addons.featureGate" = false;
    "browser.urlbar.clipboard.featureGate" = false;
    "browser.urlbar.mdn.featureGate" = false;
    "browser.urlbar.pocket.featureGate" = false;
    "browser.urlbar.richSuggestions.featureGate" = false;
    "browser.urlbar.trending.featureGate" = false;
    "browser.urlbar.weather.featureGate" = false;
    "browser.urlbar.yelp.featureGate" = false;

  /** AUTOPLAY ***/
  # 0=Allow all, 1=Block non-muted media (default), 5=Block all
    "media.autoplay.default" = 5;

  /** NEW TAB PAGE ***/
  # Settings->Home->New Tabs and Windows
    # 0=blank, 1=home, 2=last visited page, 3=resume previous session
      "browser.startup.page" = 1;
    # Set to Tabliss automatically via policies.ExtensionSettings
      #"browser.startup.homepage" = "moz-extension://";
    "browser.newtab.extensionControlled" = true;
    "browser.newtab.privateAllowed" = false;
  # Settings->Home->Firefox Home Control
    "browser.newtabpage.enabled" = false;
    # 'Web Search'
      "browser.newtabpage.activity-stream.showSearch" = false;
      "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
    # 'Shortcuts'
      "browser.newtabpage.activity-stream.feeds.topsites" = false;
      "browser.newtabpage.activity-stream.default.sites" = "";
    # 'Shortcuts'->'Sponsored shortcuts'
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    # 'Recommended stories'
      "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    # 'Recommended stories'->'Sponsored stories'
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
      "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
    # 'Recent activity'
      "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
      "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
      "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
      "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
  # always, newtab, never - Handled via policies.DisplayBookmarksinToolbar
    #"browser.toolbars.bookmarks.visibility" = "newtab";

  /** POCKET ***/
  "extensions.pocket.enabled" = false;
  "extensions.pocket.api" = " ";
  "extensions.pocket.oAuthConsumerKey" = " ";
  "extensions.pocket.showHome" = false;
  "extensions.pocket.site" = " ";

  /** DOWNLOADS ***/
  "browser.download.always_ask_before_handling_new_types" = false;
  "browser.download.manager.addToRecentDocs" = false;

  /** PDF ***/
  "browser.download.open_pdf_attachments_inline" = true;
  # -1=remember previous state (default), 0=disabled, 1=view pages, 2=table of contents
    "pdfjs.sidebarViewOnLoad" = 2;

  /** TAB BEHAVIOR ***/
  "browser.bookmarks.openInTabClosesMenu" = false;
  "browser.tabs.loadBookmarksInTabs" = true;
  "browser.tabs.loadBookmarksInBackground" = true;
  "browser.menu.showViewImageInfo" = true;
  #"browser.tabs.cardPreview.enabled" = true;
  #"browser.tabs.closeWindowWithLastTab" = false;
  "browser.tabs.insertAfterCurrent" = true;
  "dom.disable_window_move_resize" = true;
  "findbar.highlightAll" = true;
  "editor.word_select.delete_space_after_doubleclick_selection" = true;
  "layout.word_select.eat_space_to_next_word" = false;
  "toolkit.tabbox.switchByScrolling" = true;

  /** UNCATEGORIZED ***/
  # 0=none, 1=multi-line, 2=single & multi-line
    "layout.spellcheckDefault" = 0;
  "browser.bookmarks.max_backups" = 1;
  "browser.zoom.full" = false;
  "view_source.wrap_long_lines" = true;
  "devtools.debugger.ui.editor-wrapping" = true;

  /****************************************************************************
   * START: MY OVERRIDES                                                      *
  ****************************************************************************/
  # Enter your personal overrides below this line:

  # disable pinch to zoom
    "apz.gtk.touchpad_pinch.enabled" = false;
  # Native Linux file browser
    "widget.use-xdg-desktop-portal.file-picker" = 1;
  # auto-enable extensions loaded via HomeManager
    "extensions.autoDisableScopes" = 0;

  /** BOOKMARKS ***/
  # disable default bookmarks - handled by policies.NoDefaultBookmarks
    #"browser.bookmarks.restore_default_bookmarks" = false;
  # enable mobile bookmarks
    "browser.bookmarks.showMobileBookmarks" = true;

  /** SYNC ***/
  "identity.fxaccounts.account.device.name" = "${config.networking.hostName}";
  # only syncing addons/bookmarks/prefs/tabs
    "services.sync.declinedEngines" = "addresses,creditcards,forms,history,passwords";
    "services.sync.addons" = true;
    "services.sync.addresses" = false;
    "services.sync.bookmarks" = true;
    "services.sync.creditcards" = false;
    "services.sync.history" = false;
    "services.sync.passwords" = false;
    "services.sync.prefs" = true;
    "services.sync.tabs" = true;
    "services.sync.deletePwdFxA" = true;

  /** TOOLBAR CUSTOMIZATION ***/
  "browser.uicustomization.state" = ''
    {"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["ublock0_raymondhill_net-browser-action","sponsorblocker_ajay_app-browser-action","addon_simplelogin-browser-action","_76ef94a4-e3d0-4c6f-961a-d38a429a332b_-browser-action","magnolia_12_34-browser-action","_testpilot-containers-browser-action","canvasblocker_kkapsner_de-browser-action","enhancerforyoutube_maximerf_addons_mozilla_org-browser-action","addon_darkreader_org-browser-action"],"nav-bar":["profile-manager","back-button","forward-button","stop-reload-button","customizableui-special-spring1","urlbar-container","customizableui-special-spring2","save-to-pocket-button","downloads-button","customizableui-special-spring13","_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action","unified-extensions-button","fxa-toolbar-menu-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button","firefox-view-button"],"PersonalToolbar":["import-button","personal-bookmarks"],"statusBar":["screenshot-button","fullscreen-button","status-text"]},"seen":["addon_simplelogin-browser-action","_76ef94a4-e3d0-4c6f-961a-d38a429a332b_-browser-action","magnolia_12_34-browser-action","_testpilot-containers-browser-action","canvasblocker_kkapsner_de-browser-action","enhancerforyoutube_maximerf_addons_mozilla_org-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","sponsorblocker_ajay_app-browser-action","_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action","developer-button","sidebar-reverse-position-toolbar","undo-closed-tab","profile-manager"],"dirtyAreaCache":["unified-extensions-area","nav-bar","statusBar","PersonalToolbar","TabsToolbar","toolbar-menubar","widget-overflow-fixed-list"],"currentVersion":20,"newElementCount":17}
  '';


  /****************************************************************************
   * SECTION: SMOOTHFOX                                                       *
  ****************************************************************************/
  # visit https://github.com/yokoffing/Betterfox/blob/main/Smoothfox.js
  # Enter your scrolling overrides below this line:

  # PREF: sharpen scrolling
  "general.smoothScroll" = true; # DEFAULT
  "general.smoothScroll.mouseWheel.durationMinMS" = 50; # default=50
  "general.smoothScroll.currentVelocityWeighting" = "0.25"; # default=.25
  "general.smoothScroll.stopDecelerationWeighting" = "0.4"; # default=.4
  # Touchpad scrolling slowed down
  "mousewheel.default.delta_multiplier_x" = 30; # default=100
  "mousewheel.default.delta_multiplier_y" = 30; # default=300
  # Mousewheel scrolling to match touchpad
  "mousewheel.min_line_scroll_amount" = 120; # default=5

  /****************************************************************************
   * END: BETTERFOX                                                           *
  ****************************************************************************/

  /****************************************************************************
   * FLOORP                                                                   *
  ****************************************************************************/
  "browser.newtabpage.activity-stream.floorp.newtab.imagecredit.hide" = true;
  "browser.newtabpage.activity-stream.floorp.newtab.releasenote.hide" = true;
  "floorp.browser.sidebar.enable" = false;
  "floorp.browser.sidebar.useIconProvider" = "duckduckgo";
  "floorp.browser.sidebar2.data" = ''
    {"data":{"floorp__bmt":{"url":"floorp//bmt","width":500},"floorp__bookmarks":{"url":"floorp//bookmarks"},"floorp__downloads":{"url":"floorp//downloads"},"floorp__notes":{"url":"floorp//notes"},"w0":{"url":"https://translate.google.com"},"w202471813257":{"url":"https://mail.proton.me/"}},"index":["floorp__bmt","floorp__bookmarks","floorp__downloads","floorp__notes","w0","w202471813257"]}
  '';
  "floorp.browser.sidebar2.global.webpanel.width" = 400;
  "floorp.browser.tabbar.settings" = 2;
  "floorp.browser.tabs.openNewTabPosition" = 1;
  "floorp.browser.tabs.verticaltab" = true;
  "floorp.browser.user.interface" = 1;
  "floorp.browser.workspaces.enabled" = false;
  # 1=starts, 2=finishes, 3=both, 4=disabled
    "floorp.download.notification" = 2;
  "floorp.downloading.red.color" = false;
  "floorp.tabbar.style" = 2;
  "floorp.verticaltab.hover.enabled" = true;
  "floorp.verticaltab.show.newtab.button" = true;
  "media.videocontrols.picture-in-picture.video-toggle.enabled" = false;
  "services.sync.prefs.sync.floorp.browser.note.memos" = true;
  "sidebar.position_start" = false;
}
