{
  myUser,
  ...
}: {
  home-manager.users.${myUser} = {
    programs.fastfetch = {
      enable = true;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "chafa";
          source = ../../assets/logo.png;
          #source = "NixOS_small";
          width = 20;
          padding = {
            left = 4;
            top = 2;
          };
        };
        display = {
          #color = {
            #title = "";
            #keys = "";
            #separator = "";
            #output = "";
          #};
          separator = "  ";
        };
        modules = [
          {
            type = "title";
            format = "{6}{7}{8}";
            #color = {
              #user = "";
              #at = "";
              #host = "";
            #};
          }
          "separator"
          {
            type = "os";
            key = "";
            format = "{3}";
          }
          {
            type = "kernel";
            key = "";
            format = "{2}";
          }
          {
            type = "wm";
            key = "";
            format = "{2} ({3})";
          }
          {
            type = "uptime";
            key = "";
          }
          "separator"
          {
            type = "cpu";
            key = "";
            format = "{1} ({5}) @ {7}";
          }
          {
            type = "gpu";
            key = "󰢮";
            #format = "{1} {2} @ {12} GHz";
            format = "{1} {2}";
          }
          {
            type = "memory";
            key = "";
            format = "{1} / {2} {4}";
          }
          {
            type = "disk";
            key = "󰋊";
            #format = "{1} / {2} {13} - {9}";
            format = "{1} / {2} {13}";
          }
          "separator"
          {
            type = "terminal";
            key = "";
            format = "{5} {6}";
          }
          {
            type = "shell";
            key = "";
            format = "{6} {4}";
          }
          {
            type = "packages";
            key = "󰏖";
          }
          "break"
          {
            type = "colors";
            symbol = "circle";
          }
        ];
      };
    };
  };

}
