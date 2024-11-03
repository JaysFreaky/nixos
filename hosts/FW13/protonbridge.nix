(final: prev: {
  protonmail-bridge-gui = prev.protonmail-bridge-gui.overrideAttrs (_: {
    postPatch = ''
      # Bypass `vcpkg` by deleting lines that `include` BridgeSetup.cmake
      find . -type f -name "CMakeLists.txt" -exec sed -i "/BridgeSetup\\.cmake/d" {} \;

      # Use the available ICU version
      sed -i "s/libicu\(i18n\|uc\|data\)\.so\.56/libicu\1.so/g" bridge-gui/DeployLinux.cmake

      # Create a Desktop Entry that uses a `protonmail-bridge-gui` binary without upstream's launcher
      sed "s/^\(Icon\|Exec\)=.*$/\1=protonmail-bridge-gui/" ../../../dist/proton-bridge.desktop > proton-bridge-gui.desktop

      # Also update `StartupWMClass` to match the GUI binary's `wmclass` (Wayland app id)
      sed -i "s/^\(StartupWMClass=\)Proton Mail Bridge$/\1ch.proton.bridge-gui/" proton-bridge-gui.desktop

      # Don't build `bridge-gui-tester`
      sed -i "/add_subdirectory(bridge-gui-tester)/d" CMakeLists.txt

      # Qt 6.8 support
      # fix "ColorImage is not a type"
      find . -name '*.qml' -type f -exec sed -i '
      /import QtQuick.Controls/ {
        n
        /import QtQuick.Controls.impl/! {
          i import QtQuick.Controls.impl
        }
      }' {} +
      # fix "Cannot override FINAL property"
      find . -name '*.qml' -type f -exec sed -i 's/\bpopupType\b/protonPopupType/g' {} +
    '';
  });
})
