{ lib
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, fetchpatch
, which
# runtime dependencies
, numpy
, torch
# check dependencies
, pytestCheckHook
, pytest-cov
# , pytest-mpi
, pytest-timeout
# , pytorch-image-models
, hydra-core
, fairscale
, scipy
, cmake
, openai-triton
, networkx
#, apex
, einops
, transformers
, timm
, git
# , flash-attn
}:
let
  inherit (torch) cudaCapabilities cudaPackages cudaSupport rocmSupport;
  version = "0.0.23.post1";
in
buildPythonPackage {
  pname = "xformers";
  inherit version;
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "facebookresearch";
    repo = "xformers";
    rev = "refs/tags/v${version}";
    hash = "sha256-AJXow8MmX4GxtEE2jJJ/ZIBr+3i+uS4cA6vofb390rY=";
    fetchSubmodules = true;
  };

  patches = [
    ./0001-fix-allow-building-without-git.patch
  ];

  env = {
    # Version check is incompatible with removed git dependency, as
    # flash-attn submodule has wrong version specified in it.
    # only results in failure on
    XFORMERS_IGNORE_FLASH_VERSION_CHECK = "1";
  };

  postPatch = lib.optionalString rocmSupport ''
    patch -u xformers/ops/fmha/common.py -i ${fetchpatch {
      name = "commonpy-rocm";
      url = "https://raw.githubusercontent.com/vllm-project/vllm/f0d4e145575bf6fb96c141d776ce92c9bfc79c49/rocm_patch/commonpy_xformers-0.0.23.rocm.patch";
      hash = "sha256-2CM7S9fr/ch9c9Ww2DYgrSoC7o4iNfNkdS5CK1o+pJI=";
    }}
    patch -u xformers/ops/fmha/flash.py -i ${./flashpy.patch}
  '';

  preBuild = ''
    cat << EOF > ./xformers/version.py
    # noqa: C801
    __version__ = "${version}"
    EOF
  '' + lib.optionalString cudaSupport ''
    export CUDA_HOME=${cudaPackages.cuda_nvcc}
    export TORCH_CUDA_ARCH_LIST="${lib.concatStringsSep ";" cudaCapabilities}"
  '';

  buildInputs = lib.optionals cudaSupport (with cudaPackages; [
    # flash-attn build
    cuda_cudart # cuda_runtime_api.h
    libcusparse.dev # cusparse.h
    cuda_cccl.dev # nv/target
    libcublas.dev # cublas_v2.h
    libcusolver.dev # cusolverDn.h
    libcurand.dev # curand_kernel.h
  ]);

  nativeBuildInputs = [
    which
  ];

  propagatedBuildInputs = [
    numpy
    torch
  ];

  pythonImportsCheck = [ "xformers" ];

  dontUseCmakeConfigure = true;

  enableParallelBuilding = true;
  # see commented out missing packages
  doCheck = false;

  nativeCheckInputs = [
    pytestCheckHook
    pytest-cov
    pytest-timeout
    hydra-core
    fairscale
    scipy
    cmake
    networkx
    openai-triton
    # apex
    einops
    transformers
    timm
    # flash-attn
    # Checks flash-attn version, but fails as no .git found.
    # Should the check here allow for missing git?
    # https://github.com/facebookresearch/xformers/blob/e6e66958b29be6ed6428ab0664092e1733d4bdbc/setup.py#L71
    git
  ];

  meta = with lib; {
    description = "XFormers: A collection of composable Transformer building blocks";
    homepage = "https://github.com/facebookresearch/xformers";
    changelog = "https://github.com/facebookresearch/xformers/blob/${version}/CHANGELOG.md";
    license = licenses.bsd3;
    maintainers = with maintainers; [ happysalada ];
  };
}
