# 宣傳影片拍攝計畫(神通妙巫師 繁中融合版)— v5 重拍(640 crisp)

依 `game-promo-video-ffmpeg` skill(三段 pipeline)與 `rulebook/93`(配樂用原版鐵則)擬定。
本文件是**計畫**;實作腳本已存在(`scripts/make_promo.sh` v4 + `promo_build/rec_*.sh`),本輪只更新計畫,尚未重新產片。

> **這一版為什麼要重拍**:現有 YouTube 片(youtu.be/TTQcoItbF38)的所有實機畫面都是舊 **320×200** 錄的——
> 中文字幕又糊又擠。引擎已改用 **PC98 雙層 640×400 高解析**(字幕/面板/懸停句畫進 `_scaleBuf` 疊層,
> 相對變小、真 crisp)。重拍的**核心動作 = 把錄製從 320 拉到 640**,並新增一段「糊→清」前後對比,
> 把清晰度當成這一版的新賣點之一。

---

## 1. 目標與規格

- **時長** 60–75 秒;**解析度** 1280×720;**FPS** 25。
- **theme(沿用 v4,不重挑)**:「羊皮紙與魔法書」——token 萃取自遊戲本身
  (閣樓暖木 `#120b06`/`#3a2412`、羊皮紙 `#e8d9b0`、琥珀標題 `#d98e2b`、遊戲字幕綠 `#1b6103`/`#2f9e0a`、磚紅場景標 `#ac301c`)。
- **敘事骨架(沿用 v4)**:骨架 E(實機錄影混剪為主)+ 對白卡(骨架 C)穿插。
- **賣點順序**(這片要讓人記住的):
  1. 完整中文字幕(補足英文 CD 版缺的約四成對白)。
  2. **640×480 高解析,中文字終於清晰**(本版新增;糊→清對比段)。
  3. 保留 CD 英語配音(Chris Barrie 原聲)+ F8 中/英切換。
  4. 經典英式冷笑話(托爾金惡搞、巨魔橋)終於看懂。
- **調性**:奇幻詼諧(黑爵士式冷幽默),不要嚴肅史詩腔。

## 2. 三段 pipeline

`① 擷取(640 crisp 錄影 + 原版音樂)→ ② 素材(標題卡/對白卡/對比卡,程序生成)→ ③ ffmpeg 合成(clip+fade+配樂)`

全程 docker、CPU 限 2 核、可重跑。工具 image `game-video:latest`(`ffmpeg imagemagick fonts-noto-cjk fluidsynth`)一次建好。

---

## 3. 素材清單

### 3.1 實機錄影 —— [本輪最重點] 大量增加「進到遊戲」的實機畫面

> **使用者回饋(2026-07-09)**:現有片**真正進到遊戲的畫面太少**,整片被程序生成的標題卡/羊皮紙對白卡塞滿。
> 這一版要**反過來**:實機遊玩畫面當主角,卡片只留必要的框(標題/問題/收尾),對白盡量**在遊戲裡實拍**、不要拿羊皮紙卡替代。

#### (a) 解析度改 640 crisp(前提)

`promo_build/rec_clips.sh` 寫死 320×200,**必須改**:

| 位置 | 舊(320) | 新(640 crisp) |
|---|---|---|
| Xvfb 螢幕 | `-screen 0 320x200x24` | `-screen 0 640x480x24` |
| x11grab | `-video_size 320x200` | `-video_size 640x480` |
| xdotool 座標 | 320×200 邏輯座標(如 `160 100`) | **×2**(hires `_mouse >>= 1`,螢幕 640 → 邏輯 320;點同一物件要 `320 200`) |

> 引擎 initGraphics 640×400,經 AGOS aspect 校正顯示 640×480 全幅(見 `docs/img/hero_scene.png`)。改完先錄一小段抽幀確認**字 crisp、面板中文有出來**(需 `simon_zh16.dcjk` 在 game 目錄)。

#### (b) 三層取材法 —— 盡量拍到多、拍到深(愈上層愈省力)

**第 1 層:免解謎、直接可錄(先把這層錄滿,量就夠一半)**
- **片頭魔術秀**(auto play ~110s):Calypso 召喚、變狗把戲,中文字幕密集——最好取材,錄整段挑亮點。
- **開場臥室/閣樓**:遊戲真正起點,西蒙翻出《古老魔法書》。ESC 跳過場後可走動、查看物件(觸發中文物件名 + 動作句 + 旁白)。
- **巫師書房**(已驗證可達,見 `screenshots_scene/scene_02.png` 的「神祕掛毯」):壁爐、魔鏡、通花園拱門;懸停各物件錄中文物件名 + 底部中文動詞面板反白。
- 手法:`import`/x11grab 邊走邊錄,滑鼠移到不同物件停 2s 觸發中文,錄 40–60s/場景。

**第 2 層:ScummVM 存檔點跳場景(拍經典對白場景的正解)**
- 滑鼠驅動深層場景(巨魔橋、托爾金迷森林、蠹蟲、巫師小子店)難用 xdotool 導航——**改用存檔**:
  照攻略把遊戲玩到各經典點各存一格(ScummVM Ctrl+F5 / F5 存檔),錄影時 `scummvm ... --save-slot=N` 或載入存檔直接到那個場景實拍對白。
- 存檔一次做好可重複用;存檔檔放本機(gitignore),不入庫。

**第 3 層:AGOS 除錯台強制到場景(存檔太費時的 fallback)**
- 引擎內建 debugger(`debugger.cpp`)指令可不解謎叫出場景:
  - `sub <id>` = `Cmd_StartSubroutine`,直接跑某段遊戲腳本(可觸發特定房間/對白序列)。
  - `bit`/`var`/`obj` = 設旗標/變數/物件狀態(解開場景前置條件)。
  - `voice <id>` = 播指定語音(對嘴驗證/補錄)。
- 需先查對應的 subroutine / flag id(用既有 `scripts/dump_scripts.sh` dump 腳本反查);屬進階手段,前兩層拍夠就不必動。

#### (c) 產出對應分鏡(見 §4):第 1 層 → 片頭/開場/書房 clip;第 2 層 → 巨魔橋·托爾金·蠹蟲 clip。重錄後時間戳位移,合成時抽幀對齊 `make_promo.sh` 的 `ss/dur`。

### 3.2 「糊→清」前後對比素材 —— [本版新增]

新增一段 `split_ba` 式對比(skill 版面庫 D:前後對照),把**同一句字幕**的舊糊版 vs 新清版並排:

- **右(新)**:640 crisp 錄影/截圖裁下字幕區(如 `docs/img/subtitle_crisp.png` 的「你知道嗎 我可是完全自學的」)。
- **左(舊)**:同一句的 320×200 糊版。**來源**:
  - git 歷史(commit `3b6ecd3` 之前的 `docs/img/hero_subtitle.png` / `subtitle_2lines.png`),或
  - 舊 `promo_build/out/*.mp4`(320 錄影)抽幀,或
  - 暫時把 `run_floppy` 的 `simon_zh24.dcjk` 移開跑一次 320… **不建議**;直接用 git 歷史的舊圖最省。
- 版面:左右分割 + 中間琥珀色箭頭 `▶`;上緣小字「舊 320」/「新 640」,底部字幕條「看得更清楚了」。
- 可在 `make_promo.sh` 加一個 `split_hires()`(仿現有 `split_ba()`,吃兩張圖而非中英字串)。

### 3.3 配樂 —— [HARD] 用原版遊戲音樂,不自產(rulebook 93)。**沿用不重錄**

- 現成 `promo_build/music/simon_title_bgm.wav`(由 `rec_music.sh` 產:`SDL_AUDIODRIVER=disk` +
  `-e adlib --music-volume=255` 錄原版 AdLib 主題,全速灌爆需掃描找有聲窗)。音訊與解析度無關,**沿用即可**。
- 若要重錄:照 `rec_music.sh`,錄完用 python 逐 20s `volumedetect` 掃 `mean_volume > -60dB` 的有聲窗截取
  (別假設音樂在前段);`ffmpeg -i x.wav -af volumedetect` 驗非靜音、無 clipping、時長對(10KB/60s = 壞檔重錄)。

### 3.4 標題卡 / 對白卡設計 token —— 沿用 v4(§1 的羊皮紙 theme,勿改回 v1 紫金)

- `card()` 暖木徑向漸層底 + 琥珀浮雕標題(暗金陰影 `#6b3d10` + 主金 `#d98e2b` + 米白副標)。
- `dcard()` 羊皮紙面板 + 陰影 + 磚紅場景標 + 墨綠對白(用遊戲字幕綠,對白專用)。
- 字型:標題 `NotoSerifCJK-Bold.ttc`、內文 `NotoSerifCJK-Regular.ttc`(無 Medium;用前 `ls` 確認路徑)。

---

## 4. 分鏡 storyboard v5(= v4 + 糊→清對比段;13 段)

| # | 型 | 內容 | 秒 | 字幕/文案 |
|---|---|---|---|---|
| 00 | live clip | 遊戲 logo 動畫開場(640 crisp) | 6 | Simon the Sorcerer · 1993 · Adventure Soft |
| 01 | 標題卡 | 主標題 | 6 | 神通妙巫師 / 繁體中文化 / CD 語音 × Floppy 完整字幕 |
| 02 | 對白卡 | 問題點 | 5 | 「英文 CD 版沒有完整字幕。嘴巴在動,一個字都看不到。」 |
| 03 | 對白卡 | 解法 | 5 | 「floppy 完整文字 × CD 英語配音,融合成從未存在過的版本。」 |
| 04 | live clip | 片頭魔術秀(**640 crisp** 中文字幕即時渲染) | 10 | 「完整中文字幕,一句不漏。」 |
| **★** | **對比卡** | **糊→清(本版新增)** | **5** | **左 舊 320 糊 / 右 新 640 清;「看得更清楚了」** |
| 05 | live clip | 場景遊玩(640 crisp,懸停物件名/動詞面板) | 10 | 「操作選單、旁白全程中文。」 |
| 06 | split_ba | 中/英對照(F8) | 5 | 謝謝你,奇皮。 ↔ Thank-you, Chippy. |
| 07 | 對白卡 | 托爾金迷 | 6 | 「以托爾金的神聖鬍鬚之名,準備受死吧!!!」 |
| 08 | live clip | 實際遊玩,旁白中文 | 8 | — |
| 09 | 對白卡 | 巨魔橋 | 6 | 「你走運了,我正好是個到處推銷滿足的業務員。」 |
| 10 | 標題卡 | 特色收束 | 5 | 全劇 4035 條一句不漏 / 英語原聲 · F8 中英切換 · 防拷免手冊 |
| 11 | 標題卡 | 結尾/連結 | 6 | 神通妙巫師 繁中化 / github.com/wicanr2/simon-the-sorcerer-cht |

節奏:標題慢(6s)、live/亮點 8–10s、對白卡 5–6s、結尾留長音;配樂淡入 2s、淡出 3s、`volume 1.6`。
糊→清對比段放在「秀完 crisp 字幕(#04)之後」——先讓觀眾看到清楚的,再回頭對比舊糊版,升級感最強。

## 5. 工程注意(skill 踩過的雷)

- **[HARD] 錄影解析度改 640,但別碰 zoompan**:live clip 用 `enc()`/`clip()` 靜態 fade,不要 zoompan(幀數爆炸燒 CPU 8 分鐘)。
- `docker run --cpus=2` + ffmpeg `-preset veryfast -threads 2`;工具用預建 `game-video:latest` 別每次 apt。
- 重錄 clip 後**先抽幀讀圖**確認 crisp(字不糊、面板中文在);再對齊 `make_promo.sh` 的 `ss/dur`。
- 字型 `fonts-noto-cjk` 只有 Regular/Bold;ImageMagick policy 若擋 `@` 讀檔用 `sed` 放行本地讀取。
- xdotool 座標記得 ×2(hires `_mouse >>= 1`);沒 ×2 會點錯地方跳不過片頭。

## 6. 對外發布的 IP 提醒(rulebook 93 但書)

- 原版 Simon 音樂是 Adventure Soft / 作曲者著作權。**本機保存/內部 demo** 用原版沒問題,素材與產片 gitignore 不入庫。
- **公開上傳**(YouTube 等):配原版音樂 = 散布他人著作,有風險。現有 YouTube 片已這樣發過;
  若在意,重發時可改授權曲/原創曲。**維持既有做法前先讓使用者拍板**。

## 7. 執行骨架(等使用者說「開拍」再做)

```bash
# 0) 改錄製解析度:promo_build/rec_clips.sh 與 capt_gameplay.sh 的 320x200 → 640x480,xdotool 座標 ×2
# 1) 建工具 image(若無):
docker run --cpus=2 --name vb debian:bookworm-slim bash -c \
  'apt-get update -qq && apt-get install -y -qq ffmpeg imagemagick fonts-noto-cjk fluidsynth'
docker commit vb game-video:latest && docker rm vb
# 2) 重錄 640 crisp 畫面(clip 進 promo_build/clips/,music 沿用):
docker run --rm --cpus=2 -v $PWD/run_floppy:/game -v $PWD/promo_build/out:/out game-video:latest bash /game/../promo_build/rec_clips.sh
# 3) 加 split_hires() + 糊→清對比段到 make_promo.sh,對齊時間戳
# 4) 合成(限 2 核):
docker run --rm --cpus=2 -v $PWD/promo_build/shots:/shots:ro -v $PWD/promo_build/clips:/clips:ro \
  -v $PWD/promo_build/music:/music:ro -v $PWD/promo_build/out:/out \
  -v $PWD/scripts/make_promo.sh:/make.sh:ro game-video:latest bash /make.sh
```

## 8. 產出與驗收

- 產出:`dist/simon-cht-promo.mp4`(60–75s,720p,H.264 + AAC;覆蓋舊 v4)。
- 驗收:抽 3–4 幀讀圖——**live clip 字幕要 crisp(不糊不擠)**、對比段左右差異明顯、標題不糊、字幕不被裁、配色統一、黑邊少、節奏對;配樂 `ffprobe volumedetect` 非空白。
- 差異化(vs 現有 YouTube 片):畫面 320→640 crisp、新增糊→清對比段;theme 仍羊皮紙(同 v4,不算新片而是升級重拍)。
- 影片與音樂素材 **gitignore 不入庫**(同遊戲原檔)。

---

*相關:`rulebook/93`(素材真實性)、`game-promo-video-ffmpeg` skill(合成實務)、`scripts/make_promo.sh`(v4 實作)、`promo_build/rec_*.sh`(錄製)、記憶 [[sdl-disk-audio-capture-gotchas]](AdLib 錄音雷)、[[agos-hires-cjk-subtitle-empty-sprite-overlay]](crisp 字幕機制)。*
