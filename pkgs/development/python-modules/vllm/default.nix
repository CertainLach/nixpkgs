{ lib
, buildPythonPackage
, fetchFromGitHub
, cudaPackages
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
, config
, cudaSupport ? config.cudaSupport
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

  preBuild = lib.optionalString cudaSupport ''
    export CUDA_HOME=${cudaPackages.cuda_nvcc}
  '';

  nativeBuildInputs = [
    ninja
    packaging
    setuptools
    torch
    wheel
    which
  ];

  buildInputs = lib.optionals cudaSupport (with cudaPackages; [
    cuda_cudart.dev # cuda_runtime.h
    cuda_cccl.dev # <thrust/*>
    libcusparse.dev # cusparse.h
    libcublas.dev # cublas_v2.h
    libcusolver # cusolverDn.h
  ]);

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
    broken = !cudaSupport;
  };
}
