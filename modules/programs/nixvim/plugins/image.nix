{
  programs.nixvim.plugins.image = {
    enable = true;
    integrations.markdown = {
      enabled = true;
      filetypes = [
        "markdown"
      ];
      onlyRenderImageAtCursor = true;
    };
  };
}
