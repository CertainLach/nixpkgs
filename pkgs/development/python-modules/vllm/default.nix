{ lib
, buildPythonPackage
, fetchFromGitHub
, fetchpatch
, which
, ninja
, packaging
, setuptools
, torch
, wheel
, psutil
, ray
, pandas
, pyarrow
, sentencepiece
, numpy
, transformers
, xformers
, fastapi
, uvicorn
, pydantic
, aioprometheus
, writeShellScript

, config

, cudaSupport ? config.cudaSupport
, cudaPackages ? {}

, rocmSupport ? config.rocmSupport
, rocmPackages ? {}
, gpuTargets ? []
}:

let
  version = "0.3.0";
in
buildPythonPackage {
  pname = "vllm";
  inherit version;
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    rev = "v${version}";
    hash = "sha256-ZpVvh/WvKu97t7AMH4BNSsRqqtmzRL1fkdphT4QclOk=";
  };

  # Otherwise it will be built for targets supported by torch, which then wants to
  GPU_ARCHS = lib.optionalString rocmSupport (lib.strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
      gpuTargets
    else
      # vllm supports less gpu targets than rocm clr, supported target list is taken from ROCM_SUPPORTED_ARCHS in setup.py
      lib.lists.intersectLists rocmPackages.clr.gpuTargets ["gfx90a" "gfx908" "gfx906" "gfx1030" "gfx1100"]
  ));

  # xformers 0.0.23.post1 github release specifies its version as 0.0.24
  # hipcc --version works badly on NixOS due to unresolved paths.
  postPatch = ''
    substituteInPlace requirements.txt \
      --replace "xformers == 0.0.23.post1" "xformers == 0.0.24"
  '' + lib.optionalString rocmSupport ''
    substituteInPlace setup.py \
      --replace "'hipcc', '--version'" "'${writeShellScript "hipcc-version-stub" "echo HIP version: 0.0"}'"
  '';

  preBuild = lib.optionalString cudaSupport ''
    export CUDA_HOME=${cudaPackages.cuda_nvcc}
  ''
  + lib.optionalString rocmSupport ''
    export ROCM_HOME=${rocmPackages.clr}
    export PATH=$PATH:${rocmPackages.hipcc}
  '';

  nativeBuildInputs = [
    ninja
    packaging
    setuptools
    torch
    wheel
    which
  ] ++ lib.optionals rocmSupport [
    rocmPackages.hipcc
  ];

  buildInputs = (lib.optionals cudaSupport (with cudaPackages; [
    cuda_cudart # cuda_runtime.h, -lcudart
    cuda_cccl.dev # <thrust/*>
    libcusparse.dev # cusparse.h
    libcublas.dev # cublas_v2.h
    libcusolver # cusolverDn.h
  ])) ++ (lib.optionals rocmSupport (with rocmPackages; [
    clr
    rocthrust
    rocprim
    hipsparse
    hipblas
  ]));

  propagatedBuildInputs = [
    psutil
    ray
    pandas
    pyarrow
    sentencepiece
    numpy
    torch
    transformers
    xformers
    fastapi
    uvicorn
    pydantic
    aioprometheus
  ] ++ uvicorn.optional-dependencies.standard
    ++ aioprometheus.optional-dependencies.starlette;

  pythonImportsCheck = [ "vllm" ];

  meta = with lib; {
    description = "A high-throughput and memory-efficient inference and serving engine for LLMs";
    changelog = "https://github.com/vllm-project/vllm/releases/tag/v${version}";
    homepage = "https://github.com/vllm-project/vllm";
    license = licenses.asl20;
    maintainers = with maintainers; [ happysalada ];
    broken = !cudaSupport && !rocmSupport;
  };
}
