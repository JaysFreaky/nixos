{ lib, ... }: {
  options.myHosts = with lib; {
    width = mkOption {
      description = "Width of monitor resolution";
      example = 1920;
      type = types.nullOr types.int;
    };
    height = mkOption {
      description = "Height of monitor resolution";
      example = 1080;
      type = types.nullOr types.int;
    };
    refresh = mkOption {
      description = "Refresh rate of monitor resolution";
      example = 60;
      type = types.nullOr types.int;
    };
    scale = mkOption {
      description = "Scale of monitor resolution";
      example = 1.25;
      type = types.nullOr types.float;
    };
  };
}
