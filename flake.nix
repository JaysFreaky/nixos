{
  description = "NixOS Systems Flake";

  inputs = {
    hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    #hyprland.url = "github:hyprwm/Hyprland";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    /*nixvim = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/nixvim";
    };*/
    nur.url = "github:nix-community/NUR";
  };

  outputs = {
    self,
    hardware,
    home-manager,
    #hyprland,
    nix-flatpak,
    nixpkgs,
    nixpkgs-stable,
    #nixvim,
    nur,
    ...
  } @ inputs:
  let
    inherit (self) outputs;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system} = {
      setup = pkgs.callPackage ./packages/setup { };
    };

    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = (
      import ./hosts {
        inherit (nixpkgs) lib;
        inherit inputs outputs hardware home-manager nix-flatpak nixpkgs nixpkgs-stable nur;
      }
    );
  };
}
