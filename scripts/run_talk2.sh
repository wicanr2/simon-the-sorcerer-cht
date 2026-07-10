#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_talk2"; rm -f "$PROJ/screenshots_talk2"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_talk2:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm_talk2.log &
    SVPID=$!
    sleep 6
    for i in $(seq 1 25); do xdotool key Escape 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true; sleep 1; done
    sleep 2
    n=0
    # 查看不同物件, 每次點完高頻連拍(每0.4s)抓講話字幕
    for obj in "180 120" "300 110" "470 130" "240 150" "150 100" "400 200"; do
      xdotool mousemove 146 306 click 1 2>/dev/null||true; sleep 0.8   # 選查看
      xdotool mousemove $obj click 1 2>/dev/null||true                 # 點物件
      for k in $(seq 1 10); do
        import -window root /shots/t_$(printf %03d $n).png 2>/dev/null||true; n=$((n+1))
        sleep 0.4
      done
    done
    kill $SVPID 2>/dev/null||true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null||true
  '
docker run --rm -v "$PROJ/screenshots_talk2:/s" simon-build bash -c 'cd /s; montage t_*.png -tile 10x6 -geometry 160x120+1+1 -background gray montage_t2.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_t2.png' 2>/dev/null||true
echo "done: $(ls "$PROJ/screenshots_talk2"/t_*.png 2>/dev/null|wc -l)"
