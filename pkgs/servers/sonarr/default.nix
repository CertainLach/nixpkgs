{ lib, stdenv, fetchurl, dotnet-runtime, libmediainfo, sqlite, curl, makeWrapper, nixosTests, openssl, icu, zlib }:

stdenv.mkDerivation rec {
  pname = "sonarr";
  version = "4.0.0.710";

  src = fetchurl {
    url = "https://download.sonarr.tv/v4/develop/${version}/Sonarr.develop.${version}.linux-x64.tar.gz";
    hash = "sha256-6Br196zVjBkRRbDt179G1lUFilR0/PxTK3xNKY1sTrM=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/${pname}-${version}}
    cp -r * $out/share/${pname}-${version}/.

    makeWrapper "${dotnet-runtime}/bin/dotnet" $out/bin/NzbDrone \
      --add-flags "$out/share/${pname}-${version}/Sonarr.dll" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        curl sqlite libmediainfo openssl icu zlib ]}

    runHook postInstall
  '';

  passthru = {
    updateScript = ./update.sh;
    tests.smoke-test = nixosTests.sonarr;
  };

  meta = {
    description = "Smart PVR for newsgroup and bittorrent users";
    homepage = "https://sonarr.tv/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ fadenb purcell ];
    mainProgram = "NzbDrone";
    platforms = lib.platforms.all;
  };
}
