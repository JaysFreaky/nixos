let
  pluginName = "arrow";
in {
  # File navigation wraparound
  programs.yazi.keymap.manager.prepend_keymap = [
    # Wrap to top
    {
      on = "j";
      run = "plugin ${pluginName} 1";
    }
    # Wrap to bottom
    {
      on = "k";
      run = "plugin ${pluginName} -1";
    }
  ];

  xdg.configFile."yazi/plugins/${pluginName}.yazi/main.lua".text = ''
    --- @sync entry
    return {
      entry = function(_, job)
        local current = cx.active.current
        local new = (current.cursor + job.args[1]) % #current.files
        ya.manager_emit("arrow", { new - current.cursor })
      end,
    }
  '';
}
