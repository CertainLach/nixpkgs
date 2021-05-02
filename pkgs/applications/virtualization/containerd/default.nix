{ lib
, fetchFromGitHub
, buildGoModule
, btrfs-progs
, go-md2man
, installShellFiles
, util-linux
, nixosTests
}:

buildGoModule rec {
  pname = "containerd";
  version = "1.5.0-rc.2";

  src = fetchFromGitHub {
    owner = "containerd";
    repo = "containerd";
    rev = "v${version}";
    sha256 = "sha256-zg1/cOnOPCQcYSazEZK1PE861gg3Gq54v0dIY/PPk70=";
  };

  vendorSha256 = null;

  outputs = [ "out" ];

  nativeBuildInputs = [ go-md2man installShellFiles util-linux ];

  buildInputs = [ btrfs-progs ];

  subPackages = [
    "cmd/containerd-shim-runc-v1"
    "cmd/containerd-shim-runc-v2"
    "cmd/containerd-shim"
    "cmd/containerd"
    "cmd/ctr"
  ];

  BUILDTAGS = [ ]
    ++ lib.optional (btrfs-progs == null) "no_btrfs";

  postInstall = ''
    installManPage man/*.[1-9]
    installShellCompletion --bash contrib/autocomplete/ctr
    installShellCompletion --zsh --name _ctr contrib/autocomplete/zsh_autocomplete
  '';

  passthru.tests = { inherit (nixosTests) docker; };

  meta = with lib; {
    homepage = "https://containerd.io/";
    description = "A daemon to control runC";
    license = licenses.asl20;
    maintainers = with maintainers; [ offline vdemeester ];
    platforms = platforms.linux;
  };
}
