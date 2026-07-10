#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots_talk3"; rm -f "$PROJ/screenshots_talk3"/*.png
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots_talk3:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm_talk3.log &
    SVPID=$!
    sleep 6
    for i in $(seq 1 25); do xdotool key Escape 2>/dev/null||true; xdotool mousemove 320 240 click 1 2>/dev/null||true; sleep 1; done
    sleep 2
    # 查看框(box102)螢幕座標 (146,367);場景物件在上半(y<330)
    LOOK="146 367"
    objs=("200 156" "300 120" "460 150" "240 190" "150 130" "400 170" "330 220")
    n=0
    for o in "${objs[@]}"; do
      xdotool mousemove $LOOK click 1 2>/dev/null||true; sleep 0.8   # 選查看
      xdotool mousemove $o click 1 2>/dev/null||true                 # 查看該物件 → 西蒙講話
      for k in $(seq 1 12); do
        import -window root /shots/t_$(printf %03d $n).png 2>/dev/null||true; n=$((n+1)); sleep 0.4
      done
    done
    kill $SVPID 2>/dev/null||true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null||true
  '
docker run --rm -v "$PROJ/screenshots_talk3:/s" simon-build bash -c 'cd /s; montage t_*.png -tile 12x7 -geometry 140x105+1+1 -background gray montage_t3.png 2>/dev/null; chown '$(id -u):$(id -u)' montage_t3.png' 2>/dev/null||true
echo "done: $(ls "$PROJ/screenshots_talk3"/t_*.png 2>/dev/null|wc -l)"
