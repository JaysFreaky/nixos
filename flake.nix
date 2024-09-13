{
  description = "NixOS Systems Flake";

  inputs = {
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs = {
        home-manager.follows = "home-manager";
        jovian.follows = "jovian";
        nixpkgs.follows = "nixpkgs";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fancontrol-gui = {
      url = "github:JaysFreaky/fancontrol-gui";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    framework-plymouth = {
      url = "github:JaysFreaky/framework-plymouth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks-nix.follows = "";
        rust-overlay.follows = "rust-overlay";
      };
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
        rust-overlay.follows = "rust-overlay";
      };
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nur.url = "github:nix-community/NUR";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    /*stylix = {
      url = "github:danth/stylix";
      inputs = {
        flake-compat.follows = "flake-compat";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };*/
    superfile = {
      url = "github:yorukot/superfile";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    wezterm = {
      url = "github:wez/wezterm?dir=nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
      };
    };

    # Follows-only
    flake-compat.url = "github:edolstra/flake-compat";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, ... } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        inputs.nur.overlay
      ];
    };
    stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
    vars = {
      user = "jays";
      name = "Jason";
      configPath = "/etc/nixos";
      # Alacritty, kitty, or wezterm
      terminal = "kitty";
    };

    standardModules = [
      ./hosts/common.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.nixos-cosmic.nixosModules.default
      inputs.nur.nixosModules.nur
      inputs.sops-nix.nixosModules.sops
      inputs.spicetify-nix.nixosModules.spicetify
      #inputs.stylix.nixosModules.stylix
    ];
  in {
    # 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = {
      Dekki = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "Dekki"; }
          ./hosts/Dekki
          inputs.chaotic.nixosModules.default
          inputs.jovian.nixosModules.jovian
        ];
      };

      FW13 = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "FW13"; }
          ./hosts/FW13
          inputs.hardware.nixosModules.framework-13-7040-amd
          inputs.lanzaboote.nixosModules.lanzaboote
        ];
      };

      # nix build .#nixosConfigurations.iso.config.system.build.isoImage
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/iso ];
      };

      Ridge = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "Ridge"; }
          ./hosts/Ridge
          inputs.chaotic.nixosModules.default
        ];
      };

      T1 = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "T1"; }
          ./hosts/T1
          inputs.chaotic.nixosModules.default
        ];
      };

      T450s = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "T450s"; }
          ./hosts/T450s
          inputs.hardware.nixosModules.lenovo-thinkpad-t450s
        ];
      };

      VM = nixpkgs.lib.nixosSystem {
        inherit pkgs system;
        specialArgs = {
          inherit inputs stable vars;
        };
        modules = standardModules ++ [
          { networking.hostName = "VM"; }
          ./hosts/VM
        ];
      };
    };

  };
}
