{
  programs.nixvim.plugins = {
    #image.enable = true; # Enabled in image.nix
    nui.enable = true;
    #web-devicons.enable = true;  # Enabled in telescope.nix

    neo-tree = {
      enable = true;
      filesystem.window.mappings = { };
      window.mappings = { };
    };
  };
}
