# 宣傳影片拍攝計畫(神通妙巫師 繁中融合版)

依 `game-promo-video-ffmpeg` skill(u1-cht 起源的三段 pipeline)與 `rulebook/93`(配樂用原版鐵則)擬定。
本文件是**計畫**,尚未產片;要開拍時照本文執行。

## 1. 目標與規格

- **時長** 60–75 秒;**解析度** 1280×720;**FPS** 25。
- **賣點順序**(這片要讓人記住的三件事):
  1. 完整中文字幕(補足英文 CD 版缺的約四成對白)。
  2. 保留 CD 英語配音(Chris Barrie 原聲)。
  3. 一鍵(F8)中/英字幕切換 + 經典英式冷笑話終於看懂。
- **調性**:奇幻詼諧(對應 Simon 的黑爵士式冷幽默),不要嚴肅史詩腔。

## 2. 三段 pipeline

`① 擷取(截圖 + 原版音樂)→ ② 素材(標題卡/字幕卡程序生成)→ ③ ffmpeg 合成(投影片+fade+配樂)`

全程 docker、CPU 限 2 核、可重跑。工具 image 一次建好(`ffmpeg imagemagick fonts-noto-cjk fluidsynth`)。

## 3. 素材清單

### 3.1 截圖(Simon 是滑鼠驅動 → 用靜態截圖,不跟 xdotool 纏鬥)

既有可用(`docs/img/`、`screenshots/`):
- `docs/img/hero_subtitle.png` — 西蒙+奇皮,字幕「謝謝你,奇皮。」(題圖)
- `docs/img/intro_montage.png` — 片頭中文字幕連續幀
- `screenshots/PROOF_full_translation.png`

需補拍(用 `scripts/run_capture.sh` 改存檔點,或既有存檔跳場景):
- 巨魔橋對話(「你走運了,我正好是個到處推銷滿足的業務員。」)
- 蠹蟲場景(「這就是歧視——第三級的!」)
- 動詞列繁中(操作選單:走到/查看/使用)
- F8 切換前後對照(同一句 英文↔中文,做並排或前後兩張)
- 存讀檔畫面繁中(「要覆寫嗎? 是 否」)

截圖保留遊戲原色,只在合成時加金框。

### 3.2 配樂 —— [HARD] 用原版遊戲音樂,不自產(rulebook 93)

- Simon 1 原版音樂在 `original_game_floppy/installed/*.MUS`(45 首,AdLib/MT-32 模組格式)。
- **取得方式**:用 **ScummVM 本身**播放 Simon 的音樂並錄音(最真實):
  ```bash
  # 用 patched scummvm 以 disk audio 錄製主題曲(SDL disk driver)
  SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=/out/cap.raw \
    scummvm -p /game --auto-detect   # 進到有音樂的場景
  ffmpeg -f s16le -ar 44100 -ac 2 -i /out/cap.raw /out/simon_bgm.wav
  ```
  (AGOS MUS 非標準 MIDI,交給引擎自己的 MIDI/AdLib driver 渲染最準;不要自寫合成器逼近。)
- **驗證(鐵則 93-2)**:`ffmpeg -i simon_bgm.wav -af volumedetect -f null /dev/null` 看 `mean/max_volume` 非靜音、無 clipping、時長對;10KB/60s = 壞檔重錄。
- **選曲**:優先片頭主題(最有辨識度);找不到主題就取酒館/森林等有記憶點的場景曲。

### 3.3 標題卡設計 token(換皮只改這段)

- 配色:深紫徑向漸層底(`#241844`→`#0c0818`)、鎏金標題(`#c9a227` + 暗金陰影 `#7a5c14` 浮雕)、米白副標(`#f2ead2`)。
- 字型:標題 `NotoSerifCJK-Bold`、字幕 `NotoSerifCJK-Regular`(襯線較有奇幻質感;先 `ls` 確認 `.ttc` 路徑存在)。
- 標題文案:中標「神通妙巫師」/ 英標「Simon the Sorcerer」/ 副標「繁體中文化 · CD 語音 × 完整字幕」。

## 4. 分鏡 storyboard(約 11 段)

| # | 型 | 內容 | 秒 | 字幕/文案 |
|---|---|---|---|---|
| 00 | 標題卡 | 主標題 | 6 | 神通妙巫師 / Simon the Sorcerer / 繁體中文化 |
| 01 | 字幕卡 | 問題點 | 5 | 「英文 CD 版,其實沒有完整字幕。」 |
| 02 | 截圖 | 嘴動無字(英文 CD 現象) | 4 | 「角色在說話,你卻一個字都看不到。」 |
| 03 | 字幕卡 | 解法 | 4 | 「用 floppy 完整文字 × CD 英語語音,融合。」 |
| 04 | 截圖 | 片頭中文字幕(hero) | 6 | 「完整中文字幕,一句不漏。」 |
| 05 | 截圖 | 巨魔橋 | 6 | 經典對白選段 |
| 06 | 截圖 | 蠹蟲場景 | 6 | 「連當年沒看懂的冷笑話,都補上了。」 |
| 07 | 截圖 | 動詞列繁中 | 5 | 「操作選單也中文化。」 |
| 08 | 截圖 | F8 中英對照 | 6 | 「按 F8,中英字幕即時切換。」 |
| 09 | 字幕卡 | 特色收束 | 5 | 「英語原聲 · 完整字幕 · 中英切換 · 防拷免手冊」 |
| 10 | 標題卡 | 結尾/連結 | 6 | github.com/wicanr2/simon-the-sorcerer-cht |

節奏:標題慢(6s)、亮點 6s/張、結尾留長音;配樂淡入 2s、淡出 3s。

## 5. 工程注意(skill 踩過的雷)

- **[HARD] 不用 zoompan**:預設靜態圖 + fade(zoompan 幀數爆炸會燒 CPU 8 分鐘)。要動態才餵單幀 + `-frames:v` 收。
- `docker run --cpus=2` + ffmpeg `-preset veryfast -threads 2`。
- 預建工具 image(`docker commit` 成 `game-video:latest`),別每次 apt。
- 先跑靜態版確認流程通,再考慮動態。
- 字型:`fonts-noto-cjk` 只有 Regular/Bold,無 Medium;用前 `ls` 確認路徑。
- ImageMagick policy 若擋 `@` 讀檔,`sed` 放行本地讀取。

## 6. 對外發布的 IP 提醒(rulebook 93 但書)

- 原版 Simon 音樂是 Adventure Soft / 作曲者著作權。**本機保存/內部 demo** 用原版沒問題,素材與產片 gitignore 不入庫。
- **若要公開上傳**(YouTube 等):配上原版音樂 = 散布他人著作,有風險 → **開拍前先向使用者確認**,可能改用授權曲/原創曲。

## 7. 執行骨架(CPU-safe 靜態+fade)

沿用 skill 的 `make_promo.sh` 骨架(設計 token 在最上、`card()`/`slide()`/`kb()` 函式、concat + afade 鋪配樂),
把 §3.3 的 token、§4 的分鏡填入。跑法:

```bash
# 1) 建工具 image(一次)
docker run --cpus=2 --name vb debian:bookworm-slim bash -c \
  'apt-get update -qq && apt-get install -y -qq ffmpeg imagemagick fonts-noto-cjk fluidsynth'
docker commit vb game-video:latest && docker rm vb
# 2) 合成(限 2 核)
docker run --rm --cpus=2 -v $PWD/promo_shots:/shots:ro -v /tmp/music:/music:ro \
  -v /tmp/out:/out -v $PWD/scripts/make_promo.sh:/make.sh:ro game-video:latest bash /make.sh
```

## 8. 產出與驗收

- 產出:`dist/simon-cht-promo.mp4`(60–75s,720p,H.264 + AAC)。
- 驗收:抽 3–4 幀讀圖檢查(標題不糊、字幕不被裁、配色、黑邊、節奏);配樂 ffprobe 非空白。
- 影片與音樂素材 **gitignore 不入庫**(同遊戲原檔)。

---

*相關:`rulebook/93`(素材真實性)、`game-promo-video-ffmpeg` skill(合成實務)、`retro-game-playtest`(截圖)。*
