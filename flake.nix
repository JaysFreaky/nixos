{
  description = "NixOS Systems Flake";

  inputs = {
    # Follows-only
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    systems.url = "github:nix-systems/default-linux";

    # Regular
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
      inputs.jovian.follows = "jovian";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nur.url = "github:nix-community/NUR";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superfile = {
      url = "github:yorukot/superfile";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wezterm = {
      url = "github:wez/wezterm?dir=nix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    ...
  } @ inputs:
  let
    system = "x86_64-linux";
    stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    vars = {
      user = "jays";
      name = "Jason";
      configPath = "/etc/nixos";
      editor = "nvim";
      # kitty or Alacritty
      terminal = "kitty";
    };

    standardModules = [
      ./hosts/common.nix
      inputs.home-manager.nixosModules.home-manager {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [
          #inputs.hyprland.homeManagerModules.default
          #inputs.plasma-manager.homeManagerModules.plasma-manager
        ];
      }
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.nur.nixosModules.nur
      inputs.spicetify-nix.nixosModules.spicetify
    ];
  in {
    # 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      Dekki = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
          host.hostName = "Dekki";
        };
        modules = standardModules ++ [
          ./hosts/Dekki
          inputs.jovian.nixosModules.jovian
        ];
      };

      FW13 = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
          host = {
            hostName = "FW13";
            resWidth = "2256";
            resHeight = "1504";
            resRefresh = "60";
            resScale = "1.5";
          };
        };
        modules = standardModules ++ [
          ./hosts/FW13
          inputs.hardware.nixosModules.framework-13-7040-amd
        ];
      };

      Ridge = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
          host = {
            hostName = "Ridge";
            resWidth = "2560";
            resHeight = "1440";
            resRefresh = "144";
            resScale = "1.25";
          };
        };
        modules = standardModules ++ [
          ./hosts/Ridge
          inputs.chaotic.nixosModules.default
        ];
      };

      T1 = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
          host = {
            hostName = "T1";
            resWidth = "2560";
            resHeight = "1440";
            resRefresh = "144";
            resScale = "1.25";
          };
        };
        modules = standardModules ++ [
          ./hosts/T1
          inputs.chaotic.nixosModules.default
        ];
      };

      T450s = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
          host = {
            hostName = "T450s";
            resWidth = "1920";
            resHeight = "1080";
            resRefresh = "60";
            resScale = "1.25";
          };
        };
        modules = standardModules ++ [
          ./hosts/T450s
          inputs.hardware.nixosModules.lenovo-thinkpad-t450s
        ];
      };

      VM = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit (nixpkgs) lib;
        specialArgs = {
          inherit inputs stable vars;
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
