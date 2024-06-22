{
  description = "NixOS Systems Flake";

  inputs = {
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #hyprland.url = "github:hyprwm/Hyprland";
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nur.url = "github:nix-community/NUR";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superfile = {
      url = "github:yorukot/superfile";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wez/wezterm?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    home-manager,
    nixpkgs,
    nixpkgs-stable,
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
      configPath = "/etc/nixos";
      editor = "nvim";
      # alacritty or kitty
      terminal = "kitty";
    };

    standardModules = [
      ./hosts/common.nix
      home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.nur.nixosModules.nur
      inputs.spicetify-nix.nixosModules.spicetify
    ];
  in {
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      Dekki = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable vars;
          host.hostName = "Dekki";
        };
        modules = standardModules ++ [
          ./hosts/Dekki
          inputs.jovian.nixosModules.jovian
        ];
      };

      FW13 = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable vars;
          host.hostName = "FW13";
        };
        modules = standardModules ++ [
          ./hosts/FW13
          inputs.hardware.nixosModules.framework-13-7040-amd
        ];
      };

      Ridge = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable vars;
          host.hostName = "Ridge";
        };
        modules = standardModules ++ [
          ./hosts/Ridge
          #inputs.jovian.nixosModules.jovian
        ];
      };

      T450s = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable vars;
          host.hostName = "T450s";
        };
        modules = standardModules ++ [
          ./hosts/T450s
          inputs.hardware.nixosModules.lenovo-thinkpad-t450s
        ];
      };

      VM = nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs pkgs stable vars;
          host.hostName = "VM";
        };
        modules = standardModules ++ [
          ./hosts/VM
        ];
      };
    };

    packages.${system} = {
      framework-plymouth = nixpkgs.legacyPackages.${system}.callPackage ./packages/framework-plymouth { };
      setup-system = nixpkgs.legacyPackages.${system}.callPackage ./packages/setup-system { };
    };
  };

}
