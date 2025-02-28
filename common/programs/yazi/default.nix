{
  lib,
  pkgs,
  myUser,
  nixPath,
  ...
}: let
  extraDeps = [ pkgs.mediainfo ];
in {
  home-manager.users.${myUser} = {
    imports = [ ./plugins ];

    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration	= false;
      enableNushellIntegration = false;
      enableZshIntegration = false;
      package = pkgs.yazi.override { optionalDeps = extraDeps; };
      shellWrapperName = "y";

      initLua = ''
        --- Show username and hostname in header
        Header:children_add(function()
          if ya.target_family() ~= "unix" then
            return ""
          end
          return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
        end, 500, Header.LEFT)

        --- Show symlink in status bar
        Status:children_add(function(self)
          local h = self._current.hovered
          if h and h.link_to then
            return " -> " .. tostring(h.link_to)
          else
            return ""
          end
        end, 3300, Status.LEFT)

        --- Show user/group of files in status bar
        Status:children_add(function()
          local h = cx.active.current.hovered
          if h == nil or ya.target_family() ~= "unix" then
            return ""
          end

          return ui.Line {
            ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
            ":",
            ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
            " ",
          }
        end, 500, Status.RIGHT)
      '';

      keymap = {
        input.prepend_keymap = [
          # Close input w/ one <Esc>
          {
            desc = "Cancel input";
            on = "<Esc>";
            run = "close";
          }
        ];

        manager.prepend_keymap = [
          # Open a shell in pwd
          {
            desc = "Open shell here";
            on = "!";
            run = "shell \"$SHELL\" --block";
          }

          # Copy selected files to the system clipboard while yanking
          {
            on = "y";
            run = [
              "shell -- for path in \"$@\"; do echo \"file://$path\"; done | ${lib.getExe' pkgs.wl-clipboard "wl-copy"} -t text/uri-list"
              "yank"
            ];
          }

          # cd to NixOS config files
          {
            desc = "Goto NixOS config";
            on = ["g" "n"];
            run = "cd ${nixPath}";
          }

          # cd back to the root of the current Git repository
          {
            desc = "Goto root of current Git repo";
            on = [ "g" "r" ];
            run = "shell -- ya emit cd \"$(git rev-parse --show-toplevel)\"";
          }

          # Reverse q/Q actions
          {
            desc = "Quit the process w/o outputting cwd-file";
            on = "q";
            run = "quit --no-cwd-file";
          }
          {
            desc = "Quit the process";
            on = "Q";
            run = "quit";
          }
        ];
      };

      settings = {
        input.cursor_blink = true;

        manager = {
          show_symlink = true;
          sort_by = "natural";
          sort_dir_first = true;
        };

        # Mimetypes are ignored and 'Choose application' pops up if 'config.xdg.portal.xdgOpenUsePortal = true;'
        opener = let
          runCmd = "${lib.getExe' pkgs.xdg-utils "xdg-open"} \"$@\"";
        in {
          open = [{
            desc = "Open";
            orphan = true;
            run = runCmd;
          }];
          play = [{
            desc = "Play";
            orphan = true;
            run = runCmd;
          }];
        };

        plugin = {
          # Disable network pre-load/view
          prepend_preloaders = [
            {
              name = "/mnt/nas/**";
              run = "noop";
            }
          ];
          prepend_previewers = [
            {
              name = "/mnt/nas/**";
              run = "noop";
            }
          ];
        };

        preview = {
          tab_size = 2;
          wrap = "yes";
        };
      };
    };
  };
}
