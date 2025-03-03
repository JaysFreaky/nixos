{
  config,
  inputs,
  lib,
  myUser,
  ...
}: let
  stylix = config.stylix.enable;
in { 
  home-manager.users.${myUser} = { config, ... }: {
    imports = [
      inputs.nixvim.homeManagerModules.nixvim
      ./plugins
    ];

    programs.nixvim = {
      enable = true;

      # See `:help lua-guide-autocommands`
      autoCmd = [
        # Highlight when yanking (copying) text
        # Try it w/ `yap` in normal mode
        # See `:help vim.highlight.on_yank()`
        {
          event = [ "TextYankPost" ];
          callback.__raw = ''
            function()
              vim.highlight.on_yank()
            end
          '';
          desc = "Highlight when yanking (copying) text";
          group = "kickstart-highlight-yank";
        }

        # Spellchecking
        {
          event = [ "FileType" ];
          callback.__raw = ''
            function(opts)
              local cmp = require("cmp")
              cmp.setup.buffer({ enabled = false })
              vim.opt.spelllang = "en_us"
              vim.opt.spell = true
            end
          '';
          pattern = [
            "markdown"
            "txt"
          ];
        }
      ];

      autoGroups.kickstart-highlight-yank.clear = true;

      # Sync clipboard between OS and Neovim.
      # See `:help 'clipboard'`
      clipboard = {
        providers.wl-copy.enable = true;
        register = "unnamedplus";
      };

      colorschemes = lib.mkIf (!stylix) {
        catppuccin = {
          enable = true;
          settings.flavour = "auto";
        };
      };

      globals = {
        # Set <space> as the leader key
        # See `:help mapleader`
        mapleader = " ";
        maplocalleader = " ";

        # Set to true if you have a Nerd Font installed
        have_nerd_font = true;
      };

      # See `:help vim.opt`
      opts = {
        # Make line numbers default
        number = true;
        # You can also add relative line numbers, to help w/ jumping.
        relativenumber = true;

        # Enable mouse mode, can be useful for resizing splits for example!
        mouse = "a";

        # Don't show the mode, since it's already in the status line
        showmode = false;

        # Enable break indent
        breakindent = true;

        # Indent spacing
        smartindent = true;
        tabstop = 2;
        shiftwidth = 2;

        # Save undo history
        undofile = true;

        # Case-insensitive searching UNLESS \C or one or more capital letters in the search term
        ignorecase = true;
        smartcase = true;

        # Keep signcolumn on by default
        signcolumn = "yes";

        # Decrease update time
        updatetime = 250;

        # Decrease mapped sequence wait time
        # Displays which-key popup sooner
        timeoutlen = 300;

        # Configure how new splits should be opened
        splitright = true;
        splitbelow = true;

        # Sets how neovim will display certain whitespace characters in the editor.
        # See `:help 'list'` and `:help 'listchars'`
        list = true;
        listchars = {
          tab = "» ";
          trail = "·";
          nbsp = "␣";
        };

        # Preview substitutions live, as you type!
        inccommand = "split";

        # Show which line your cursor is on
        cursorline = true;

        # Minimal number of screen lines to keep above and below the cursor.
        scrolloff = 10;

        # Set highlight on search
        hlsearch = true;

        # Determine how text w/ the "conceal" syntax attribute is shown - useful for Markdown
        conceallevel = 2;
      };


      # See `:help vim.keymap.set()`
      keymaps = [
        # Clear search highlighting on pressing <Esc> in normal mode
        {
          mode = "n";
          key = "<Esc>";
          action = "<cmd>nohlsearch<CR>";
        }

        # Diagnostic keymaps
        {
          mode = "n";
          key = "[d";
          action = "vim.diagnostic.goto_prev";
          options.desc = "Go to previous [D]iagnostic message";
        }
        {
          mode = "n";
          key = "]d";
          action = "vim.diagnostic.goto_next";
          options.desc = "Go to next [D]iagnostic message";
        }
        {
          mode = "n";
          key = "<leader>e";
          action = "vim.diagnostic.open_float";
          options.desc = "Show diagnostic [E]rror messages";
        }
        {
          mode = "n";
          key = "<leader>q";
          action = "vim.diagnostic.setloclist";
          options.desc = "Open diagnostic [Q]uickfix list";
        }

        # Exit terminal mode in the builtin terminal w/ a shortcut that is a bit easier
        # for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
        # is not what someone will guess w/o a bit more experience.
        #
        # NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
        # or just use <C-\><C-n> to exit terminal mode
        {
          mode = "t";
          key = "<Esc><Esc>";
          action = "<C-\\><C-n>";
          options.desc = "Exit terminal mode";
        }

        # TIP: Disable arrow keys in normal mode
        /*
        {
          mode = "n";
          key = "<left>";
          action = "<cmd>echo 'Use h to move!!'<CR>";
        }
        {
          mode = "n";
          key = "<right>";
          action = "<cmd>echo 'Use l to move!!'<CR>";
        }
        {
          mode = "n";
          key = "<up>";
          action = "<cmd>echo 'Use k to move!!'<CR>";
        }
        {
          mode = "n";
          key = "<down>";
          action = "<cmd>echo 'Use j to move!!'<CR>";
        }
        */

        # Keybinds to make split navigation easier.
        #  Use CTRL+<hjkl> to switch between windows
        #  See `:help wincmd` for a list of all window commands
        {
          mode = "n";
          key = "<C-h>";
          action = "<C-w><C-h>";
          options.desc = "Move focus to the left window";
        }
        {
          mode = "n";
          key = "<C-l>";
          action = "<C-w><C-l>";
          options.desc = "Move focus to the right window";
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<C-w><C-k>";
          options.desc = "Move focus to the upper window";
        }
        {
          mode = "n";
          key = "<C-j>";
          action = "<C-w><C-j>";
          options.desc = "Move focus to the lower window";
        }
        {
          mode = "x";
          key = "<leader>p";
          action = "\"_dP";
          options = {
            desc = "Keep text contents in clipboard";
            noremap = true;
          };
        }
        {
          mode = "n";
          key = "<C-d>";
          action = "<C-d>zz";
          options.noremap = true;
        }
        {
          mode = "n";
          key = "<C-u>";
          action = "<C-u>zz";
          options.noremap = true;
        }
        {
          mode = "n";
          key = "n";
          action = "nzzzv";
          options.noremap = true;
        }
        {
          mode = "n";
          key = "N";
          action = "Nzzzv";
          options.noremap = true;
        }
      ];

      plugins = {
        # "gc" to comment visual regions/lines
        comment.enable = true;

        # Adds git related signs to the gutter, as well as utilities for managing changes
        # See `:help gitsigns` to understand what the configuration keys do
        gitsigns = {
          enable = true;
          settings.signs = {
            add.text = "+";
            change.text = "~";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
        };

        # Add indentation guides even on blank lines
        indent-blankline.enable = true;

        # Detect tabstop and shiftwidth automatically
        sleuth.enable = true;

        # Highlight todo, notes, etc in comments
        todo-comments = {
          enable = true;
          settings.signs = false;
        };

        # Vim game/tutorial
        vim-be-good.enable = true;
      };
    };
  };
}
