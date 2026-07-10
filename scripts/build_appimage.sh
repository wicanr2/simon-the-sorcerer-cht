#!/bin/bash
# 完整版 AppImage:patched ScummVM + 內含遊戲(floppy 資料 + CD SIMON.VOC + CHT 資產)
# 雙擊直接進《神通妙巫師》繁中融合版。
# 產出: dist-all/SimonTheSorcerer-CHT-FULL-x86_64.AppImage(私用完整版,含版權資料,不入 git)
set -e
PROJ="/home/anr2/scummvm/simon-1-cht-claude"
GAME="$PROJ/run_floppy"          # 含 floppy 遊戲檔 + SIMON.VOC + simon_zh24.dcjk/simon_zh.tab/simon_voice.map
mkdir -p "$PROJ/dist-all"
[ -f "$GAME/GAMEPC" ] || { echo "!! run_floppy 缺遊戲檔"; exit 1; }
[ -f "$GAME/SIMON.VOC" ] || echo "!! 警告: 無 SIMON.VOC(語音會關閉)"

docker run --rm -v "$PROJ:/w" -w /w game-video bash -c '
    set -e
    APP=/tmp/AppDir
    rm -rf $APP; mkdir -p $APP/usr/bin $APP/usr/lib $APP/usr/share/simon-game
    cp build/scummvm-src/scummvm $APP/usr/bin/scummvm

    # 相依 .so(排除核心系統庫)
    ldd $APP/usr/bin/scummvm | awk "{print \$3}" | grep -E "^/" | while read lib; do
        case "$lib" in
            *ld-linux*|*libc.so*|*libm.so*|*libpthread*|*libdl.so*|*librt.so*|*libstdc++*|*libgcc_s*) ;;
            *) cp -L "$lib" $APP/usr/lib/ 2>/dev/null || true ;;
        esac
    done

    # 內含完整遊戲(含 CHT 資產 + 語音)
    cp -rL run_floppy/* $APP/usr/share/simon-game/

    # ScummVM 執行期資料檔(GUI 主題/字型/翻譯)—— 缺了會 "Could not find theme / font" 亂掉(issue #1/#2)
    mkdir -p $APP/usr/share/scummvm
    cp build/scummvm-src/gui/themes/scummmodern.zip build/scummvm-src/gui/themes/scummclassic.zip \
       build/scummvm-src/gui/themes/scummremastered.zip build/scummvm-src/gui/themes/gui-icons.dat \
       build/scummvm-src/gui/themes/shaders.dat build/scummvm-src/gui/themes/translations.dat \
       build/scummvm-src/dists/engine-data/fonts.dat build/scummvm-src/dists/engine-data/fonts-cjk.dat \
       $APP/usr/share/scummvm/

    # 開機直接進遊戲(--auto-detect 偵測並執行;savepath 寫到使用者家目錄)
    cat > $APP/AppRun <<"EOF"
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
SAVE="${XDG_DATA_HOME:-$HOME/.local/share}/simon-cht/saves"
mkdir -p "$SAVE"
DATA="${HERE}/usr/share/scummvm"
exec "${HERE}/usr/bin/scummvm" -p "${HERE}/usr/share/simon-game" \
     --themepath="$DATA" --extrapath="$DATA" \
     --savepath="$SAVE" --auto-detect "$@"
EOF
    chmod +x $APP/AppRun

    cat > $APP/scummvm.desktop <<"EOF"
[Desktop Entry]
Type=Application
Name=Simon the Sorcerer CHT
Exec=AppRun
Icon=scummvm
Categories=Game;
EOF
    convert -size 256x256 "radial-gradient:#3a2668-#0c0818" -font /usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc \
        -gravity center -fill "#c9a227" -pointsize 60 -annotate +0-20 "西蒙" \
        -fill "#f2ead2" -pointsize 26 -annotate +0+60 "CHT" $APP/scummvm.png 2>/dev/null || \
        convert -size 256x256 xc:navy $APP/scummvm.png

    cd /tmp
    ARCH=x86_64 /w/.toolcache/appimagetool --appimage-extract-and-run /tmp/AppDir /w/dist-all/SimonTheSorcerer-CHT-FULL-x86_64.AppImage 2>&1 | tail -3
    chown -R '"$(id -u):$(id -g)"' /w/dist-all 2>/dev/null || true
'
echo "=== dist-all ==="; ls -lh "$PROJ/dist-all/"*.AppImage 2>/dev/null
