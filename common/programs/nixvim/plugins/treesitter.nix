{
  pkgs,
  ...
}: {
  # Highlight, edit, and navigate code
  programs.nixvim.plugins.treesitter = {
    enable = true;

    grammarPackages = builtins.attrValues {
      inherit (pkgs.vimPlugins.nvim-treesitter.builtGrammars)
        bash
        #c
        html
        lua
        markdown
        markdown_inline
        nix
        vim
        vimdoc
      ;
    };
    # Whether to install grammars defined in grammarPackages
    nixGrammars = true;

    settings = {
      # Autoinstall languages that are not installed
      #auto_install = true;
      # Not needed when using grammarPackages/nixGrammers
      #ensure_install = [ ];

      highlight = {
        enable = true;
        # Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        # If you are experiencing weird indenting issues, add the language to
        # the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = true;
        disable = [
          #ruby
        ];
      };

      indent.enable = true;
    };

    # There are additional nvim-treesitter modules that you can use to interact
    # w/ nvim-treesitter. You should go explore a few and see what interests you:
    #
    # - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    # - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    # - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  };
}
