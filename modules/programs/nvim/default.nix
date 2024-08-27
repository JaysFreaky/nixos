{ pkgs, vars, ... }: {
  home-manager.users.${vars.user} = {
    home.packages = with pkgs; [
      gcc
      gnumake
      ripgrep
    ];

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs; [
        nil    # Nix language
      ];
    };

    xdg.configFile = {
      "nvim/lua".source = ./lua;
      "nvim/init.lua".source = ./init.lua;
      "nvim/.stylua.toml".source = ./.stylua.toml;
    };

  };
}
