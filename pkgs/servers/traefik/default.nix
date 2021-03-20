{ lib, fetchzip, buildGoModule, go-bindata, nixosTests }:

buildGoModule rec {
  pname = "traefik";
  version = "2.4.7";

  src = fetchzip {
    url = "https://github.com/traefik/traefik/releases/download/v${version}/traefik-v${version}.src.tar.gz";
    sha256 = "sha256-K1uSfsi/uC41ukDGaWaYIKX6A+SU59x3a/DYip9/LPI=";
    stripRoot = false;
  };

  vendorSha256 = "sha256-MCQbSy2TOSkZoqC2POIq8mDRld4fe245m0Xe0drxEq8=";

  doCheck = false;

  subPackages = [ "cmd/traefik" ];

  nativeBuildInputs = [ go-bindata ];

  passthru.tests = { inherit (nixosTests) traefik; };

  preBuild = ''
    go generate

    CODENAME=$(awk -F "=" '/CODENAME=/ { print $2}' script/binary)

    buildFlagsArray+=("-ldflags=\
      -X github.com/traefik/traefik/v2/pkg/version.Version=${version} \
      -X github.com/traefik/traefik/v2/pkg/version.Codename=$CODENAME")
  '';

  meta = with lib; {
    homepage = "https://traefik.io";
    description = "A modern reverse proxy";
    license = licenses.mit;
    maintainers = with maintainers; [ vdemeester ];
  };
}
