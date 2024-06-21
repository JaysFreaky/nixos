{ config, lib, pkgs, vars, ... }: with lib;
let
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/+CvZ9Cnq3Y4my0UtpH19dSNBJeT1wCPK7BAJyAvMA";
in {
  options.git = {
    libsecret.enable = mkOption {
      default = false;
      type = types.bool;
    };
    oauth.enable = mkOption {
      default = false;
      type = types.bool;
    };
    ssh.enable = mkOption {
      default = true;
      type = types.bool;
    };
  };

  config.home-manager.users.${vars.user} = mkMerge [
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
    (mkIf (config.git.libsecret.enable) {
      programs.git = {
        extraConfig.credential.helper = "libsecret";
        # gitFull contains git-credential-libsecret
        package = pkgs.gitFull;
      };
    })

    # OAuth does not require additional pkgs like libsecret
    (mkIf (config.git.oauth.enable) {
      programs.git-credential-oauth.enable = true;
    })

    # SSH signing/commits
    (mkIf (config.git.ssh.enable) {
      programs.git.extraConfig = {
        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh = mkMerge [
            (mkIf (config."1password".enable) {
              program = "${pkgs._1password-gui}/bin/op-ssh-sign";
            })
            (mkIf (!config."1password".enable) {
              program = "${pkgs.openssh}/bin/ssh-agent";
            })
          ];
        };
        user.signingkey = publicKey;
      };

      home.file.".ssh/config" = mkMerge [
        (mkIf (config."1password".enable) {
          text = ''
            Host *
              IdentityAgent ~/.1password/agent.sock
          '';
        })
        (mkIf (!config."1password".enable) {
          text = ''
            Host github.com
              ForwardAgent yes
          '';
        })
      ];
    })
  ];

}
