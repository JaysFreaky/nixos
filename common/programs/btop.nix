{
  pkgs,
  cfgOpts,
  myUser,
  ...
}: {
  home-manager.users.${myUser}.programs.btop = {
    enable = true;
    package = (
      if (cfgOpts.hardware.amdgpu.enable)
        then (pkgs.btop.override { rocmSupport = true; })
      else if (cfgOpts.hardware.nvidia.enable)
        then (pkgs.btop.override { cudaSupport = true; })
      else pkgs.btop
    );
    settings = {
      clock_format = "[/host] %X";
      proc_filter_kernel = true;
      proc_left = true;
      proc_sorting = "cpu lazy";
      vim_keys = true;
    };
  };
}
