{
  lib,
  cfgOpts,
  ...
}: let
  cfg = cfgOpts.vm;
in {
  options.myOptions.vm.enable = lib.mkEnableOption "QEMU/KVM";

  config = lib.mkIf (cfg.enable) {
    programs.virt-manager.enable = true;
    virtualisation.libvirtd.enable = true;
  };
}
