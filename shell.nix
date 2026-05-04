{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    bash
    imagemagick
    bc
    bison
    ccache
    curl
    flex
    git
    gnupg
    elfutils
    lz4
    openssl
    libxml2
    lzop
    pngcrush
    rsync
    schedtool
    squashfsTools
    libarchive
    ncurses
    python3Packages.setuptools
    python3Packages.mako
    python3Packages.pyyaml
    gperf
    gnumake
    SDL
    libxslt
    zlib
    unzip
    zip
    meson
    pkg-config
    glslang
    python3Packages.pycparser
    binutils
    gcc
    git-repo
  ];

  shellHook = ''
    export USE_CCACHE=1
    export CCACHE_EXEC=${pkgs.ccache}/bin/ccache
    ccache -M 20G

    # Limit Go/Soong memory use; adjust if needed.
    export GOMEMLIMIT=24GiB
    export GOGC=50
  '';
}
