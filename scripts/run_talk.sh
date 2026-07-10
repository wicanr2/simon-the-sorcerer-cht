#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_talk"; rm -f "$PROJ/screenshots_talk"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_talk:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm_talk.log &
    SVPID=$!
    sleep 6
    # 跳過片頭過場進場景
    for i in $(seq 1 25); do xdotool key Escape 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true; sleep 1; done
    sleep 2
    # 進場景後: 點「查看」動詞(box102, 640 螢幕約 146,306)再點場景物件 → 西蒙講話(字幕壓在房間上)
    # 場景物件點(640 螢幕座標, 上半場景區 y<300)
    objs=("200 180" "400 150" "300 130" "500 200" "120 190" "260 160" "440 210" "180 140")
    n=0
    for o in "${objs[@]}"; do
      xdotool mousemove 146 306 click 1 2>/dev/null||true   # 選「查看」
      sleep 1
      xdotool mousemove $o click 1 2>/dev/null||true        # 點物件 → 講話
      # 講話期間連續截幾張抓字幕出現的時刻
      for k in 1 2 3 4; do sleep 1; import -window root /shots/talk_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1)); done
    done
    kill $SVPID 2>/dev/null||true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null||true
  '
docker run --rm -v "$PROJ/screenshots_talk:/s" simon-build bash -c 'cd /s; montage talk_*.png -tile 8x4 -geometry 200x150+1+1 -background gray montage_talk.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_talk.png' 2>/dev/null||true
echo "done: $(ls "$PROJ/screenshots_talk"/talk_*.png 2>/dev/null|wc -l)"
