{
  lib,
  ...
}: {
  options.myHosts = {
    width = lib.mkOption {
      description = "Width of monitor resolution";
      example = 1920;
      type = lib.types.nullOr lib.types.int;
    };
    height = lib.mkOption {
      description = "Height of monitor resolution";
      example = 1080;
      type = lib.types.nullOr lib.types.int;
    };
    refresh = lib.mkOption {
      description = "Refresh rate of monitor resolution";
      example = 60;
      type = lib.types.nullOr lib.types.int;
    };
    scale = lib.mkOption {
      description = "Scale of monitor resolution";
      example = 1.25;
      type = lib.types.nullOr lib.types.float;
    };
  };
}
