{ pkgs }:

pkgs.writeShellApplication {
  name = "s2idle";

  runtimeInputs = with pkgs; [
    acpica-tools
    (python3.withPackages(ps: with ps; [
      distro
      packaging
      pip
      pyudev
      systemd
    ]))
  ];

  text = ''
    sudo python3 "$1" --force
  '';
}
