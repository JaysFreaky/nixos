{ fetchFromSourcehut, lib, pkgs, stdenv }:

stdenv.mkDerivation {
  name = "framework";
  version = "unstable-2024-05-14";

  src = fetchFromSourcehut {
    owner = "~jameskupke";
    repo = "framework-plymouth-theme";
    rev = "b801f5bbf41df1cd3d1edeeda31d476ebf142f67";
    hash = "sha256-TuD+qHQ6+csK33oCYKfWRtpqH6AmYqvZkli0PtFm8+8=";
  };

  # Local .plymouth file overwrites fetched file, preserving firmware image
  file = ./framework.plymouth;

  dontConfigure = true;
  nativeBuildInputs = with pkgs; [ imagemagick ];
  buildPhase = ''
    buildDir=/tmp/plymouth-fw
    mkdir -p $buildDir
    cp -r $src/framework/* $buildDir/
    chmod -R +w $buildDir/
    cp $file $buildDir/framework.plymouth
    for image in $(ls $buildDir/throbber*.png); do
      convert -resize 25% $image $image;
    done
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plymouth/themes/framework
    cp -r $buildDir/* $out/share/plymouth/themes/framework/ 
    sed -i "s@/usr/@$out/@" $out/share/plymouth/themes/framework/framework.plymouth

    runHook postInstall
  '';

  meta = with lib; {
    description = "Animated Framework logo for Plymouth";
    homepage = "https://git.sr.ht/~jameskupke/framework-plymouth-theme";
    license = licenses.mit;
    maintainers = [ "JaysFreaky" ];
    platforms = platforms.linux;
  };
}
