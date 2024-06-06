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

  dontConfigure = true;
  nativeBuildInputs = with pkgs; [ imagemagick ];
  buildPhase = ''
    buildDir=/tmp/framework-plymouth
    mkdir -p $buildDir
    cp -r $src/framework/* $buildDir/
    chmod -R +w $buildDir/
    for image in $(ls $buildDir/throbber*.png); do
      convert -resize 25% $image $image;
    done
    sed -i '2s/F/f/' $buildDir/framework.plymouth
    sed -i '8s/3/2/' $buildDir/framework.plymouth
    sed -i '11s/382/8/' $buildDir/framework.plymouth
    sed -i '13s/382/3/' $buildDir/framework.plymouth
    sed -i '15s/5/8/' $buildDir/framework.plymouth
    sed -i '28 i UseFirmwareBackground=true' $buildDir/framework.plymouth
    sed -i '32 i UseFirmwareBackground=true' $buildDir/framework.plymouth
    sed -i '36 i UseFirmwareBackground=true' $buildDir/framework.plymouth
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
