{ writeShellApplication, bash, btrfs-progs, coreutils, cryptsetup, dosfstools, git, grub2, gum, parted, ... }:

writeShellApplication {
  name = "setup";
  text = builtins.readFile ./setup.sh;

  runtimeInputs = [
    bash
    btrfs-progs
    coreutils
    cryptsetup
    dosfstools
    git
    grub2
    gum
    parted
  ];
}
