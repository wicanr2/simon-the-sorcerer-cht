#!/bin/bash
# 增量重編 + 對 floppy 與 CD 各跑一次 script dump(用引擎內建反組譯器)
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
SRC="$PROJ/build/scummvm-src"
FLOPPY="$PROJ/original_game_floppy/installed"
CD="/home/anr2/scummvm/simon-1/original_game/extracted"
mkdir -p "$PROJ/strings/dumps"

docker run --rm \
  -v "$SRC:/src" \
  -v "$FLOPPY:/floppy:ro" \
  -v "$CD:/cd:ro" \
  -v "$PROJ/strings/dumps:/out" \
  -w /src ubuntu:24.04 bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq build-essential libsdl2-dev libsdl2-net-dev \
        libfreetype6-dev libpng-dev libjpeg-turbo8-dev pkg-config zlib1g-dev nasm >/dev/null 2>&1
    echo "=== incremental make ==="
    make -j$(nproc) 2>&1 | tail -5
    export SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy

    run_dump () {
        local name=$1 dir=$2
        # 工作目錄放到 game dir 以便 flag 檔被偵測
        cp /src/scummvm /tmp/scummvm
        mkdir -p /work_$name
        # 建立可寫 game dir 副本(symlink 遊戲檔 + 放 flag)
        cd /work_$name
        for f in $dir/*; do ln -sf "$f" . 2>/dev/null || true; done
        touch dump_scripts_flag
        echo ">>> dumping $name ..."
        /tmp/scummvm -p /work_$name --auto-detect 2>/dev/null > /out/$name.dump || true
        echo "  $name lines: $(wc -l < /out/$name.dump)"
        cd /src
    }
    run_dump floppy /floppy
    run_dump cd /cd
    chown -R '"$(id -u):$(id -g)"' /out 2>/dev/null || true
  '
echo "=== 結果 ==="
for f in floppy cd; do echo "$f.dump:" $(wc -l < "$PROJ/strings/dumps/$f.dump" 2>/dev/null); done
