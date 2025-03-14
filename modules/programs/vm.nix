{
  lib,
  cfgOpts,
  myUser,
  ...
}: let
  cfg = cfgOpts.vm;
in {
  options.myOptions.vm.enable = lib.mkEnableOption "QEMU/KVM";

  config = lib.mkIf (cfg.enable) {
    programs.virt-manager.enable = true;

    users.users.${myUser}.extraGroups = [
      "libvirtd"
      "qemu-libvirtd"
    ];

    virtualisation.libvirtd.enable = true;
  };
}
