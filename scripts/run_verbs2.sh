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
    # 快速左鍵狂點跳過片頭對白 (~100s)
    for i in $(seq 1 100); do xdotool mousemove 320 250 click 1 2>/dev/null || true; sleep 1;
      if [ $((i % 12)) -eq 0 ]; then import -window root /shots/vb_$(printf %03d $i).png 2>/dev/null || true; fi
    done
    # 最後移滑鼠掃場景觸發動詞列
    for i in $(seq 1 6); do xdotool mousemove $((90+i*60)) $((100+i*10)) 2>/dev/null; sleep 2; import -window root /shots/vg_$(printf %02d $i).png 2>/dev/null || true; done
    kill $SVPID 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
docker run --rm -v "$PROJ/screenshots_vb:/s" simon-build bash -c 'cd /s; montage vb_*.png vg_*.png -tile 4x4 -geometry 200x150+1+1 -background gray montage_vb.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_vb.png'
