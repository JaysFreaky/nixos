{
  inputs,
  ...
}: let
  pluginName = "chmod";
in {
  programs.yazi = {
    keymap.manager.prepend_keymap = [
      {
        desc = "Chmod on selected files";
        on = [ "c" "m" ];
        run = "plugin ${pluginName}";
      }
    ];

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";
  };
}
