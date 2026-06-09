{ pkgs, unstable }:

# https://github.com/SoftFever/OrcaSlicer/issues/8145#issuecomment-3507303598
pkgs.symlinkJoin {
  name = "orca-slicer";

  paths = [ unstable.orca-slicer ];

  buildInputs = [ pkgs.makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/orca-slicer \
      --prefix LC_ALL : C \
      --prefix MESA_LOADER_DRIVER_OVERRIDE : zink \
      --prefix WEBKIT_DISABLE_DMABUF_RENDERER : 1 \
      --prefix __EGL_VENDOR_LIBRARY_FILENAMES : ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
      --prefix GALLIUM_DRIVER : zink
  '';
}
