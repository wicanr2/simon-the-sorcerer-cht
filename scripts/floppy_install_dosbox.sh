#!/bin/bash
# DOSBox 安裝完整 floppy(目錄熱抽換法):
# A: 掛一個可寫目錄, 先放 disk01 檔; 監看 /out VGA 數, 停滯就把 A: 內容換成下一片
# (含該片 DISK.ID), 讓安裝程式通過換片驗證, 直到三片都解完。
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
DISKS="$PROJ/original_game_floppy/disks_extracted"
rm -rf "$PROJ/floppy_install/out"; mkdir -p "$PROJ/floppy_install/out"
docker run --rm \
  -v "$DISKS:/disks:ro" \
  -v "$PROJ/floppy_install/out:/out" \
  simon-build bash -c '
    set -e
    export DISPLAY=:99 SDL_AUDIODRIVER=dummy
    Xvfb :99 -screen 0 1024x768x16 >/dev/null 2>&1 &
    sleep 2
    mkdir -p /floppy
    cp /disks/disk01/* /floppy/
    cat > /conf.conf <<EOF
[cpu]
cycles=60000
[autoexec]
mount c /out
mount a /floppy -t floppy
a:
INSTALL.EXE
EOF
    dosbox -conf /conf.conf >/dosbox.log 2>&1 &
    DBPID=$!
    sleep 6
    for i in $(seq 1 6); do xdotool key --clearmodifiers Return; sleep 1; done

    disk=1; stall=0; last=0
    for i in $(seq 1 60); do
        xdotool key --clearmodifiers Return; sleep 1
        cnt=$(ls /out/SIMON/*.VGA 2>/dev/null | wc -l)
        if [ "$cnt" -eq "$last" ]; then stall=$((stall+1)); else stall=0; last=$cnt; fi
        echo "  iter $i: VGA=$cnt disk=$disk stall=$stall"
        # 停滯 5 次且還有下一片 → 換片
        if [ "$stall" -ge 5 ] && [ "$disk" -lt 3 ]; then
            disk=$((disk+1))
            echo "  >>> 換到 disk0$disk"
            rm -f /floppy/*
            cp /disks/disk0$disk/* /floppy/
            stall=0
            xdotool key --clearmodifiers Return; sleep 1
        fi
        # 三片都解且穩定 → 結束
        if [ "$disk" -eq 3 ] && [ "$stall" -ge 6 ]; then break; fi
    done
    sleep 2
    kill $DBPID 2>/dev/null || true
    sleep 1
    echo "=== 最終 VGA 數: $(ls /out/SIMON/*.VGA 2>/dev/null | wc -l) ==="
    cp /dosbox.log /out/dosbox.log 2>/dev/null || true
    chown -R '"$(id -u):$(id -g)"' /out 2>/dev/null || true
  '
echo "=== host out ==="
ls "$PROJ/floppy_install/out/SIMON/"*.VGA 2>/dev/null | xargs -n1 basename 2>/dev/null | cut -c1-2 | sort -u | tr '\n' ' '; echo
echo "total VGA: $(ls "$PROJ/floppy_install/out/SIMON/"*.VGA 2>/dev/null | wc -l)"
