{
  inputs,
  ...
}: let
  pluginName = "git";
in {
  # Show the status of GIt file changes as linemode in the file list
  programs.yazi = {
    initLua = ''
      THEME.git = THEME.git or {}
      THEME.git.added_sign = "A"
      THEME.git.deleted_sign = "D"
      ---THEME.git.ignored_sign = ""
      THEME.git.modified_sign = "M"
      ---THEME.git.untracked_sign = ""
      ---THEME.git.updated_sign = ""

      require("${pluginName}"):setup()
    '';

    plugins.${pluginName} = inputs.yazi-plugins + "/${pluginName}.yazi";

    settings.plugin.prepend_fetchers = [
      {
        id = "git";
        name = "*";
        run = pluginName;
      }
      {
        id = "git";
        name = "*/";
        run = pluginName;
      }
    ];
  };
}
