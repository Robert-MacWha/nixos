{
  appimageTools,
  fetchurl,
  lib,
}:
let
  pname = "rotki";
  version = "1.41.2";

  src = fetchurl {
    url = "https://github.com/rotki/rotki/releases/download/v${version}/${pname}-linux_x86_64-v${version}.AppImage";
    hash = "sha256:1ki6bzra6xmjh91cnmvy8qn3mvmm21pppvjfflkn9vxwgjqa8ijr";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/rotki.desktop $out/share/applications/rotki.desktop
    substituteInPlace $out/share/applications/rotki.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=rotki'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Portfolio tracking and accounting tool for cryptocurrencies";
    homepage = "https://rotki.com";
    license = lib.licenses.agpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "rotki";
  };
}
