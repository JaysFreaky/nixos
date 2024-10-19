{  lib, pkgs, ... }: let
  find-generation = let
    home-manager = lib.getExe pkgs.home-manager;
    find = lib.getExe' pkgs.toybox "find";
    grep = lib.getExe' pkgs.toybox "grep";
    head = lib.getExe' pkgs.toybox "head";
  in ''
    for line in $(${home-manager} generations | ${grep} -o '/.*'); do
      res=$(${find} "$line" | ${grep} specialisation | ${head} -1)
      output=$?
      if [[ $output -eq 0 ]] && [[ $res != "" ]]; then
        echo "$res"
        exit
      fi
    done
  '';
in pkgs.writeShellScriptBin "switch-mode" ''
  $(${find-generation})/$@/activate
''
