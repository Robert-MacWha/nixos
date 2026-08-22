{
  lib,
  stdenv,
  python3,
  makeWrapper,
}:

let
  py = python3.withPackages (ps: [
    ps.mcp
    ps.pgpy
  ]);
in
stdenv.mkDerivation {
  pname = "hackenproof-decrypt-proxy";
  version = "0.3.0";

  src = ./proxy.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/libexec
    cp $src $out/libexec/proxy.py
    makeWrapper ${py}/bin/python3 $out/bin/hackenproof-decrypt-proxy \
      --add-flags "$out/libexec/proxy.py"
  '';

  meta.mainProgram = "hackenproof-decrypt-proxy";
}
