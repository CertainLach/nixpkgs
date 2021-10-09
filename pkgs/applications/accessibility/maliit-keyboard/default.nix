{ lib
, stdenv
, fetchFromGitHub
, glib
, wrapGAppsHook
, qt5
, wayland
, wayland-protocols
, cmake
, pkg-config
, maliit-framework
, presage
, hunspell
, anthy
, libpinyin
}:

stdenv.mkDerivation rec {
  pname = "maliit-keyboard";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "maliit";
    repo = "keyboard";
    rev = version;
    sha256 = "sha256-8TXBoNuT3wi0LxHmL50Q9eTbN8HGUCBT3u+ypNldmo4=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = with qt5; [
    presage
    hunspell
    anthy
    libpinyin
    glib
    qtbase
    qtdeclarative
    qtmultimedia
    qtwayland
    wrapQtAppsHook
    wrapGAppsHook
    wayland
    wayland-protocols
    maliit-framework
  ];

  postInstall = ''
    glib-compile-schemas "$out"/share/glib-2.0/schemas
  '';

  cmakeFlags = [  ];

  meta = with lib; {
    description = "Virtual keyboard based on Maliit framework";
    longDescription = ''
      Maliit provides a flexible and cross-platform input method framework
      for mobile and embedded text input, including a virtual keyboard.
      It has a plugin-based client-server architecture where applications
      act as clients and communicate with the Maliit server via input context plugins.
    '';
    license = with licenses; [ bsd2 ];
    maintainers = with maintainers; [ lach ];
  };
}
