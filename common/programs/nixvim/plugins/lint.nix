{
  pkgs,
  ...
}: {
  # Linting
  programs.nixvim = {
    autoCmd = [
      # Create autocommand which carries out the actual linting
      # on the specified events.
      {
        event = [
          "BufEnter"
          "BufWritePost"
          "InsertLeave"
        ];
        callback.__raw = ''
          function()
            require('lint').try_lint()
          end
        '';
        #desc = "";
        group = "lint";
      }
    ];

    autoGroups.lint.clear = true;

    # Be sure to install the corresponding pkg for the below linters
    extraPackages = [
      pkgs.markdownlint-cli
    ];

    plugins.lint = {
      enable = true;
      lintersByFt = {
        markdown = [
          "markdownlint"
          #"vale"
        ];
        nix = [ "nix" ];
      };
    };
  };
}
