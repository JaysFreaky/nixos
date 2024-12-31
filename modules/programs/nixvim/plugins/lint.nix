{
  # Linting
  programs.nixvim = {
    autoCmd = [
      # Create autocommand which carries out the actual linting
      # on the specified events.
      {
        callback.__raw = ''
          function()
            require('lint').try_lint()
          end
        '';
        #desc = "";
        event = [
          "BufEnter"
          "BufWritePost"
          "InsertLeave"
        ];
        group = "lint";
      }
    ];

    autoGroups.lint.clear = true;

    plugins.lint = {
      enable = true;
      lintersByFt = {
        markdown = [ "markdownlint" ];
      };
    };
  };
}
