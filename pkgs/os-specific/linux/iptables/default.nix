{ lib, stdenv, fetchgit
, autoreconfHook, pkg-config, pruneLibtoolFiles, flex, bison
, libmnl, libnetfilter_conntrack, libnfnetlink, libnftnl, libpcap
, nftablesCompat ? true
, gitUpdater
}:

stdenv.mkDerivation rec {
  version = "1.8.11";
  pname = "iptables";

  src = fetchgit {
    url = "https://git.netfilter.org/iptables";
    rev = "075e4de85b96ad905c2113d580290963a7872e67";
    hash = "sha256-o7iEBiTAFm2VECq5Zt1hI+rJQ39MtVSlrZ93lItSKRw=";
  };

  outputs = [ "out" "dev" "man" ];

  nativeBuildInputs = [
    autoreconfHook pkg-config pruneLibtoolFiles flex bison
  ];

  buildInputs = [ libmnl libnetfilter_conntrack libnfnetlink libnftnl libpcap ];

  configureFlags = [
    "--enable-bpf-compiler"
    "--enable-devel"
    "--enable-libipq"
    "--enable-nfsynproxy"
    "--enable-shared"
  ] ++ lib.optional (!nftablesCompat) "--disable-nftables";

  enableParallelBuilding = true;

  postInstall = lib.optionalString nftablesCompat ''
    rm $out/sbin/{iptables,iptables-restore,iptables-save,ip6tables,ip6tables-restore,ip6tables-save}
    ln -sv xtables-nft-multi $out/bin/iptables
    ln -sv xtables-nft-multi $out/bin/iptables-restore
    ln -sv xtables-nft-multi $out/bin/iptables-save
    ln -sv xtables-nft-multi $out/bin/ip6tables
    ln -sv xtables-nft-multi $out/bin/ip6tables-restore
    ln -sv xtables-nft-multi $out/bin/ip6tables-save
  '';

  passthru = {
    updateScript = gitUpdater {
      url = "https://git.netfilter.org/iptables";
      rev-prefix = "v";
    };
  };

  meta = with lib; {
    description = "A program to configure the Linux IP packet filtering ruleset";
    homepage = "https://www.netfilter.org/projects/iptables/index.html";
    platforms = platforms.linux;
    maintainers = with maintainers; [ fpletz ];
    license = licenses.gpl2;
    downloadPage = "https://www.netfilter.org/projects/iptables/files/";
  };
}
