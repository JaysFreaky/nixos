{ pkgs, vars, ... }: {
  home-manager.users.${vars.user} = {
    programs.neovim = {
      enable = true;
      viAlias = false;
      vimAlias = false;
      extraPackages = with pkgs; [
      # LSP
        nil       # Nix

      # Tools
        gcc
        gnumake
        ripgrep
      ];
      plugins = with pkgs.vimPlugins; [ ];
    };

    xdg.configFile = {
      "nvim/lua".source = ./lua;
      "nvim/init.lua".source = ./init.lua;
      "nvim/.stylua.toml".source = ./.stylua.toml;
    };

  };
}
