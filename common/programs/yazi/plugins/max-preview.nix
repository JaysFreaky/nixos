{
  inputs,
  ...
}: let
  pluginName = "max-preview";
in {
  programs.yazi = {
    keymap.manager.prepend_keymap = [
      {
        desc = "Maximize or restore preview";
        on = "T";
        run = "plugin ${pluginName}";
      }
    ];

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";

    settings.preview = {
      #max_height = ;
      #max_width = ;
    };
  };
}
