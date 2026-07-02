#!/bin/bash
# 把 patched ScummVM 打包成 AppImage (含繁中 CJK patch)。
# 產出: dist/SimonTheSorcerer-CHT-x86_64.AppImage
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
mkdir -p "$PROJ/dist"
docker run --rm -v "$PROJ:/w" -w /w simon-build bash -c '
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq wget file desktop-file-utils >/dev/null 2>&1

    APP=/tmp/AppDir
    rm -rf $APP; mkdir -p $APP/usr/bin $APP/usr/lib
    cp build/scummvm-src/scummvm $APP/usr/bin/scummvm

    # 帶入相依 .so (排除核心系統庫)
    ldd $APP/usr/bin/scummvm | awk "{print \$3}" | grep -E "^/" | while read lib; do
        case "$lib" in
            *ld-linux*|*libc.so*|*libm.so*|*libpthread*|*libdl.so*|*librt.so*|*libstdc++*|*libgcc_s*) ;;
            *) cp -L "$lib" $APP/usr/lib/ 2>/dev/null || true ;;
        esac
    done

    # 繁中資產(放進 AppDir 供參考; 實際需複製到遊戲目錄)
    mkdir -p $APP/usr/share/simon-cht
    cp fonts/simon_zh24.dcjk fonts/simon_zh.tab fonts/simon_voice.map $APP/usr/share/simon-cht/

    cat > $APP/AppRun <<"EOF"
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/scummvm" "$@"
EOF
    chmod +x $APP/AppRun

    cat > $APP/scummvm.desktop <<"EOF"
[Desktop Entry]
Type=Application
Name=Simon the Sorcerer CHT
Exec=scummvm
Icon=scummvm
Categories=Game;
EOF
    # 簡單圖示 (32x32 png)
    cp original_game_floppy/installed/ICON.DAT /dev/null 2>/dev/null || true
    convert -size 256x256 xc:navy -gravity center -pointsize 48 -fill white \
        -annotate 0 "Simon\nCHT" $APP/scummvm.png 2>/dev/null || \
        convert -size 256x256 xc:navy $APP/scummvm.png
    cp $APP/scummvm.png $APP/usr/share/ 2>/dev/null || true

    # appimagetool
    wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/ait || \
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /tmp/ait
    chmod +x /tmp/ait
    cd /tmp
    ARCH=x86_64 ./ait --appimage-extract-and-run /tmp/AppDir /w/dist/SimonTheSorcerer-CHT-x86_64.AppImage 2>&1 | tail -5
    chown -R '"$(id -u):$(id -g)"' /w/dist 2>/dev/null || true
'
echo "=== dist ==="
ls -lh "$PROJ/dist/" 2>/dev/null
