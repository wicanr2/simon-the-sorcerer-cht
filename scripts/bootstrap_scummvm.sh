#!/bin/bash
# 在新機器重建 build/scummvm-src(已套 CHT patch 的 ScummVM 源碼樹),供 build_*.sh 使用。
# dev-setup 包不含 build/(611M,可重建);新機解包後先跑這支,再跑 scripts/build_scummvm.sh。
# 流程:clone 乾淨 v2.9.1 → git apply agos-cht.patch → 補 cht_fusion.{cpp,h}。
set -e
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$PROJ/build/scummvm-src"
if [ -d "$SRC" ]; then
  echo "已存在 $SRC —— 略過(要重來先 rm -rf 它)"; exit 0
fi
echo "=== clone ScummVM v2.9.1 ==="
mkdir -p "$PROJ/build"
git clone --depth 1 --branch v2.9.1 https://github.com/scummvm/scummvm.git "$SRC"
cd "$SRC"
echo "=== 套 CHT patch ==="
git apply "$PROJ/patches/agos-cht.patch"
cp "$PROJ/patches/cht_fusion.cpp" "$PROJ/patches/cht_fusion.h" engines/agos/
echo "=== 驗證 patch 已套(reverse check 應通過)==="
git apply --check --reverse "$PROJ/patches/agos-cht.patch" && echo "  OK"
echo ""
echo "build/scummvm-src 已重建。接著:"
echo "  ./scripts/build_scummvm.sh      # Linux 原生(docker)編譯,驗證用"
echo "  ./scripts/build_appimage.sh     # Linux 完整版 AppImage"
echo "  ./scripts/build_windows.sh      # Windows 完整版(docker mingw)"
