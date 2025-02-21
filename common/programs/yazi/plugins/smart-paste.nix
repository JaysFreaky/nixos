let
  pluginName = "smart-paste";
in {
  programs.yazi.keymap.manager.prepend_keymap = [
    {
      desc = "Paste into the hovered directory or CWD";
      on = "p";
      run = "plugin ${pluginName}";
    }
  ];

  xdg.configFile."yazi/plugins/${pluginName}.yazi/main.lua".text = ''
    --- @sync entry
    return {
      entry = function()
        local h = cx.active.current.hovered
        if h and h.cha.is_dir then
          ya.manager_emit("enter", {})
          ya.manager_emit("paste", {})
          ya.manager_emit("leave", {})
        else
          ya.manager_emit("paste", {})
        end
      end,
    }
  '';
}
