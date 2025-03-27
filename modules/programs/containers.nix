{
  lib,
  pkgs,
  cfgOpts,
  myUser,
  ...
}: let
  cfg = cfgOpts.containers;
in {
  options.myOptions.containers.enable = lib.mkEnableOption "Containers";

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = builtins.attrValues {
      inherit (pkgs)
      # Kubernetes Tools
        kind
        kubectl
      ;
    };

    users.users.${myUser}.extraGroups = [
      #"docker" # Grants root socket access - use docker.setSocketVariable instead
      "podman"
    ];

    # Docker
    virtualisation = {
      # Docker
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
        storageDriver = "btrfs";
      };
      #oci-containers.backend = "docker";

      # Podman
      containers.enable = true;
      #oci-containers.backend = "podman";
      podman = {
        enable = true;
        #dockerCompat = true; # Docker alias
        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
