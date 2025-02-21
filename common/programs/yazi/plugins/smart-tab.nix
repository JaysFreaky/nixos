let
  pluginName = "smart-tab";
in {
  programs.yazi.keymap.manager.prepend_keymap = [
    {
      desc = "Create a tab and enter the hovered directory";
      on = "t";
      run = "plugin ${pluginName}";
    }
  ];

  xdg.configFile."yazi/plugins/${pluginName}.yazi/main.lua".text = ''
    --- @sync entry
    return {
      entry = function()
        local h = cx.active.current.hovered
        ya.manager_emit("tab_create", h and h.cha.is_dir and { h.url } or { current = true })
      end,
    }
  '';
}
