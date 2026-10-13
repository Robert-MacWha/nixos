{ pkgs, ... }:
let
  libresplit-wrapped = pkgs.symlinkJoin {
    name = "libresplit-wrapped";
    paths = [ pkgs.libresplit ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/libresplit \
        --set GDK_BACKEND x11 \
        --set LIBRESPLIT_FORCE_GLOBAL_HOTKEYS 1
    '';
  };
in
{
  environment.systemPackages = [ libresplit-wrapped ];
}
