{ writeShellApplication, bash, btrfs-progs, coreutils, cryptsetup, diceware, dosfstools, git, grub2, gum, parted, ... }:

writeShellApplication {
  name = "setup-system";
  text = builtins.readFile ./setup-system.sh;

  runtimeInputs = [
    bash
    btrfs-progs
    coreutils
    cryptsetup
    diceware
    dosfstools
    git
    grub2
    gum
    parted
  ];
}
