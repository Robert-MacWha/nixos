{ pkgs, ... }:
let
  rofi-vscode = pkgs.writeShellScriptBin "rofi-vscode" (builtins.readFile ./vscode.sh);
  rofi-watson = pkgs.writeShellScriptBin "rofi-watson" (builtins.readFile ./watson.sh);
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "rofi-launch" ''
      exec rofi -show combi
    '')
  ];

  programs.rofi = {
    enable = true;
    theme = "Adapta-Nokto";
    modes = [
      "combi"
      "drun"
      "ssh"
      "vs:${rofi-vscode}/bin/rofi-vscode"
      "tt:${rofi-watson}/bin/rofi-watson"
    ];
    extraConfig = {
      show-icons = true;
      show = "combi";
      combi-modes = "drun,ssh,vs,tt";
      combi-hide-mode-prefix = false;
      click-to-exit = true;
      sort = true;
    };
  };
}
