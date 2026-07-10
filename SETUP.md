# 神通妙巫師 繁中化 — dev-setup(跨機接續包)

這包讓另一台電腦解開後能 (1) 重建整套 build/打包環境,並 (2) 用 `claude -r` 接續同一個 Claude 對話與記憶繼續工作。

## 這包有什麼 / 沒有什麼

| 有(帶進包) | 沒有(可重建,故排除) |
|---|---|
| 專案 source + 完整 `.git`(所有歷史/分支) | `build/`(611M,ScummVM 源碼樹 → 用 patch 重建) |
| `patches/`(agos-cht.patch + cht_fusion.{cpp,h}) | `dist/` `dist-mac/`(打包產物 → 重跑腳本) |
| `fonts/` `strings/` `translations/`(CHT 素材) | `promo_build/`(推廣片暫存) |
| `scripts/` `tools/` `docker/`(建置/打包/字型工具) | `screenshots*/`(工作截圖) |
| `run_floppy/`(可執行遊戲資料 + SIMON.VOC + CHT 資產)★ | |
| `claude-session/`(Claude 對話 + 記憶)★ | |

★ `run_floppy/` 含版權遊戲資料、`claude-session/` 含完整對話——**此包屬私用,勿公開散布**。

## 一、重建建置環境(新機器)

前置:`docker`、`git`、`bash`。所有編譯都在 docker 內,不污染主機。

```bash
# 1) 重建已套 patch 的 ScummVM 源碼樹(clone v2.9.1 + apply patch)
./scripts/bootstrap_scummvm.sh

# 2) Linux 原生編譯(驗證引擎)
./scripts/build_scummvm.sh

# 3) 完整版打包(含遊戲資料,產物在 dist/ dist-mac/,不入 git)
./scripts/build_appimage.sh          # Linux AppImage(148M,含 ScummVM 資料檔)
./scripts/build_windows.sh           # Windows zip(docker mingw)
gh workflow run build-mac            # macOS(GitHub Actions,產 universal .app)
```

建置細節(patch 不是 fork、各平台取捨、驗證紀律)見 `docs/DEV-SETUP.md`。
**重點**:三平台打包都必須隨附 ScummVM 執行期資料檔(`gui/themes/*.zip` + `translations.dat` + `fonts.dat` + `fonts-cjk.dat`)並在啟動器加 `--themepath`/`--extrapath`,否則會 "Could not find theme / font" 起不來(issue #1 根因,已修進三個 build 腳本)。

## 二、用 `claude -r` 接續 Claude 對話 ★

Claude session 依「當前工作目錄的編碼路徑」分目錄存放。要跨機接續:

### 情況 A:新機器放在**相同絕對路徑**(`/home/anr2/scummvm/simon-1-cht-claude`)
```bash
# 還原 session 到 ~/.claude/projects/<編碼路徑>/
mkdir -p ~/.claude/projects
cp -a claude-session/projects/-home-anr2-scummvm-simon-1-cht-claude \
      ~/.claude/projects/
cd /home/anr2/scummvm/simon-1-cht-claude
claude --continue          # 接最近一次;或 claude --resume 挑清單
```

### 情況 B:路徑不同(不同 user/home)
用 session UUID 直接接,不卡路徑(同 repo 任意目錄都找得到):
```bash
# 先把 session 檔放進去(照新路徑編碼建目錄,或用下面 UUID 法)
cp -a claude-session/projects/-home-anr2-scummvm-simon-1-cht-claude/* \
      ~/.claude/projects/<新路徑編碼>/
cd <新專案路徑>
claude --resume 9b89c4d8-ff80-42df-be9b-7b500da01914
```
> 編碼規則:絕對路徑 `/` 換成 `-`、開頭再加一個 `-`。
> 例:`/home/me/simon` → `-home-me-simon`。

**最近 session UUID:`9b89c4d8-ff80-42df-be9b-7b500da01914`**(見 `previous-work.md`)。
最小集 = `<UUID>.jsonl`(對話)+ `memory/`(長期記憶);兩者都在 `claude-session/` 內。
全域 `~/.claude/settings.json`、MCP、登入不必搬,新機重設即可。

## 三、接手先讀

`previous-work.md` —— 專案現況、本次做了什麼、待辦、硬約束、記憶索引。
