{ lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  environment.systemPackages = with pkgs; [
    coreutils
    git
    lm_sensors
    lshw
    pciutils
    sops
    ssh-to-age
    tree
    usbutils
    vim
    wget
  ];

  isoImage.squashfsCompression = "gzip";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  time.timeZone = "America/Chicago";

  users.users.nixos = {
    isNormalUser = true;
    initialHashedPassword = lib.mkForce null;
    password = "nixos";
  };

}
