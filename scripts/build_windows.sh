#!/bin/bash
# Windows 版:mingw-w64 交叉編譯 patched ScummVM(AGOS)+ 收齊所有 DLL + 內含遊戲
# 產出: dist/win/  (scummvm.exe + *.dll + 遊戲 + 播放.bat)  →  可壓成 portable zip
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/dist/win"
docker run --rm -v "$PROJ:/w" -w /w debian:bookworm-slim bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++-mingw-w64-x86-64 mingw-w64-tools g++ make wget tar xz-utils \
      libz-mingw-w64-dev ca-certificates file >/dev/null 2>&1

  HOST=x86_64-w64-mingw32
  # SDL2 mingw devel
  cd /opt
  wget -q https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-devel-2.30.9-mingw.tar.gz
  tar xzf SDL2-devel-2.30.9-mingw.tar.gz
  SDLP=/opt/SDL2-2.30.9/$HOST
  export PATH="$SDLP/bin:$PATH"

  # 複製源碼(含 patch)到乾淨 win 建置樹,清掉 Linux .o
  rm -rf /win && cp -r /w/build/scummvm-src /win
  cd /win
  find . -name "*.o" -delete; find . -name "*.a" -delete; rm -f scummvm scummvm.exe config.mk config.log 2>/dev/null || true

  echo "=== configure (mingw, AGOS only) ==="
  ./configure --host=$HOST \
    --enable-engine=agos --disable-all-engines --enable-release \
    --with-sdl-prefix="$SDLP" \
    --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
    --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl --disable-timidity \
    2>&1 | tail -20
  echo "=== config.mk CXX/HOST ==="; grep -E "^CXX|^CC |HOST|BACKEND" config.mk | head

  echo "=== make ==="
  make -j$(nproc) 2>&1 | tail -8
  ls -lh scummvm.exe

  # 收齊 DLL
  OUT=/w/dist/win; mkdir -p $OUT
  cp scummvm.exe $OUT/
  cp "$SDLP/bin/SDL2.dll" $OUT/
  # mingw runtime + zlib
  GCCDIR=$(dirname $(x86_64-w64-mingw32-g++ -print-libgcc-file-name))
  for d in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    f=$(find /usr/lib/gcc/$HOST /usr/$HOST -name $d 2>/dev/null | head -1); [ -n "$f" ] && cp "$f" $OUT/
  done
  zdll=$(find /usr/$HOST -iname "zlib1.dll" -o -iname "libz-1.dll" 2>/dev/null | head -1); [ -n "$zdll" ] && cp "$zdll" $OUT/ || true
  # 用 objdump 驗證還缺哪些非系統 DLL
  echo "=== scummvm.exe 相依 DLL ==="
  x86_64-w64-mingw32-objdump -p scummvm.exe | grep "DLL Name" | sort -u
  echo "=== 已收 DLL ==="; ls $OUT/*.dll
  chown -R '"$(id -u):$(id -g)"' $OUT 2>/dev/null || true
'
echo "=== dist/win ==="; ls -lh "$PROJ/dist/win/" 2>/dev/null