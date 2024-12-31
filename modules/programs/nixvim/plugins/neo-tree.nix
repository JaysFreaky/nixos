{
  programs.nixvim.plugins = {
    image.enable = true;
    nui.enable = true;
    web-devicons.enable = true;

    neo-tree = {
      enable = true;
      filesystem.window.mappings = { };
      window.mappings = { };
    };
  };
}
