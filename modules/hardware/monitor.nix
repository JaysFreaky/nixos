{ lib, ... }: {
  options.myHosts = with lib; {
    width = mkOption {
      default = null;
      description = "Width of monitor resolution";
      type = types.nullOr types.str;
    };
    height = mkOption {
      default = null;
      description = "Height of monitor resolution";
      type = types.nullOr types.str;
    };
    refresh = mkOption {
      default = null;
      description = "Refresh rate of monitor resolution";
      type = types.nullOr types.str;
    };
    scale = mkOption {
      default = null;
      description = "Scale of monitor resolution";
      type = types.nullOr types.str;
    };
  };

}
