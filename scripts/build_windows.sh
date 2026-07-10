#!/bin/bash
# Windows 版:mingw-w64 交叉編譯 patched ScummVM(AGOS)+ 收齊所有 DLL + 內含遊戲
# 產出: dist-all/SimonTheSorcerer-CHT-FULL-win64.zip(scummvm.exe + DLL + data + 遊戲 + 播放.bat)
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/dist/win"
docker run --rm -v "$PROJ:/w" -w /w debian:bookworm-slim bash -c '
  set -e
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq g++-mingw-w64-x86-64 mingw-w64-tools g++ make wget tar xz-utils zip \
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

  # 收齊 DLL(輸出成 dist-all 內的 portable 目錄, 最後壓成 zip)
  STAGE=/w/dist-all/SimonTheSorcerer-CHT-win64; rm -rf $STAGE; OUT=$STAGE; mkdir -p $OUT
  cp scummvm.exe $OUT/
  cp "$SDLP/bin/SDL2.dll" $OUT/
  # mingw runtime + zlib
  GCCDIR=$(dirname $(x86_64-w64-mingw32-g++ -print-libgcc-file-name))
  for d in libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll; do
    f=$(find /usr/lib/gcc/$HOST /usr/$HOST -name $d 2>/dev/null | head -1); [ -n "$f" ] && cp "$f" $OUT/
  done
  zdll=$(find /usr/$HOST -iname "zlib1.dll" -o -iname "libz-1.dll" 2>/dev/null | head -1); [ -n "$zdll" ] && cp "$zdll" $OUT/ || true
  # ScummVM 執行期資料檔(GUI 主題/字型/翻譯)—— 缺了會 "Could not find theme / font" 起不來(issue #1)
  # AGOS 不需 engine-data,只帶 GUI 主題 + 字型(含 CJK,支援中文 GUI)
  mkdir -p $OUT/data
  cp gui/themes/scummmodern.zip gui/themes/scummclassic.zip gui/themes/scummremastered.zip \
     gui/themes/gui-icons.dat gui/themes/shaders.dat gui/themes/translations.dat \
     dists/engine-data/fonts.dat dists/engine-data/fonts-cjk.dat $OUT/data/
  echo "=== ScummVM 資料檔 ==="; ls -lh $OUT/data/ | awk "{print \$5,\$NF}"
  # 播放遊戲.bat(自動建 saves + 指定 GUI 主題/字型資料路徑)
  printf "@echo off\r\ncd /d \"%%~dp0\"\r\nif not exist saves mkdir saves\r\nscummvm.exe -p game --themepath=data --extrapath=data --auto-detect --savepath=saves\r\npause\r\n" > "$OUT/播放遊戲.bat"
  # 用 objdump 驗證還缺哪些非系統 DLL
  echo "=== scummvm.exe 相依 DLL ==="
  x86_64-w64-mingw32-objdump -p scummvm.exe | grep "DLL Name" | sort -u
  echo "=== 已收 DLL ==="; ls $OUT/*.dll
  # 內含完整遊戲(含 CHT 資產 + 語音)+ 空 saves
  mkdir -p $OUT/game $OUT/saves
  cp -rL /w/run_floppy/* $OUT/game/
  # 壓成 portable zip 放 dist-all, 再刪 staging 目錄(省空間)
  cd /w/dist-all
  rm -f SimonTheSorcerer-CHT-FULL-win64.zip
  ( cd /w/dist-all && zip -rq SimonTheSorcerer-CHT-FULL-win64.zip SimonTheSorcerer-CHT-win64 )
  rm -rf $STAGE
  echo "=== 產出 ==="; ls -lh /w/dist-all/SimonTheSorcerer-CHT-FULL-win64.zip
  chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
'
echo "=== dist/win ==="; ls -lh "$PROJ/dist/win/" 2>/dev/null