{ lib
, buildPythonPackage
, click
, fetchPypi
, packaging
, pytestCheckHook
, requests
}:

buildPythonPackage rec {
  pname = "openwrt-luci-rpc";
  version = "1.1.8";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-bo9HLT0q0yiLJI7i5v/36G82FHbGCtnAI50iGniyKSU=";
  };

  propagatedBuildInputs = [
    click
    requests
    packaging
  ];

  checkInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [ "openwrt_luci_rpc" ];

  meta = with lib; {
    description = "Python module for interacting with the OpenWrt Luci RPC interface";
    longDescription = ''
      This module allows you to use the Luci RPC interface to fetch connected devices
      on your OpenWrt based router. Supports 15.X & 17.X & 18.X or newer releases of
      OpenWrt.
    '';
    homepage = "https://github.com/fbradyirl/openwrt-luci-rpc";
    license = licenses.asl20;
    maintainers = with maintainers; [ matt-snider ];
  };
}
