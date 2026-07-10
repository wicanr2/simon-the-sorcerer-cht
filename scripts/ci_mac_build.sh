#!/bin/bash
# 在 GitHub Actions macos-14 (Apple Silicon) 上建 universal .app:
#   自編 pinned 真 SDL2(非 brew,避 sdl2-compat→SDL3)per-arch + lipo 合併
#   ScummVM autoconf 每弧各編一次 + lipo(單次雙弧會炸 configure)
#   dylibbundler -s $PREFIX/lib </dev/null(避 @rpath 互動 hang)
# 產出:dist-mac/SimonScummVM-CHT.app + .dmg + .tar.gz(無遊戲,私用版本機注入)
set -euo pipefail
SDL_VER=2.30.9; MIN=11.0

# 斷言:必須在 Apple Silicon(arm64)runner 上,否則 arch -x86_64(Rosetta)邏輯會反。
# GitHub macos-14 = arm64;若被排到 Intel(macos-13)runner,x86_64 變原生、arm64 無法
# 用 Rosetta 跑 configure 測試,會產出單弧或壞掉的 binary。寧可 fail-fast。
HOSTARCH="$(uname -m)"
if [ "$HOSTARCH" != "arm64" ]; then
  echo "FATAL: 需要 Apple Silicon(arm64)runner,實際 uname -m=$HOSTARCH。" >&2
  echo "       請確認 workflow runs-on: macos-14(非 macos-13/Intel)。" >&2
  exit 1
fi

ROOT="$PWD"; WORK="$ROOT/_macbuild"; mkdir -p "$WORK"
SRC="$WORK/scummvm-src"; DIST="$ROOT/dist-mac"; mkdir -p "$DIST"

log(){ echo "[$(date +%H:%M:%S)] $*"; }

# ---- 0. 取 ScummVM v2.9.1 + 套 CHT patch ----
if [ ! -d "$SRC" ]; then
  log "clone ScummVM v2.9.1"
  git clone --depth 1 --branch v2.9.1 https://github.com/scummvm/scummvm.git "$SRC"
  log "apply CHT patch"
  cp "$ROOT/patches/cht_fusion.h" "$ROOT/patches/cht_fusion.cpp" "$SRC/engines/agos/"
  ( cd "$SRC" && git apply "$ROOT/patches/agos-cht.patch" )
fi

# ---- 1. 自編 SDL2 per-arch ----
build_sdl(){ local arch=$1 pref=$2
  [ -f "$pref/lib/libSDL2-2.0.0.dylib" ] && return 0
  log "build SDL2 $arch"
  local d="$WORK/SDL2-$SDL_VER"
  [ -d "$d" ] || { curl -Ls "https://github.com/libsdl-org/SDL/releases/download/release-$SDL_VER/SDL2-$SDL_VER.tar.gz" | tar xz -C "$WORK"; }
  rm -rf "$WORK/sdlbuild-$arch"; cp -r "$d" "$WORK/sdlbuild-$arch"; cd "$WORK/sdlbuild-$arch"
  local runner=""; [ "$arch" = "x86_64" ] && runner="arch -x86_64"
  $runner ./configure --prefix="$pref" \
      CFLAGS="-arch $arch -mmacosx-version-min=$MIN" \
      LDFLAGS="-arch $arch -mmacosx-version-min=$MIN" >/dev/null
  $runner make -j"$(sysctl -n hw.ncpu)" >/dev/null
  make install >/dev/null
  cd "$ROOT"
}
build_sdl arm64  "$WORK/sdl-arm64"
build_sdl x86_64 "$WORK/sdl-x86_64"

# ---- 2. ScummVM per-arch (autoconf 單弧) ----
build_scummvm(){ local arch=$1 sdlpref=$2 out=$3
  log "build ScummVM $arch"
  cd "$SRC"; make distclean >/dev/null 2>&1 || true
  local runner=""; [ "$arch" = "x86_64" ] && runner="arch -x86_64"
  # ScummVM configure 非 autoconf:CXXFLAGS/LDFLAGS 只能走環境變數,不能當 KEY=VALUE 引數
  # (SDL2 是 autoconf 才吃引數)。arch 值須與 $runner 一致:x86_64 在 Rosetta 下 -arch x86_64。
  CXXFLAGS="-arch $arch -mmacosx-version-min=$MIN" \
  LDFLAGS="-arch $arch -mmacosx-version-min=$MIN" \
  PATH="$sdlpref/bin:$PATH" $runner ./configure \
      --enable-engine=agos --disable-all-engines --enable-release \
      --with-sdl-prefix="$sdlpref" \
      --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
      --disable-mpeg2 --disable-theoradec --disable-faad --disable-libcurl \
      --disable-png --disable-freetype2 --disable-jpeg --disable-timidity >/dev/null
  $runner make -j"$(sysctl -n hw.ncpu)" >/dev/null
  cp scummvm "$out"
  cd "$ROOT"
}
build_scummvm arm64  "$WORK/sdl-arm64"  "$WORK/scummvm.arm64"
build_scummvm x86_64 "$WORK/sdl-x86_64" "$WORK/scummvm.x86_64"

# ---- 3. lipo 合併 binary 與 SDL dylib ----
log "lipo universal"
lipo -create "$WORK/scummvm.arm64" "$WORK/scummvm.x86_64" -output "$WORK/scummvm.univ"
lipo -info "$WORK/scummvm.univ"
mkdir -p "$WORK/sdl-univ/lib"
lipo -create "$WORK/sdl-arm64/lib/libSDL2-2.0.0.dylib" "$WORK/sdl-x86_64/lib/libSDL2-2.0.0.dylib" \
     -output "$WORK/sdl-univ/lib/libSDL2-2.0.0.dylib"

# ---- 4. 組 .app ----
APP="$DIST/SimonScummVM-CHT.app"; rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$WORK/scummvm.univ" "$APP/Contents/MacOS/scummvm"
chmod +x "$APP/Contents/MacOS/scummvm"
# ScummVM 執行期資料檔(GUI 主題/字型/翻譯)—— 缺了會 "Could not find theme / font"(issue #1/#2)
mkdir -p "$APP/Contents/Resources/scummvm-data"
cp "$SRC/gui/themes/scummmodern.zip" "$SRC/gui/themes/scummclassic.zip" \
   "$SRC/gui/themes/scummremastered.zip" "$SRC/gui/themes/gui-icons.dat" \
   "$SRC/gui/themes/shaders.dat" "$SRC/gui/themes/translations.dat" \
   "$SRC/dists/engine-data/fonts.dat" "$SRC/dists/engine-data/fonts-cjk.dat" \
   "$APP/Contents/Resources/scummvm-data/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Simon CHT</string>
  <key>CFBundleDisplayName</key><string>神通妙巫師 繁中</string>
  <key>CFBundleIdentifier</key><string>com.wicanr2.simon-cht</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleExecutable</key><string>launch.sh</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>$MIN</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
# 啟動 wrapper:指向 bundle 內遊戲(私用版注入到 Resources/game)+ auto-detect
cat > "$APP/Contents/MacOS/launch.sh" <<'LAUNCH'
#!/bin/bash
D="$(cd "$(dirname "$0")" && pwd)"
GAME="$D/../Resources/game"
DATA="$D/../Resources/scummvm-data"
SAVE="$HOME/Library/Application Support/simon-cht/saves"; mkdir -p "$SAVE"
if [ -d "$GAME" ]; then
  exec "$D/scummvm" -p "$GAME" --themepath="$DATA" --extrapath="$DATA" --savepath="$SAVE" --auto-detect
else
  exec "$D/scummvm" --themepath="$DATA" --extrapath="$DATA" --savepath="$SAVE"
fi
LAUNCH
chmod +x "$APP/Contents/MacOS/launch.sh"

# ---- 5. 手動 bundle SDL2(唯一非系統 dylib;png/freetype/vorbis 等皆已停用)----
# 不用 dylibbundler:lipo 後的 universal scummvm 兩個 slice 各自參照不同 prefix 的
# SDL2 路徑(autoconf 的 install_name = 各自 --prefix),dylibbundler 只會抓其中一份
# 非-fat dylib,導致 Frameworks 內 SDL2 變單弧(x86_64)。改手動放 universal SDL2 進
# Frameworks,對兩個舊路徑各 install_name_tool -change 一次(每次只影響對應 slice)。
log "manual bundle SDL2 (universal)"
SDL_ARM="$WORK/sdl-arm64/lib/libSDL2-2.0.0.dylib"
SDL_X86="$WORK/sdl-x86_64/lib/libSDL2-2.0.0.dylib"
FW="$APP/Contents/Frameworks/libSDL2-2.0.0.dylib"
cp "$WORK/sdl-univ/lib/libSDL2-2.0.0.dylib" "$FW"; chmod 644 "$FW"
install_name_tool -id "@executable_path/../Frameworks/libSDL2-2.0.0.dylib" "$FW"
install_name_tool -change "$SDL_ARM" "@executable_path/../Frameworks/libSDL2-2.0.0.dylib" "$APP/Contents/MacOS/scummvm"
install_name_tool -change "$SDL_X86" "@executable_path/../Frameworks/libSDL2-2.0.0.dylib" "$APP/Contents/MacOS/scummvm"
# install_name_tool 改過必須重簽(否則載入/Gatekeeper 失敗);ad-hoc 對兩弧都有效
codesign --force --sign - "$FW"
codesign --force --sign - "$APP/Contents/MacOS/scummvm"

# ---- 5b. 防呆:binary 與 SDL2 都必須 universal(arm64+x86_64)、非 SDL3 shim、無殘留絕對路徑 ----
for f in "$APP/Contents/MacOS/scummvm" "$FW"; do
  info=$(lipo -info "$f"); echo "$info"
  echo "$info" | grep -q "arm64" && echo "$info" | grep -q "x86_64" || { echo "FATAL: $f 非 universal"; exit 1; }
done
if otool -L "$APP/Contents/MacOS/scummvm" | grep -qi "SDL3"; then echo "FATAL: SDL3 shim"; exit 1; fi
if otool -L "$APP/Contents/MacOS/scummvm" | grep -q "_macbuild"; then
  echo "FATAL: scummvm 殘留 build 期絕對路徑"; otool -L "$APP/Contents/MacOS/scummvm"; exit 1; fi
ls -la "$APP/Contents/Frameworks/"; otool -L "$APP/Contents/MacOS/scummvm" | grep -i sdl

# ---- 6. 打包 .dmg + .tar.gz(雙保險)----
log "package"
tar czf "$DIST/SimonScummVM-CHT-mac.tar.gz" -C "$DIST" "SimonScummVM-CHT.app"
hdiutil create -volname "Simon CHT" -srcfolder "$APP" -ov -format UDZO "$DIST/SimonScummVM-CHT-mac.dmg" >/dev/null
log "done"; ls -lh "$DIST"
