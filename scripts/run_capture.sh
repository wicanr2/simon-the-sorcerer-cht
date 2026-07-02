#!/bin/bash
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/screenshots"
docker run --rm -v "$PROJ/build/scummvm-src/scummvm:/scummvm:ro" \
  -v "$PROJ/run_floppy:/game" -v "$PROJ/screenshots:/shots" \
  simon-build bash -c '
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 640x480x16 >/dev/null 2>&1 &
    sleep 2
    cd /game
    /scummvm -p /game --auto-detect 2>/game/scummvm.log &
    SVPID=$!
    for i in $(seq 1 14); do
      sleep 3
      import -window root /shots/shot_$(printf %02d $i).png 2>/dev/null || true
    done
    kill $SVPID 2>/dev/null || true
    grep -iE "CHT|fusion|error" /game/scummvm.log | head -15 || true
    cp /game/scummvm.log /shots/scummvm.log 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /shots 2>/dev/null || true
  '
