{
  programs.nixvim.plugins.image = {
    enable = true;
    settings.integrations.markdown = {
      enabled = true;
      filetypes = [
        "markdown"
      ];
      onlyRenderImageAtCursor = true;
    };
  };
}
