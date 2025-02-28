{
  # Autocompletion
  programs.nixvim = {
    plugins = {
      # Snippet Engine & its associated nvim-cmp source
      luasnip = {
        enable = true;
        fromVscode = [ {} ];
      };
      # friendly-snippets` contains a variety of premade snippets.
      # See the README about individual language/framework/plugin snippets:
      # https://github.com/rafamadriz/friendly-snippets
      friendly-snippets.enable = true;
      cmp_luasnip.enable = true;
      # Adds other completion capabilities.
      # nvim-cmp does not ship w/ all sources by default. They are split
      # into multiple repos for maintenance purposes.
      cmp-nvim-lsp.enable = true;
      cmp-path.enable = true;

      cmp = {
        enable = true;
        settings = {
          snippet.expand = ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';

          completion.completeopt = "menu,menuone,noinsert";

          # For an understanding of why these mappings were
          # chosen, you will need to read `:help ins-completion`
          #
          # No, but seriously. Please read `:help ins-completion`, it is really good!
          #
          # For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          # https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
          mapping = {
            # Select the [n]ext item
            "<C-n>" = "cmp.mapping.select_next_item()";
            # Select the [p]revious item
            "<C-p>" = "cmp.mapping.select_prev_item()";
            # Scroll the documentation window [b]ack / [f]orward
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            # Accept ([y]es) the completion.
            # This will auto-import if your LSP supports it.
            # This will expand snippets if the LSP sent a snippet.
            "<C-y>" = "cmp.mapping.confirm { select = true }";
            # Manually trigger a completion from nvim-cmp.
            # Generally you don't need this, because nvim-cmp will display
            # completions whenever it has completion options available.
            "<C-Space>" = "cmp.mapping.complete {}";
            # Think of <c-l> as moving to the right of your snippet expansion.
            #  So if you have a snippet that's like:
            #  function $name($args)
            #    $body
            #  end
            #
            # <c-l> will move you to the right of each of the expansion locations.
            "<C-l>" = ''
              cmp.mapping(function()
                if luasnip.expand_or_locally_jumpable() then
                  luasnip.expand_or_jump()
                end
              end, { 'i', 's' })
            '';

            # <c-h> is similar, except moving you backwards.
            "<C-h>" = ''
              cmp.mapping(function()
                if luasnip.locally_jumpable(-1) then
                  luasnip.jump(-1)
                end
              end, { 'i', 's' })
            '';
          };

          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
          ];
        };
      };
    };
  };
}
