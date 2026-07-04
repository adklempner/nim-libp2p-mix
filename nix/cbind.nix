# Mirrors nim-libp2p's nix/cbind.nix (at c431993), adapted for the
# out-of-tree mix cbind: compiles cbind/cbind.nim (the cbind main module) against the libp2p_mix
# package (src root) plus the pinned nim-libp2p from deps.nix.
{ pkgs, src }:

let
  deps = import ./deps.nix { inherit pkgs; };
  cbindDeps = import ./cbind-deps.nix { inherit pkgs; };

  pathArgs =
    builtins.concatStringsSep " "
      (map (p: "--path:${p}") (builtins.attrValues (deps // cbindDeps)));

  libExt =
    if pkgs.stdenv.hostPlatform.isWindows then "dll"
    else if pkgs.stdenv.hostPlatform.isDarwin then "dylib"
    else "so";
in
pkgs.stdenv.mkDerivation {
  pname = "nim-libp2p-mix-cbind";
  version = "dev";

  inherit src;

  nativeBuildInputs = [
    pkgs.nim-2_2
    pkgs.git
    pkgs.nimble
  ];

  buildPhase = ''
    export HOME=$TMPDIR
    export XDG_CACHE_HOME=$TMPDIR/.cache
    export NIMBLE_DIR=$TMPDIR/.nimble
    export NIMCACHE=$TMPDIR/nimcache

    mkdir -p build $NIMCACHE

    common_args="--noNimblePath \
      ${pathArgs} \
      --path:${deps.dnsclient}/src \
      --path:. \
      --threads:on \
      --opt:size \
      --noMain \
      --mm:refc \
      --header \
      --undef:metrics \
      --nimMainPrefix:libp2p \
      --nimcache:$NIMCACHE"

    echo "== Building C bindings (dynamic/shared) =="
    nim c $common_args \
      --out:build/libp2p.${libExt} \
      --app:lib \
      cbind/cbind.nim

    echo "== Building C bindings (static) =="
    nim c $common_args \
      --out:build/libp2p.a \
      --app:staticlib \
      cbind/cbind.nim
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp build/libp2p.${libExt} $out/lib
    cp build/libp2p.a         $out/lib
    cp cbind/libp2p.h         $out/include
  '';
}
