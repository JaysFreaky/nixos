{
  # Shows how to use the DAP plugin to debug your code.
  #
  # Primarily focused on configuring the debugger for Go, but can
  # be extended to other languages as well.
  programs.nixvim = {
    extraConfigLua = ''
      require('dap').listeners.after.event_initialized['dapui_config'] = require('dapui').open
      require('dap').listeners.before.event_terminated['dapui_config'] = require('dapui').close
      require('dap').listeners.before.event_exited['dapui_config'] = require('dapui').close
    '';

    # Basic debugging keymaps, feel free to change to your liking!
    keymaps = [
      {
        mode = "n";
        key = "<F5>";
        action.__raw = ''
          function()
            require('dap').continue()
          end
        '';
        options.desc = "Debug: Start/Continue";
      }
      {
        mode = "n";
        key = "<F1>";
        action.__raw = ''
          function()
            require('dap').step_into()
          end
        '';
        options.desc = "Debug: Step Into";
      }
      {
        mode = "n";
        key = "<F2>";
        action.__raw = ''
          function()
            require('dap').step_over()
          end
        '';
        options.desc = "Debug: Step Over";
      }
      {
        mode = "n";
        key = "<F3>";
        action.__raw = ''
          function()
            require('dap').step_out()
          end
        '';
        options.desc = "Debug: Step Out";
      }
      {
        mode = "n";
        key = "<leader>b";
        action.__raw = ''
          function()
            require('dap').toggle_breakpoint()
          end
        '';
        options.desc = "Debug: Toggle Breakpoint";
      }
      {
        mode = "n";
        key = "<leader>B";
        action.__raw = ''
          function()
            require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
          end
        '';
        options.desc = "Debug: Set Breakpoint";
      }
      # Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      {
        mode = "n";
        key = "<F7>";
        action.__raw = ''
          function()
            require('dapui').toggle()
          end
        '';
        options.desc = "Debug: See last session result.";
      }
    ];

    plugins = {
      # Install golang specific config
      dap-go.enable = true;

      # Creates a beautiful debugger UI
      # For more information, see |:help nvim-dap-ui|
      dap-ui = {
        enable = true;
        settings = {
          controls = {
            enabled = true;
            icons = {
              disconnect = "⏏";
              pause = "⏸";
              play = "▶";
              run_last = "▶▶";
              step_back = "b";
              step_into = "⏎";
              step_out = "⏮";
              step_over = "⏭";
              terminate = "⏹";
            };
          };

          # Set icons to characters that are more likely to work in every terminal.
          # Feel free to remove or use ones that you like more! :)
          icons = {
            collapsed = "▸";
            current_frame = "*";
            expanded = "▾";
          };
        };
      };
    };
  };
}
