{
  description = "NixOS Systems Flake";

  inputs = {
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    #hyprland.url = "github:hyprwm/Hyprland";
    impermanence.url = "github:nix-community/impermanence";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nur.url = "github:nix-community/NUR";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  outputs = {
    self,
    hardware,
    home-manager,
    #hyprland,
    impermanence,
    nix-flatpak,
    nixpkgs,
    nixpkgs-stable,
    nur,
    ...
  } @ inputs:
  let
    system = "x86_64-linux";
    nixosSystem = nixpkgs.lib.nixosSystem;

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    vars = {
      user = "jays";
      name = "Jason";
      editor = "nvim";
      # alacritty or kitty
      terminal = "alacritty";
    };

    standardModules = [
      ./hosts/common.nix
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
      impermanence.nixosModules.impermanence
      nix-flatpak.nixosModules.nix-flatpak
      nur.nixosModules.nur
    ];
  in {
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      FW13 = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable system vars;
          host.hostName = "FW13";
        };
        modules = standardModules ++ [
          ./hosts/FW13
          hardware.nixosModules.framework-13-7040-amd
        ];
      };

      T450s = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable system vars;
          host.hostName = "T450s";
        };
        modules = standardModules ++ [
          ./hosts/T450s
          hardware.nixosModules.lenovo-thinkpad-t450s
        ];
      };

      VM = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable system vars;
          hosthostName = "VM";
        };
        modules = standardModules ++ [
          ./hosts/VM
        ];
      };
    };

    packages.${system} = {
      setup = nixpkgs.legacyPackages.${system}.callPackage ./packages/setup { };
    };

  };
}
