{ lib
, buildPythonPackage
, fetchFromGitHub
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
, torch-bin
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
    rev = "v${version}";
    hash = "sha256-JN+Z1rPJkCLanegJm85Ggw4/2Mq4VkCVtV+UeeDoKuQ=";
  };

  # Adding ROCM's LLVM to PATH breaks everything.
  # amdgpu-offload-arch returns rocm arch. vllm still won't work on arch mismatch, but offload-arch script wants
  # too many new sandbox paths.
  # HIP version format is broken with raw hipcc call, as it wants some packages in /opt/rocm.
  postPatch = lib.optionalString rocmSupport ''
    substituteInPlace setup.py \
      --replace "/opt/rocm/llvm/bin/amdgpu-offload-arch" "${writeShellScript "gpu-arch-hardcode" "echo gfx1100"}"
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
    cuda_cudart.dev # cuda_runtime.h
    cuda_cccl.dev # <thrust/*>
    libcusparse.dev # cusparse.h
    libcublas.dev # cublas_v2.h
    libcusolver # cusolverDn.h
  ])) ++ (lib.optionals rocmSupport (with rocmPackages; [
    clr
    rocthrust
    rocprim
  ]));

  propagatedBuildInputs = [
    psutil
    ray
    pandas
    pyarrow
    sentencepiece
    numpy
    torch-bin
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
