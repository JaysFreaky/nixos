{
  inputs,
  ...
}: let
  pluginName = "full-border";
in {
  programs.yazi = {
    initLua = ''
      require("${pluginName}"):setup {
        -- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
        type = ui.Border.ROUNDED,
      }
    '';

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";
  };
}
