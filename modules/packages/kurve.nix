{
  stdenv,
  lib,
  fetchFromGitHub,
  nix-update-script,
  kdePackages,
  cava,
  python3,
  cmake,
  qt6,
}:
let
  pythonEnv = python3.withPackages (ps: [ ps.websockets ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kurve";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "kurve";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TWNgQUgjrlzQs+cjzfoD13dHG3M93Akxyg5VNB9Rp9E=";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    kdePackages.plasma5support
    kdePackages.kwindowsystem
    qt6.qtbase
    qt6.qtwebsockets
  ];

  cmakeFlags = [
    "-DBUILD_PLUGIN=ON"
  ];

  postPatch = ''
    # Set cava path
    substituteInPlace package/contents/ui/Cava.qml --replace-fail "cava -p" "${cava}/bin/cava -p"
    substituteInPlace package/contents/ui/FullRepresentation.qml --replace-fail "cava -v" "${cava}/bin/cava -v"

    # Set python path
    substituteInPlace package/contents/ui/tools/commandMonitor --replace-fail "#!/usr/bin/env python3" "#!${pythonEnv}/bin/python3"
  '';

  postInstall = ''
    # Copy plasmoid to correct location
    mkdir -p $out/share/plasma/plasmoids/luisbocanegra.audio.visualizer
    cp -r ../package/* $out/share/plasma/plasmoids/luisbocanegra.audio.visualizer/
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "KDE Plasma widget displaying CAVA audio visualizations";
    homepage = "https://github.com/luisbocanegra/kurve";
    changelog = "https://github.com/luisbocanegra/kurve/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ chrisheib ];
    inherit (kdePackages.kwindowsystem.meta) platforms;
  };
})
