{pkgs ? import <nixpkgs> {}}:
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
    git-lfs
    git-repo
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
    ncurses5
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
    pkg-config
    meson
    cmake
    glslang
    python3Packages.pycparser
    binutils
    gcc
  ];

  shellHook = ''
    touch $HOME/.repo_.gitconfig.json # Needed for some myriad reason otherwise the build fails due to read-only access.

    # Use CCACHE.
    export USE_CCACHE=1
    export CCACHE_EXEC=${pkgs.ccache}/bin/ccache
    ccache -M 20G

    # Put cache artifacts in the output directory.
    export CCACHE_DIR="$PWD/out/repo-cache"
    mkdir -p "$CCACHE_DIR"
  '';
}
