# 開發環境與建置流程

整個專案的可重現建置流程。所有編譯都在 docker 或 GitHub Actions 內完成,不污染本機環境。
遊戲原始資料(`*.GME` / `*.VOC` / `GAMEPC` / floppy 影像)一律不進 git,建置產物的「完整版」(含遊戲)只在本機保存。

## 目錄角色

| 目錄 | 內容 | 進 git? |
|---|---|---|
| `patches/` | `agos-cht.patch`(引擎改動)+ `cht_fusion.h/.cpp`(新增檔) | ✅ |
| `translations/zh.tsv` | 4035 行 floppy id → 中文 | ✅ |
| `fonts/` | `simon_zh24.dcjk`(24×24 Big5 字型)、`simon_zh.tab`、`simon_voice.map` | ✅(字型工具產物) |
| `scripts/` | 各平台建置腳本 | ✅ |
| `build/scummvm-src/` | 本機工作用的 ScummVM 原始碼樹(已套 patch) | ❌(gitignore) |
| `run_floppy/` | 可執行的完整遊戲目錄(floppy 資料 + `SIMON.VOC` + CHT 資產) | ❌ |
| `dist-all/` | **所有打包產物統一放這**(見下) | ❌ |

## 打包產物統一放 `dist-all/`(慣例)

所有可交付/可散布的打包一律輸出到 `dist-all/`(gitignore,不入庫),舊的 `dist/`、`dist-mac/` 已淘汰:

| 產物 | 來源腳本 |
|---|---|
| `SimonTheSorcerer-CHT-FULL-x86_64.AppImage` | `scripts/build_appimage.sh` |
| `SimonTheSorcerer-CHT-FULL-win64.zip` | `scripts/build_windows.sh`(自足:含 exe+DLL+data+遊戲+bat,直接產 zip) |
| `SimonScummVM-CHT-FULL-mac.tar.gz` | CI `build-mac` 產 `.app` → 本機注入 `run_floppy` + `scummvm-data` → tar 到 `dist-all/` |
| `simon-cht-promo.mp4` | `scripts/make_promo.sh`(產在 `promo_build/out/`,複製到 `dist-all/`) |
| `simon-1-cht-dev-setup-YYYYMMDD.tar.zst` | dev-setup 跨機接續包(見 `SETUP.md`) |

清理舊版打包只留最新一份:直接刪 `dist-all/` 內舊檔;中間 staging(mingw 的 portable 目錄、mac 的 `.app` 解壓)腳本跑完會自清。

## 核心概念:patch,不是 fork

ScummVM 原始碼不進本 repo。CHT 改動全部收斂成:

- `patches/agos-cht.patch` — 對 AGOS 引擎既有檔的改動(字型載入、Big5 windowPutChar、extraBuffer 放大、F8 切換、防拷 bypass、融合注入點)。
- `patches/cht_fusion.h` / `cht_fusion.cpp` — 新增的融合模組(字型 / 對照表 / 語音映射載入 + Big5 索引)。

任何平台建置都是:`clone scummvm v2.9.1` → `cp cht_fusion.*` → `git apply agos-cht.patch` → 建。
patch 對乾淨 v2.9.1 可乾淨套用(CI 前置驗證,見下)。

## 資產產生鏈(一次性,產物已進 git)

```
translations/zh.tsv ──┐
                      ├─ scripts/build_font.sh ─→ fonts/simon_zh24.dcjk (24×24 Big5)
Big5 來源字型 ────────┘                          fonts/simon_zh.tab  (id→Big5 文字表)
speech 對照 ──────────── ─────────────────────→ fonts/simon_voice.map (id→speechId)
```

字型與對照表在執行期由 `cht_fusion.cpp` 載入,放在遊戲目錄旁。

## 平台一:Linux AppImage(`scripts/build_appimage.sh`)

- 基底 docker image 內編 ScummVM(AGOS-only)。
- AppDir 打包遊戲資料到 `usr/share/simon-game/`,`AppRun` 用 `--auto-detect` 自動進遊戲。
- `appimagetool` 需要 `file` 指令;工具下載到本機 `.toolcache/` 掛載進容器。
- 產物:`dist/SimonTheSorcerer-CHT-FULL-x86_64.AppImage`(約 98MB,雙擊直接進 Simon)。

## 平台二:Windows(`scripts/build_windows.sh`,docker mingw 交叉編譯)

- `debian:bookworm-slim` + `g++-mingw-w64-x86-64`(交叉)+ **原生 `g++`**(ScummVM 建置期主機工具需要,漏了會 `g++: not found` 卡在 `base/main.o`)。
- SDL2 用官方 `SDL2-devel-2.30.9-mingw`(`--with-sdl-prefix`),不自編。
- configure:`--host=x86_64-w64-mingw32 --enable-engine=agos --disable-all-engines --enable-release`,關掉 mad/vorbis/flac/fluidsynth/mpeg2/theora/faad/curl/timidity。
- 收 DLL:`objdump -p` 驗相依。scummvm.exe 實際只動態相依 `SDL2.dll` + `zlib1.dll`(C++ runtime 靜態連結);另附 `libgcc_s_seh-1` / `libstdc++-6` / `libwinpthread-1` 保險(「包含所有 DLL」)。
- 完整版(本機):`dist/win/` = `scummvm.exe` + 5 個 DLL + `game/`(遊戲資料) + `播放遊戲.bat`(`scummvm.exe -p game --auto-detect`),免安裝雙擊即玩。

## 平台三:macOS(`scripts/ci_mac_build.sh` + `.github/workflows/build-mac.yml`)

本機沒有 macOS,走 GitHub Actions `macos-14`(Apple Silicon)。關鍵取捨:

- **不用 brew 的 sdl2**:brew `sdl2` 現在是 `sdl2-compat`(底層轉 SDL3),會引入 shim。改自編 pinned **真 SDL2 2.30.9**。
- **universal 要 per-arch 分別編再 lipo**:ScummVM autoconf 單次雙弧(`-arch arm64 -arch x86_64`)會炸 configure。所以 SDL2 與 ScummVM 都各編 arm64 / x86_64 兩次(x86_64 走 `arch -x86_64` Rosetta),再 `lipo -create` 合併 binary 與 `libSDL2-2.0.0.dylib`。
- **dylibbundler 用 `-s $PREFIX/lib` 且 `</dev/null`**:指定自編 SDL prefix 當搜尋路徑,`</dev/null` 避免互動卡住。
- 防呆:`otool -L` 檢查 Frameworks 內 SDL2 不含 `SDL3`(擋到 sdl2-compat 就 fail)。
- 產物:`dist-mac/SimonScummVM-CHT.app` → `.dmg` + `.tar.gz`(不含遊戲,`.app/Contents/Resources/game` 由本機注入後 `launch.sh` 自動載入)。

觸發:`gh workflow run build-mac.yml`,完成後 `gh run download` 取 artifact。

## 驗證紀律

- Windows:cross-compile 連得過不等於跑得動 → Wine 煙霧測試(`--version` + `--auto-detect` 偵測)。
- macOS:CI 內 `lipo -info` 確認雙弧、`otool -L` 確認 SDL2 非 SDL3 shim。
- 共通:同一份 patch 在 Linux 原生 build 已驗證可進遊戲(CJK 字幕 + CD 語音 + F8 切換),交叉平台只需確認 PE/Mach-O 載入正常。
