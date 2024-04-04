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
    extra-experimental-features = [ "nix-command" "flakes" ];
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
        inherit inputs outputs hardware home-manager impermanence nix-flatpak nixpkgs nixpkgs-stable nur;
      }
    );
  };
}
