#!/bin/bash
# 本機組 macOS 完整版 → dist-all/。
# CI(build-mac)產的是 engine-only universal .app;本機注入遊戲資料(run_floppy)後才是完整版。
# 用法:
#   gh run download <run-id> -n SimonScummVM-CHT-mac -D dist-all/.mac-artifact
#   ./scripts/pack_mac_full.sh
set -e
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
ART="$PROJ/dist-all/.mac-artifact"
APP="$ART/SimonScummVM-CHT.app"
[ -f "$ART/SimonScummVM-CHT-mac.tar.gz" ] && tar xzf "$ART/SimonScummVM-CHT-mac.tar.gz" -C "$ART"
[ -d "$APP" ] || { echo "!! 找不到 $APP —— 先 gh run download 到 dist-all/.mac-artifact"; exit 1; }

# 注入遊戲資料(含 CHT 資產 + SIMON.VOC)
mkdir -p "$APP/Contents/Resources/game"
cp -rL "$PROJ/run_floppy/"* "$APP/Contents/Resources/game/"

# 若 CI .app 沒帶 ScummVM 資料檔(舊版 CI),從 build/scummvm-src 補(需先跑 bootstrap_scummvm.sh)
if [ ! -f "$APP/Contents/Resources/scummvm-data/fonts-cjk.dat" ]; then
  echo "(CI .app 缺 scummvm-data,從 build/scummvm-src 補)"
  SRC="$PROJ/build/scummvm-src"
  mkdir -p "$APP/Contents/Resources/scummvm-data"
  cp "$SRC/gui/themes/"{scummmodern,scummclassic,scummremastered}.zip \
     "$SRC/gui/themes/"{gui-icons,shaders,translations}.dat \
     "$SRC/dists/engine-data/"{fonts,fonts-cjk}.dat \
     "$APP/Contents/Resources/scummvm-data/"
fi

tar czf "$PROJ/dist-all/SimonScummVM-CHT-FULL-mac.tar.gz" -C "$ART" SimonScummVM-CHT.app
rm -rf "$ART"
echo "=== 產出 ==="; ls -lh "$PROJ/dist-all/SimonScummVM-CHT-FULL-mac.tar.gz"
