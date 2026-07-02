#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_vb"; rm -f "$PROJ/screenshots_vb"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_vb:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm.log &
    SVPID=$!
    sleep 4
    # 連續按 ESC 跳過片頭過場
    for i in $(seq 1 30); do xdotool key --clearmodifiers Escape 2>/dev/null || true; sleep 1; done
    # 應已進遊戲: 移滑鼠到場景各物件, 底部動詞列常駐
    for i in $(seq 1 8); do
      xdotool mousemove $((80+i*55)) $((110+i*8)) 2>/dev/null || true
      sleep 2
      import -window root /shots/vb_$(printf %02d $i).png 2>/dev/null || true
    done
    kill $SVPID 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
docker run --rm -v "$PROJ/screenshots_vb:/s" simon-build bash -c 'cd /s; montage vb_*.png -tile 4x2 -geometry 220x165+1+1 -background gray montage_vb.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_vb.png'
