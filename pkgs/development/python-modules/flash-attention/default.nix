{ lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, torch
, packaging

, config
, cudaSupport ? config.cudaSupport
, cudaPackages
}: let
  inherit (torch) cudaPackages cudaSupport;
in
buildPythonPackage rec {
  pname = "flash-attention";
  version = "2.3.6";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "Dao-AILab";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Hvc2itZWBT7K35EyiaAK0Htba/knZWfbDQUDBntTeRM=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-fix-submodules-are-fetched.patch
  ];

  preBuild = lib.optionalString (!cudaSupport) ''
    export FLASH_ATTENTION_SKIP_CUDA_BUILD=TRUE
  '';

  propagatedBuildInputs = [
    torch
    packaging
  ];

  pythonImportsCheck = [
    "flash_attn"
  ];

  meta = with lib; {
    description = "Fast and memory-efficient exact attention";
    homepage = "https://github.com/Dao-AILab/flash-attention";
    license = licenses.bsd3;
    maintainers = with maintainers; [ lach ];
  };
}
