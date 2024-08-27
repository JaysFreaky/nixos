{ config, lib, pkgs, vars, ... }: let
  cfg = config.myOptions.git;
  cfg-pwd = config.myOptions."1password";

  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/+CvZ9Cnq3Y4my0UtpH19dSNBJeT1wCPK7BAJyAvMA";
in {
  options.myOptions.git = {
    libsecret.enable = lib.mkEnableOption "Git - Libsecret";
    oauth.enable = lib.mkEnableOption "Git - Oauth";
    ssh.enable = lib.mkEnableOption "Git - SSH";
  };

  config.home-manager.users.${vars.user} = with lib; mkMerge [
    {
      programs.git = {
        enable = true;
        extraConfig.init.defaultBranch = "main";
        userEmail = "95696624+JaysFreaky@users.noreply.github.com";
        userName = "JaysFreaky";
      };
    }

    # credential.helper = "libsecret" stores credentials inside gnome-keyring
      # relies upon 'gnome-keyring', 'libsecret', and 'seahorse' pkgs in ../desktops/gnome.nix
    (mkIf (cfg.libsecret.enable) {
      programs.git = {
        extraConfig.credential.helper = "libsecret";
        # gitFull contains git-credential-libsecret
        package = pkgs.gitFull;
      };
    })

    # OAuth does not require additional pkgs like libsecret
    (mkIf (cfg.oauth.enable) {
      programs.git-credential-oauth.enable = true;
    })

    # SSH signing/commits
    (mkIf (cfg.ssh.enable) {
      programs.git.extraConfig = {
        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh.program = if (cfg-pwd.enable)
            then "${getExe' pkgs._1password-gui "op-ssh-sign"}"
            else "${getExe' pkgs.openssh "ssh-agent"}";
        };
        user.signingkey = publicKey;
      };
    })

  ];
}
