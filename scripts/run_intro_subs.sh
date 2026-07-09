#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_sub"
rm -f "$PROJ/screenshots_sub"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_sub:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm_sub.log &
    SVPID=$!
    sleep 8
    # 點一下進入片頭旁白, 之後不再干擾, 持續截圖抓字幕
    xdotool mousemove 320 240 click 1 2>/dev/null || true
    for i in $(seq 1 40); do
      sleep 2
      import -window root /shots/sub_$(printf %02d $i).png 2>/dev/null || true
    done
    kill $SVPID 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
echo "done: $(ls "$PROJ/screenshots_sub"/*.png 2>/dev/null | wc -l) shots"
