{
  pkgs,
  config,
  anyrun-plugins,
  ...
}:
{
  programs.anyrun = {
    enable = true;
    config = {
      x = {
        fraction = 0.5;
      };
      y = {
        fraction = 0.35;
      };
      width = {
        fraction = 0.4;
      };
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;

      plugins = [
        "${anyrun-plugins.watson}/lib/libanyrun_watson.so"
        "${anyrun-plugins.timestamp}/lib/libanyrun_timestamp.so"
        "${anyrun-plugins.vscode}/lib/libanyrun_vscode.so"
        "${anyrun-plugins.todo}/lib/libanyrun_todo.so"
        "${pkgs.anyrun}/lib/libapplications.so"
      ];
    };
  };

  systemd.user.services.anyrun = {
    Unit = {
      Description = "anyrun daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${config.programs.anyrun.package}/bin/anyrun daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
