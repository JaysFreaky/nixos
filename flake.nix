{
  description = "NixOS Multi-System Flake";

  inputs = {
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    disko.url = "github:nix-community/disko";
    framework-plymouth.url = "github:JaysFreaky/framework-plymouth";
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nixos-artwork = {
      url = "github:NixOS/nixos-artwork";
      flake = false;
    };
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixvim.url = "github:nix-community/nixvim";
    nur.url = "github:nix-community/NUR";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    sops-nix.url = "github:Mic92/sops-nix";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    stylix.url = "github:danth/stylix";
    wezterm.url = "github:wez/wezterm?dir=nix";
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };


  outputs = { self, nixpkgs, ... } @ inputs: let
    # 'nixos-rebuild switch --flake .#your-hostname'
    hostSystems = {
      /*
      Dekki.modules = [
        inputs.chaotic.nixosModules.default
        inputs.jovian.nixosModules.jovian
      ];
      */

      FW13.modules = [
        {
          nixpkgs.overlays = [ inputs.framework-plymouth.overlays.default ];
        }
        inputs.hardware.nixosModules.framework-13-7040-amd
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      # 'nix build .#nixosConfigurations.iso.config.system.build.isoImage'
      iso = {
        isBare = true;
        modules = [ ./hosts/iso ];
      };

      /*
      Ridge.modules = [
        inputs.chaotic.nixosModules.default
        inputs.jovian.nixosModules.jovian
      ];
      */

      T1.modules = [ inputs.chaotic.nixosModules.default ];

      T450s.modules = [ inputs.hardware.nixosModules.lenovo-thinkpad-t450s ];

      VM.modules = [ ];
    };

    mkSystem = hostName: hostOpts: let
      isBare = hostOpts.isBare or false;
      specialArgs = let
        cfgTerm = "kitty";  # kitty or wezterm
        nixPath = "/etc/nixos";
        stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        inherit cfgTerm inputs nixPath stable;
      };
      sysModules = hostOpts.modules;
      system = hostOpts.system or "x86_64-linux";
    in nixpkgs.lib.nixosSystem {
      inherit system;
      modules = (
        if (isBare)
          then ([ ])
        else (stdModules hostName specialArgs)
      ) ++ sysModules;
      specialArgs = specialArgs;
    };

    stdModules = hostName: specialArgs: [
      ({ config, ... }: {
        _module.args = {
          cfgHosts = config.myHosts;
          cfgOpts = config.myOptions;
          myUser = config.myUser;
        };
        networking.hostName = hostName;
        nixpkgs = {
          config.allowUnfree = true;
          overlays = [ inputs.nur.overlays.default ];
        };
      })
      ./common
      ./hosts/${hostName}
      inputs.disko.nixosModules.disko
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          extraSpecialArgs = specialArgs;
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }
      inputs.nur.modules.nixos.default
      inputs.sops-nix.nixosModules.sops
    ];
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem hostSystems;
  };
}
