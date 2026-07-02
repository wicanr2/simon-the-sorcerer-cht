#!/bin/bash
# 啟動繁中融合版魔法師西蒙 (需 X 顯示 + SDL2)。
# 遊戲目錄 run_floppy/ 已含: floppy 遊戲檔 + CD SIMON.VOC(語音) + CHT 資產。
# 遊戲中按 F8 切換中/英文字幕(語音維持英語)。
set -e
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$PROJ/build/scummvm-src/scummvm"
GAME="$PROJ/run_floppy"
if command -v scummvm-deps-ok >/dev/null 2>&1 || ldd "$BIN" >/dev/null 2>&1; then
  exec "$BIN" -p "$GAME" --auto-detect
else
  echo "本機缺 SDL2 等函式庫,改用 docker(需 X11 轉發):"
  echo "  xhost +local:docker"
  echo "  docker run --rm -e DISPLAY=\$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix \\"
  echo "    -v $BIN:/scummvm:ro -v $GAME:/game simon-build /scummvm -p /game --auto-detect"
fi
