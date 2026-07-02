#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
docker run --rm -v "$PROJ:/work" -w /work ubuntu:24.04 bash -c '
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq python3 python3-pip fonts-noto-cjk python3-freetype >/dev/null 2>&1
  FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
  [ -f "$FONT" ] || FONT=$(find /usr/share/fonts -iname "*NotoSansCJK*" | head -1)
  echo "font: $FONT"
  python3 tools/build_cjk_font.py --size 24 --font "$FONT" --out fonts/simon_zh24.dcjk
  chown '"$(id -u):$(id -g)"' fonts/simon_zh24.dcjk 2>/dev/null || true
'
