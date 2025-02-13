{
  config,
  lib,
  ...
}: {
  # Collection of various small independent plugins/modules
  programs.nixvim.plugins.mini = {
    enable = true;

    modules = {
      # Better Around/Inside textobjects
      #
      # Examples:
      # - va)  - [V]isually select [A]round [)]paren
      # - yinq - [Y]ank [I]nside [N]ext [']quote
      # - ci'  - [C]hange [I]nside [']quote
      ai.n_lines = 500;

      # Add/delete/replace surroundings (brackets, quotes, etc.)
      #
      # Examples:
      # - va)  - [V]isually select [A]round [)]paren
      # - yinq - [Y]ank [I]nside [N]ext [']quote
      # - ci'  - [C]hange [I]nside [']quote
      surround = { };

      # Examples:
      # - va)  - [V]isually select [A]round [)]paren
      # - yinq - [Y]ank [I]nside [N]ext [']quote
      # - ci'  - [C]hange [I]nside [']quote
      statusline = {
        # set use_icons to true if you have a Nerd Font
        use_icons = lib.mkIf (config.programs.nixvim.globals.have_nerd_font) true;
        # You can configure sections in the statusline by overriding their
        # default behavior. For example, here we set the section for
        # cursor location to LINE:COLUMN
        # @diagnostic disable-next-line: duplicate-set-field
        section_location.__raw = ''
          function()
            return '%2l:%-2v'
          end
        '';
        # ... and there is more!
        # Check out: https://github.com/echasnovski/mini.nvim
      };
    };
  };
}
