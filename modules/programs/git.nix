{
  lib,
  pkgs,
  cfgOpts,
  myUser,
  ...
}: let
  cfg = cfgOpts.git;
  gitHubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/+CvZ9Cnq3Y4my0UtpH19dSNBJeT1wCPK7BAJyAvMA";
in {
  options.myOptions.git = {
    libsecret.enable = lib.mkEnableOption "Git via Libsecret";
    oauth.enable = lib.mkEnableOption "Git via Oauth";
    ssh.enable = lib.mkEnableOption "Git via SSH";
  };

  config = {
    myOptions.git.ssh.enable = lib.mkDefault true;

    home-manager.users.${myUser} = lib.mkMerge [
      {
        programs.git = {
          enable = true;
          extraConfig.init.defaultBranch = "main";
          userEmail = "95696624+JaysFreaky@users.noreply.github.com";
          userName = "JaysFreaky";
        };
      }

      # "git-credential-libsecret" stores credentials inside gnome-keyring / kde-wallet
        # Gnome relies upon 'gnome-keyring' and 'seahorse'
        # KDE relies upon 'kwallet', 'kwallet-pam', and 'kwalletmanager'
      (lib.mkIf (cfg.libsecret.enable) {
        programs.git.extraConfig.credential.helper = lib.getExe' pkgs.git.override { withLibsecret = true; } "git-credential-libsecret";
      })

      (lib.mkIf (cfg.oauth.enable) {
        programs.git-credential-oauth.enable = true;
      })

      (lib.mkIf (cfg.ssh.enable) {
        programs = {
          git.extraConfig = {
            commit.gpgsign = true;
            gpg = {
              format = "ssh";
              ssh.program = (
                if (cfgOpts."1password".enable)
                  then (lib.getExe' pkgs._1password-gui "op-ssh-sign")
                else "" # TBD
              );
            };
            user.signingkey = gitHubKey;
          };

          ssh = let
            identityAgent = (
              if (cfgOpts."1password".enable)
                then "/home/${myUser}/.1password/agent.sock"
              else "" # TBD
            );
          in {
            enable = true;
            matchBlocks = {
              "FW13" = {
                extraOptions.IdentityAgent = identityAgent;
                forwardAgent = true;
              };
              "T1" = {
                extraOptions.IdentityAgent = identityAgent;
                forwardAgent = true;
              };
              "T450s" = {
                extraOptions.IdentityAgent = identityAgent;
                forwardAgent = true;
              };

              "github.com".match = ''
                host github.com exec "test -z $SSH_TTY"
                  IdentityAgent ${identityAgent}
              '';
            };
          };
        };
      })
    ];
  };
}
