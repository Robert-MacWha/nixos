{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  cava,
  pipewire,
  python3,
  glib,
  desktop-file-utils,
  appstream-glib,
  gobject-introspection,
}:

stdenv.mkDerivation rec {
  pname = "cavasik";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "TheWisker";
    repo = "Cavasik";
    rev = "v${version}";
    hash = "sha256-O8rFtqzmDktXKF3219RAo1yxqjfPm1qkHhAyoT7N8AU=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapGAppsHook4
    glib
    desktop-file-utils
    appstream-glib
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    libadwaita
    cava
    pipewire
    (python3.withPackages (
      ps: with ps; [
        pygobject3
        pillow
        pydbus
      ]
    ))
  ];

  postPatch = ''
    # Patch cava path
    substituteInPlace src/cava.py \
      --replace-fail '["cava"' '["${cava}/bin/cava"'
  '';

  meta = {
    description = "Audio visualizer based on CAVA with customizable LibAdwaita interface";
    homepage = "https://github.com/TheWisker/Cavasik";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
