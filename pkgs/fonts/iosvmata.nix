{
  lib,
  stdenv,
  fetchurl,
  zstd
}: let
  pname = "iosvmata-font";
  version = "1.2.0";
  src = fetchurl {
    url = "https://github.com/N-R-K/Iosvmata/releases/download/v${version}/Iosvmata-v${version}.tar.zst";
    hash = "sha256-Cq/bx+nc5sTHxb4GerpEHDmW7st835bQ6ihTOp20Ei4=";
  };
in stdenv.mkDerivation {
  inherit pname version src;
  dontUnpack = true;
  nativeBuildInputs = [ zstd ];
  installPhase = ''
    tar xvf ${src}
    mkdir -p $out/share/fonts/truetype
    install --mode=644 ./Iosvmata-v${version}/Normal/*.ttf $out/share/fonts/truetype
  '';

  meta = {
    inherit lib;
    description = "Custom Iosevka build somewhat mimicking PragmataPro";
    homepage = "https://github.com/N-R-K/Iosvmata";
  };
}
