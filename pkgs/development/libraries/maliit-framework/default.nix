{ lib
, stdenv
, fetchFromGitHub
, qt5
, wayland
, wayland-protocols
, cmake
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "maliit-framework";
  version = "2.1.1";

  src = fetchFromGitHub {
    owner = "maliit";
    repo = "framework";
    rev = version;
    sha256 = "sha256-WfOIv+8QYxyhRIssetK+5YBc+E7awmWt9RU7docw+vU=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = with qt5; [
    qtbase
    qtdeclarative
    qtwayland
    wayland
    wayland-protocols
  ];

  dontWrapQtApps = true;

  cmakeFlags = [ "-Denable-dbus-activation=ON" "-Denable-wayland-gtk=ON" "-Denable-docs=OFF" ];

  meta = with lib; {
    description = "Core libraries of Maliit and server";
    longDescription = ''
      Maliit provides a flexible and cross-platform input method framework
      for mobile and embedded text input, including a virtual keyboard.
      It has a plugin-based client-server architecture where applications
      act as clients and communicate with the Maliit server via input context plugins.
    '';
    license = with licenses; [ lgpl2 ];
    maintainers = with maintainers; [ lach ];
  };
}
