{
  lib,
  mkDerivation,
  cmake,
  extra-cmake-modules,
  makeWrapper,
  shared-mime-info,
  qtbase,
  qtsvg,
  qttools,
  qtwebengine,
  qtxmlpatterns,
  kxmlgui,
  kcmutils,
  kconfig,
  kio,
  kconfigwidgets,
  libgphoto2
}:
mkDerivation {
  pname = "kamera";

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    makeWrapper
    shared-mime-info
    qttools
  ];

  buildInputs = [
    qtbase
    qtsvg
    qtwebengine
    qtxmlpatterns
    kxmlgui
    kcmutils
    kconfig
    kio
    kconfigwidgets
    libgphoto2
  ];

  meta = with lib; {
    description = "Front end to powerful mathematics and statistics packages";
    homepage = "https://kamera.kde.org/";
    license = with licenses; [bsd3 cc0 gpl2Only gpl2Plus gpl3Only];
    maintainers = with maintainers; [hqurve];
  };
}
