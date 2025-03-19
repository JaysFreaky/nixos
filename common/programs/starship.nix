{
  myUser,
  ...
}: {
  home-manager.users.${myUser} = {
    programs.starship.enable = true;  # Adds to .bashrc automatically

    xdg.configFile."starship.toml".text = ''
      "$schema" = "https://starship.rs/config-schema.json"

      continuation_prompt = "󰘍 "

      #[](fg:white)\
      #[](fg:white bg:purple)\
      #[ ](bg:purple)\
      #[](fg:purple bg:yellow)\
      #[](fg:yellow)

      #[black](black)[red](red)[green](green)[blue](blue)[yellow](yellow)[purple](purple)[cyan](cyan)[white](white)
      #[black](bright-black)[red](bright-red)[green](bright-green)[blue](bright-blue)[yellow](bright-yellow)[purple](bright-purple)[cyan](bright-cyan)[white](bright-white)

      format = """
      [╭╴ ]()\
      $os\
      $sudo\
      $username\
      $hostname\
      $directory\
      $git_branch\
      $git_status\
      $git_metrics\
      [ ]()\
      $aws\
      $azure\
      $c\
      $cmake\
      $direnv\
      $gcloud\
      $golang\
      $java\
      $lua\
      $nix_shell\
      $nodejs\
      $php\
      $python\
      $rust\
      $terraform\
      $zig\
      $container\
      $docker_context\
      $kubernetes\
      $cmd_duration\
      $time
      $character
      """

      [os]
      format = "[$symbol](bold)  "
      disabled = false

      [os.symbols]
      Alpine = ""
      Arch = ""
      CentOS = ""
      Debian = ""
      Fedora = ""
      Linux = ""
      NixOS = ""
      openSUSE = ""
      Redhat = ""
      RedHatEnterprise = ""
      SUSE = ""

      [sudo]
      format = "[$symbol]($style)"
      symbol = "!"
      style = "bold bright-red"
      disabled = false

      [username]
      style_root = "bold red"
      style_user = ""
      format = "[$user]($style)"
      show_always = true

      [hostname]
      ssh_only = true
      #ssh_symbol = "(󰣀)"
      trim_at = "."
      format = "[@](bold blue)[$hostname]()"

      [directory]
      truncation_length = 3
      truncate_to_repo = true
      format = "[:](bold bright-blue)[$path]($style)[$read_only]($read_only_style)"
      style = "bold blue"
      read_only = " "
      read_only_style = "red"
      truncation_symbol = "…/"
      home_symbol = "~"

      [git_branch]
      format = " on [$symbol \\[$branch(:$remote_name)\\]]($style)"
      symbol = ""
      style = "bold purple"

      [git_status]
      format = "( [\\[$all_status$ahead_behind\\]]($style))"
      conflicted = "≠"
      ahead = '󰁝$count'
      behind = '󰁅$count'
      diverged = '󰹹󰁝$ahead_count󰁅$behind_count'
      up_to_date = ""
      untracked = "?"
      stashed = "$"
      modified = "!"
      staged = "[+\\($count\\)](green)"
      renamed = "󰄾"
      deleted = "x"
      style = "bold yellow"

      [git_metrics]
      added_style = "green"
      deleted_style = "red"
      format = "( [+$added]($added_style))( [-$deleted]($deleted_style))"
      disabled = false

      [cmd_duration]
      format = "[|](bold bright-blue) took [$duration]($style) "
      style = "bright-white"

      [time]
      format = "[|](bold bright-blue) 󰅐 [$time]($style)"
      style = ""
      disabled = true

      [character]
      format = "╰─$symbol "
      success_symbol = "[](bold green)"
      error_symbol = "[](bold red)"

      [aws]
      symbol = "aws "

      [azure]
      symbol = "az "

      [c]
      symbol = "C "

      [cmake]
      symbol = "cmake "

      [container]
      symbol = "⬢"

      [direnv]
      symbol = "direnv "

      [docker_context]
      symbol = "docker "

      [gcloud]
      symbol = "gcp "

      [golang]
      symbol = "go "

      [java]
      symbol = "java "

      [kubernetes]
      symbol = "kube "
      #disabled = false

      [lua]
      symbol = "lua "

      [nix_shell]
      symbol = "nix-shell "

      [nodejs]
      symbol = "nodejs "

      [php]
      symbol = "php "

      [python]
      symbol = "py "

      [rust]
      symbol = "rs "

      [terraform]
      symbol = "terraform "

      [zig]
      symbol = "zig "
    '';
  };
}
