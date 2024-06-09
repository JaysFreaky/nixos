{ pkgs, vars, ... }:
let
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/+CvZ9Cnq3Y4my0UtpH19dSNBJeT1wCPK7BAJyAvMA";
in {
  # credential.helper = "libsecret" stores credentials inside gnome-keyring
    # relies upon 'gnome-keyring', 'libsecret', and 'seahorse' pkgs in gnome.nix
  home-manager.users.${vars.user} = {
    programs.git = {
      enable = true;
      # gitFull contains git-credential-libsecret
      package = pkgs.gitFull;

      extraConfig.init.defaultBranch = "main";
      userEmail = "95696624+JaysFreaky@users.noreply.github.com";
      userName = "JaysFreaky";

      # libsecret
      #extraConfig.credential.helper = "libsecret";

      # SSH signing/commits
      extraConfig = {
        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        };
        user.signingkey = publicKey;
      };
    };

    # Use either OAuth below or libsecret above (if not using SSH) - not both
    # OAuth does not require additional pkgs like libsecret
    #programs.git-credential-oauth.enable = true;
  };

}
