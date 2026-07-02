#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_gp"
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_gp:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm.log &
    SVPID=$!
    # 過片頭: 前 50 秒每 3 秒點一下滑鼠(跳過過場)
    for i in $(seq 1 18); do sleep 3; xdotool mousemove 320 300 click 1 2>/dev/null || true; done
    # 進場景後: 移到不同位置觸發動詞列/物件名, 截圖
    for i in $(seq 1 10); do
      xdotool mousemove $((100+i*40)) $((120+i*15)) 2>/dev/null || true
      sleep 2
      import -window root /shots/gp_$(printf %02d $i).png 2>/dev/null || true
    done
    kill $SVPID 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
docker run --rm -v "$PROJ/screenshots_gp:/s" simon-build bash -c 'cd /s; montage gp_*.png -tile 5x2 -geometry 200x150+1+1 -background gray montage_gp.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_gp.png'
