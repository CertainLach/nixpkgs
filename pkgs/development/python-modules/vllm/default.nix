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
  version = "0.2.6";
in
buildPythonPackage {
  pname = "vllm";
  inherit version;
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "vllm-project";
    repo = "vllm";
    rev = "2832e7b9f92e2d1dd7dfe37951e5837c61d3db20";
    sha256 = "sha256-br9NUm+E7fa70GvhkkBCstdnqU3VUWyDnPHrmYjASFk=";
  };

  # Otherwise it will be built for targets supported by torch, which then wants to
  GPU_ARCHS = lib.optionalString rocmSupport (lib.strings.concatStringsSep ";" (
    if gpuTargets != [ ] then
      gpuTargets
    else
      # vllm supports less gpu targets than rocm clr, supported target list is taken from ROCM_SUPPORTED_ARCHS in setup.py
      lib.lists.intersectLists rocmPackages.clr.gpuTargets ["gfx90a" "gfx908" "gfx906" "gfx1030" "gfx1100"]
  ));

  patches = [
    # https://github.com/vllm-project/vllm/pull/2581
    # Without this patch, vllm tries to to use amdgpu-offload-arch script, which then tries to read some
    # out-of-the-sandbox path to deduce supported GPU target.
    (fetchpatch {
      name = "allow-specifying-hip-targets";
      url = "https://github.com/vllm-project/vllm/pull/2581/commits/0a1bf609bd8f6a7c40557923944c2892b5fbdf18.patch";
      hash = "sha256-zOeDlV/4nfKAmtzs6n1nfHw5pgkx7JEx0yuiin28n48=";
    })
    (fetchpatch {
      name = "build-only-specific-hip-targets";
      url = "https://github.com/vllm-project/vllm/pull/2581/commits/c21d71f144de18f2abbd5cb5598e104a6a499abf.patch";
      hash = "sha256-CYHnVF6v2EDdon8WeHTRn7OXXVz7SygyI5KSwHM9TrU=";
    })
  ];

  # hipcc --version works badly on NixOS due to unresolved paths.
  postPatch = lib.optionalString rocmSupport ''
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
