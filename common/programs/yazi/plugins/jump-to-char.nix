{
  inputs,
  ...
}: let
  pluginName = "jump-to-char";
in {
  programs.yazi = {
    keymap.manager.prepend_keymap = [
      {
        desc = "Jump to char";
        on = "f";
        run = "plugin ${pluginName}";
      }
    ];

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";
  };
}
