#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_scene"
rm -f "$PROJ/screenshots_scene"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_scene:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm_scene.log &
    SVPID=$!
    sleep 6
    # 連按 ESC 跳過片頭過場 + 偶爾點滑鼠推進
    for i in $(seq 1 25); do
      xdotool key Escape 2>/dev/null || true
      xdotool mousemove 320 240 click 1 2>/dev/null || true
      sleep 1
    done
    sleep 2
    # 進到閣樓場景後: 懸停不同物件觸發動作句/物件名, 截圖
    px=(120 200 300 400 480 260 160 360 220 300)
    py=(120 100 140 110 130 90 150 120 100 130)
    for i in $(seq 0 9); do
      xdotool mousemove ${px[$i]} ${py[$i]} 2>/dev/null || true
      sleep 2
      import -window root /shots/scene_$(printf %02d $i).png 2>/dev/null || true
    done
    kill $SVPID 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
docker run --rm -v "$PROJ/screenshots_scene:/s" simon-build bash -c 'cd /s; montage scene_*.png -tile 5x2 -geometry 260x195+1+1 -background gray montage_scene.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_scene.png'
echo "done: $(ls "$PROJ/screenshots_scene"/scene_*.png 2>/dev/null | wc -l)"
