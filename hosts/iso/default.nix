{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  latestKernel = false;
  nvidia = false;
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    #(modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  config = lib.mkMerge [
    {
      boot = {
        kernelModules = [
          #"nct6687"
        ];
        extraModulePackages = builtins.attrValues {
          #inherit (config.boot.kernelPackages)
            #nct6687d
          #;
        };
        # ZFS won't build against 6.13.x, even w/ allowBroken
        kernelPackages = (
          if (latestKernel)
            then pkgs.linuxPackages_latest
          else pkgs.linuxPackages_6_12
        );
      };

      environment.systemPackages = builtins.attrValues {
        inherit (pkgs)
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
        ;
      };

      isoImage.squashfsCompression = "gzip";

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
      };

      nixpkgs = {
        config = {
          #allowBroken = true; # Bypass broken ZFS module
          allowUnfree = true;
        };
        hostPlatform = lib.mkDefault "x86_64-linux";
      };

      time.timeZone = "America/Chicago";

      users.users.nixos = {
        isNormalUser = true;
        initialHashedPassword = lib.mkForce null;
        password = "nixos";
      };
    }

    (lib.mkIf (nvidia) {
      hardware = {
        graphics.enable = true;
        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = true;
          open = false;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          powerManagement = {
            enable = false;
            finegrained = false;
          };
        };
      };

      services.xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];
      };
    })
  ];
}
