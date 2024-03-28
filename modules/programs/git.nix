{ pkgs, vars, ... }:
let
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/+CvZ9Cnq3Y4my0UtpH19dSNBJeT1wCPK7BAJyAvMA";
in {
  # Using credential.helper = "libsecret"; stores credentials inside gnome-keyring
  # Relies upon gnome-keyring, libsecret, and seahorse setup in gnome.nix
  home-manager.users.${vars.user} = {
    programs.git = {
      enable = true;
      # gitFull contains git-credential-libsecret
      package = pkgs.gitFull;
      userEmail = "95696624+JaysFreaky@users.noreply.github.com";
      userName = "JaysFreaky";

      extraConfig = {
        commit.gpgsign = true;
        #credential.helper = "libsecret";
        gpg = {
          format = "ssh";
          ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        };
        init.defaultBranch = "main";
        user.signingkey = publicKey;
      };
    };

    # Uses OAuth instead of libsecret - not as much setup/requirements
    # Auto-injected into ~/.config/git
    programs.git-credential-oauth.enable = true;
  };
}
