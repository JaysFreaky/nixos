{ pkgs, ... }: {
  # Autoformat
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;

      settings = {
        notify_on_error = false;
        format_on_save = ''
          function(bufnr)
            -- Disable "format_on_save lsp_fallback" for languages that don't
            -- have a well standardized coding style. You can add additional
            -- languages here or re-enable it for the disabled ones.
            local disable_filetypes = { c = true, cpp = true }
            return {
              timeout_ms = 500,
              lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype]
            }
          end
        '';
        formatters_by_ft = {
          bash = [ "shellcheck" ];
          lua = [ "stylua" ];
        };
      };
    };

    extraPackages = with pkgs; [
      shellcheck
      stylua
    ];
  };
}