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

    environment.variables.SSH_AUTH_SOCK = lib.mkIf (cfgOpts."1password".enable) "/home/${vars.user}/.1password/agent.sock";

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
        # Gnome relies upon 'gnome-keyring', 'libsecret', and 'seahorse' pkgs in ../desktops/gnome.nix
        # KDE relies upon 'kwallet', 'kwallet-pam', 'kwalletmanager', and 'libsecret' pkgs in ../desktops/kde.nix ?
      (lib.mkIf (cfg.libsecret.enable) {
        programs.git = {
          extraConfig.credential.helper = "libsecret";
          # gitFull contains git-credential-libsecret
          package = pkgs.gitFull;
        };
      })

      # OAuth does not require additional pkgs like libsecret
      (lib.mkIf (cfg.oauth.enable) {
        programs.git-credential-oauth.enable = true;
      })

      # SSH signing/commit
      (lib.mkIf (cfg.ssh.enable) {
        programs = {
          git.extraConfig = {
            commit.gpgsign = true;
            gpg = {
              format = "ssh";
              ssh.program = (if (cfgOpts."1password".enable)
                then "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}"
                else "${lib.getExe' pkgs.openssh "ssh-agent"}"
              );
            };
            user.signingkey = gitHubKey;
          };

          ssh = {
            enable = true;
            matchBlocks = {
              "github.com" = lib.mkIf (cfgOpts."1password".enable) {
                forwardAgent = true;
                match = ''
                  Host github.com exec "test -z $SSH_TTY"
                    IdentityAgent /home/${vars.user}/.1password/agent.sock
                '';
                #extraOptions.IdentityAgent = "/home/${vars.user}/.1password/agent.sock";
              };
            };
          };
        };
      })
    ];
  };
}
