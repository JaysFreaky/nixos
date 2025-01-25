{
  cfgOpts,
  lib,
  pkgs,
  vars,
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

    environment = lib.mkMerge [
      (lib.mkIf (cfg.libsecret.enable) {
        systemPackages = with pkgs; [ libsecret ];
      })

      (lib.mkIf (cfg.ssh.enable) {
        #variables."SSH_AUTH_SOCK" = lib.mkIf (cfgOpts."1password".enable) "/home/${vars.user}/.1password/agent.sock";
      })
    ];

    home-manager.users.${vars.user} = lib.mkMerge [
      {
        programs.git = {
          enable = true;
          extraConfig.init.defaultBranch = "main";
          userEmail = "95696624+JaysFreaky@users.noreply.github.com";
          userName = "JaysFreaky";
        };
      }

      # credential.helper = "libsecret" stores credentials inside gnome-keyring / kde-wallet
        # Gnome relies upon 'gnome-keyring' and 'seahorse'
        # KDE relies upon 'kwallet', 'kwallet-pam', and 'kwalletmanager'
      (lib.mkIf (cfg.libsecret.enable) {
        programs.git = {
          extraConfig.credential.helper = "libsecret";
          # gitFull contains git-credential-libsecret
          package = pkgs.gitFull;
        };
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
              ssh.program = lib.mkIf (cfgOpts."1password".enable) (lib.getExe' pkgs._1password-gui "op-ssh-sign");
            };
            user.signingkey = gitHubKey;
          };

          ssh = {
            enable = false;
            matchBlocks = {
              "github.com" = lib.mkIf (cfgOpts."1password".enable) {
                forwardAgent = true;
                match = ''
                  Host github.com exec "test -z $SSH_TTY"
                    IdentityAgent /home/${vars.user}/.1password/agent.sock
                '';
              };
            };
          };
        };
      })
    ];
  };
}
