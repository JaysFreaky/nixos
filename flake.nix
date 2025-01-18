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
        flake-parts.follows = "flake-parts";
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
      };
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        nuschtosSearch.follows = "nuschtosSearch";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        git-hooks.follows = "git-hooks";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
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
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nuschtosSearch = {
      url = "github:NuschtOS/search";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default-linux";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };


  outputs = { self, nixpkgs, ... } @ inputs: let
    hostSystems = {
      Dekki.modules = [
        inputs.chaotic.nixosModules.default
        inputs.jovian.nixosModules.jovian
      ];

      FW13.modules = [
        inputs.hardware.nixosModules.framework-13-7040-amd
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      # 'nix build .#nixosConfigurations.iso.config.system.build.isoImage'
      iso = {
        bareSystem = true;
        modules = [ ./hosts/iso ];
      };

      Ridge.modules = [
        inputs.chaotic.nixosModules.default
        inputs.jovian.nixosModules.jovian
      ];

      T1.modules = [ inputs.chaotic.nixosModules.default ];

      T450s.modules = [ inputs.hardware.nixosModules.lenovo-thinkpad-t450s ];

      VM.modules = [ ];
    };

    mkSystem = hostName: hostOpts: let
      bareSystem = hostOpts.bareSystem or false;
      sysModules = hostOpts.modules;
      system = hostOpts.system or "x86_64-linux";
    in nixpkgs.lib.nixosSystem {
      inherit system;
      modules = (if (bareSystem) then ([ ]) else (stdModules hostName)) ++ sysModules;
      specialArgs = let
        stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        inherit inputs stable vars;
      };
    };

    stdModules = hostName: [
      { networking.hostName = hostName; }
      ./hosts/${hostName}
      ./hosts/common.nix
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }
      inputs.nur.modules.nixos.default
      inputs.sops-nix.nixosModules.sops
    ];

    vars = {
      user = "jays";
      name = "Jason";
      configPath = "/etc/nixos";
      # Alacritty, kitty, or wezterm
      terminal = "kitty";
    };
  in {
    # 'nixos-rebuild switch --flake .#your-hostname'
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem hostSystems;
  };

}
