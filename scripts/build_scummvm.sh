#!/bin/bash
# Build ScummVM (AGOS only) in docker, keeping host clean.
# Usage: ./scripts/build_scummvm.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$PROJ_DIR/build/scummvm-src"

echo "=== Building ScummVM (AGOS engine) in docker ==="
docker run --rm \
    -v "$SRC:/src" \
    -w /src \
    ubuntu:24.04 \
    bash -c "
        set -e
        apt-get update -qq && apt-get install -y -qq \
            build-essential libsdl2-dev libsdl2-net-dev \
            libfreetype6-dev libpng-dev libjpeg-turbo8-dev \
            pkg-config zlib1g-dev nasm > /dev/null 2>&1
        echo '=== Configuring (AGOS only, minimal deps) ==='
        ./configure --disable-all-engines --enable-engine=agos --enable-release \
            --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
            --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl \
            2>&1 | tail -8
        echo '=== Building ==='
        make -j\$(nproc) 2>&1 | tail -15
        echo '=== chown to host ==='
        chown $(id -u):$(id -g) scummvm 2>/dev/null || true
        ls -lh scummvm
    "
echo "=== Build complete ==="
ls -lh "$SRC/scummvm" 2>/dev/null || echo "Binary not found"
