{ lib
, stdenv
, fetchurl
, perl
, libtool
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "libvterm-neovim";
  # Releases are not tagged, look at commit history to find latest release
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "neovim";
    repo = "libvterm";
    rev = "9d6d2112335080312ef8c36667fa717ded4f7daf";
    sha256 = "sha256-aQJFrDZGLMT0B8Gzj9Jpyyk9eWnuPO2VyuP8/0f/+Yw=";
  };

  nativeBuildInputs = [ perl libtool ];

  makeFlags = [
    "CC=${stdenv.cc.targetPrefix}cc"
    "LIBTOOL=${libtool}/bin/libtool"
    "PREFIX=$(out)"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "VT220/xterm/ECMA-48 terminal emulator library";
    homepage = "http://www.leonerd.org.uk/code/libvterm/";
    license = licenses.mit;
    maintainers = with maintainers; [ rvolosatovs ];
    platforms = platforms.unix;
  };
}
