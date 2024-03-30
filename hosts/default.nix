{ lib, inputs, outputs, hardware, home-manager, impermanence, nix-flatpak, nixpkgs, nixpkgs-stable, nur, ... }:
let
  lib = nixpkgs.lib;
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  stable = import nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  vars = {
    editor = "nvim";
    # alacritty or kitty
    terminal = "alacritty";
    user = "jays";
    name = "Jason";
  };
in {
  FW13 = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs stable system vars;
      host = {
        hostName = "FW13";
      };
    };
    modules = [
      ./common.nix
      ./FW13

      hardware.nixosModules.framework-13-inch-7040-amd
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      nur.nixosModules.nur
    ];
  };

  T450s = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs stable system vars;
      host = {
        hostName = "T450s";
      };
    };
    modules = [
      ./common.nix
      ./T450s

      hardware.nixosModules.lenovo-thinkpad-t450s
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      nur.nixosModules.nur
    ];
  };

  VM = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs stable system vars;
      host = {
        hostName = "VM";
      };
    };
    modules = [
      ./common.nix
      ./VM

      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      nur.nixosModules.nur
    ];
  };

}
