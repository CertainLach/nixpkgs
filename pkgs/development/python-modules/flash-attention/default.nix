{ lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, torch
, packaging
, which

, config
}: let
  inherit (torch) cudaPackages cudaSupport rocmSupport rocmPackages;
  # flash-attention can't be built without cuda and rocm, but with rocm
  # we have somewhat working fallbacks.
in
buildPythonPackage rec {
  pname = "flash-attention";
  version = "2024-02-04";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "ROCm";
    repo = pname;
    rev = "ae7928c5aed53cf6e75cc792baa9126b2abfcf1a";
    hash = "sha256-D7JVPs9tJl2xurWM77nmMARPkK+bzIwSL9KXdhMqUnY=";
    fetchSubmodules = true;
  };

  patches = [
    # setup.py tries to fetch submodules, but we already have
    # fetchSubmodules
    ./0001-fix-submodules-are-fetched.patch
  ];

  # Without FLASH_ATTENTION_FORCE_BUILD it tries to fetch prebuild wheels.
  preBuild = ''
    export FLASH_ATTENTION_FORCE_BUILD=TRUE
  '' + lib.optionalString cudaSupport ''
    export CUDA_HOME=${cudaPackages.cuda_nvcc}
    export BUILD_TARGET=cuda
  '' + lib.optionalString rocmSupport ''
    export BUILD_TARGET=rocm
  '';

  buildInputs = lib.optionals cudaSupport (with cudaPackages; [
    cuda_cudart # cuda_runtime_api.h
    libcusparse.dev # cusparse.h
    cuda_cccl.dev # nv/target
    libcublas.dev # cublas_v2.h
    libcusolver.dev # cusolverDn.h
    libcurand.dev # curand_kernel.h
  ]);

  propagatedBuildInputs = [
    torch
    packaging
  ];

  nativeBuildInputs = [
    which
  ];

  pythonImportsCheck = [
    "flash_attn"
  ];

  meta = with lib; {
    description = "Fast and memory-efficient exact attention";
    homepage = "https://github.com/Dao-AILab/flash-attention";
    license = licenses.bsd3;
    maintainers = with maintainers; [ lach ];
    broken = cudaSupport && rocmSupport || !cudaSupport && !rocmSupport;
  };
}
