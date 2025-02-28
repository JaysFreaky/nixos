{
  pkgs
}:

pkgs.writeShellApplication {
  name = "s2idle";

  runtimeInputs = [
    pkgs.acpica-tools
    (pkgs.python3.withPackages (py: builtins.attrValues {
      inherit (py)
        distro
        packaging
        pip
        pyudev
        systemd
      ;
    }))
  ];

  text = ''
    sudo python3 "$1" --force
  '';
}
