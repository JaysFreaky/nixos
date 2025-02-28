{
  inputs,
  ...
}: let
  pluginName = "diff";
in {
  programs.yazi = {
    keymap.manager.prepend_keymap = [
      {
        desc = "Diff the selected w/ the hovered file";
        on = "<C-d>";
        run = "plugin ${pluginName}";
      }
    ];

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";
  };
}
