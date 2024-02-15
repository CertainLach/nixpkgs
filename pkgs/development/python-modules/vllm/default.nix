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
, pynvml
, cupy
, writeShellScript

, config

, cudaSupport ? config.cudaSupport
, cudaPackages ? {}

, rocmSupport ? config.rocmSupport
, rocmPackages ? {}
, gpuTargets ? []
}:

let
  version = "0.4.0";
in
buildPythonPackage {
  pname = "vllm";
  inherit version;
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    rev = "4f2ad1113553211778640c648e11f5aa2e03dbd4";
    hash = "sha256-JIoAO6WNDgAGO2Awe/kJV13wtNoFdXCFobxWShmqwQo=";
  };

  # Otherwise it will be built for targets supported by torch, which then wants to
  PYTORCH_ROCM_ARCH = lib.optionalString rocmSupport (lib.strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
      gpuTargets
    else
      # vllm supports less gpu targets than rocm clr, supported target list is taken from ROCM_SUPPORTED_ARCHS in setup.py
      lib.lists.intersectLists rocmPackages.clr.gpuTargets ["gfx90a" "gfx908" "gfx906" "gfx1030" "gfx1100"]
  ));

  # xformers 0.0.23.post1 github release specifies its version as 0.0.24
  #
  # cupy-cuda12x is the same wheel as cupy, but built with cuda dependencies, we already have it set up
  # like that in nixpkgs. Version upgrade is due to upstream shenanigans
  # https://github.com/vllm-project/vllm/pull/2845/commits/34a0ad7f9bb7880c0daa2992d700df3e01e91363
  #
  # hipcc --version works badly on NixOS due to unresolved paths.
  postPatch = ''
    substituteInPlace requirements.txt \
      --replace "xformers == 0.0.23.post1" "xformers == 0.0.24"
    substituteInPlace requirements.txt \
      --replace "cupy-cuda12x == 12.1.0" "cupy == 12.3.0"
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
    ++ aioprometheus.optional-dependencies.starlette
    ++ lib.optionals cudaSupport [
      pynvml
      cupy
    ];

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
