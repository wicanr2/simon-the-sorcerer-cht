# 神通妙巫師(Simon the Sorcerer)— 繁體中文化(CD 語音 × Floppy 完整字幕）

![實際遊玩畫面:640×480 高解析,中文動作句與動詞面板清晰](docs/img/hero_scene.png)

> 一個 12 歲男孩、一隻叫奇皮的狗、一本《古老魔法書》,和一個到處都是魔戒惡搞與英式冷笑話的平行世界。
> 三十年前它沒有中文版;現在,它有了——而且連英語配音都一起留著。

<p align="center">
  <a href="https://youtu.be/TTQcoItbF38">
    <img src="https://img.youtube.com/vi/TTQcoItbF38/hqdefault.jpg" alt="觀看介紹影片" width="480"><br>
    ▶ 觀看介紹影片(約 80 秒)
  </a>
</p>

---

## 一封給老玩家的信

還記得嗎?1993 年,《Simon the Sorcerer》(神通妙巫師)從英國 Adventure Soft 的工作室裡誕生。
那是點擊冒險遊戲的黃金年代——LucasArts 和 Sierra 打得火熱,而這個滿嘴刻薄話、活像少年版《黑爵士》的小巫師,
用它 320×200 的手繪場景和一句接一句的冷笑話,擠進了很多人的 5.25 吋磁片盒。

當年我們是怎麼玩的?一手滑鼠,一手翻著《電腦玩家》或《軟體世界》上零星的圖文攻略,
遇到「trip-trapping over my bridge」的巨魔、跟你大談「歧視」的蠹蟲、崇拜托爾金崇拜到中暑的咕嚕——
看得懂的笑一半,看不懂的猜一半。它的靈魂全在對白裡,而對白,是英文的。

這個專案,就是把那半場沒聽懂的笑話補完。

---

## 這一版做了什麼

<a name="features"></a>

先講最反直覺的一件事:**英文 CD 語音版,其實沒有完整字幕。**

當年 Adventure Soft 把 1993 floppy 版(純文字)加上語音做成 CD talkie 版時,為了塞進 170MB 的配音,
把大量對白的文字**從資料裡拿掉了**。ScummVM 的原始碼註解講得很白:

> `// English and German versions don't have full subtitles`

所以你若直接在 CD 版打開字幕,會看到**角色嘴巴在動、卻一個字都沒有**——不是 bug,是資料先天就缺了約四成。

這一版的解法是「融合」:

- **字幕**用 **1993 floppy 版的完整文字**當來源(每句都在),
- **語音**用 **CD talkie 版的英語配音**,
- 兩者用引擎腳本的行序對齊接起來。

於是你得到一個原版從來不存在的組合:**完整中文字幕 + 完整英語配音,還能一鍵切回英文對照。**

| 特色 | 說明 |
|---|---|
| **完整中文字幕** | 全劇 **4035 條**對白/物件/系統文字全數繁中,補足 CD 版缺的約四成 |
| **英語語音** | CD talkie 配音照舊播放(Chris Barrie 為 Simon 獻聲的原版聲線) |
| **中／英字幕切換** | 遊戲中按 **F8** 即時切換字幕語言,語音維持英語 |
| **640×480 高解析中文** | 沿用 ScummVM AGOS 引擎給 PC98 版的雙層畫布機制:遊戲照舊在 320×200 邏輯層跑,中文字幕/面板另畫在 640×400 高解析疊層——字清晰、相對變小、不再擠成一團 |
| **操作選單繁中** | 動詞列(走到/查看/使用⋯)中文化,直接畫進高解析層 |
| **防拷 bypass** | 開場的「唸咒防拷」自動填答,免翻手冊 |
| **不動遊戲原檔** | 全部透過 patch ScummVM 引擎達成 |

![片頭中文字幕 montage](docs/img/intro_montage.png)

*(片頭魔術秀,中文字幕在 640×400 高解析疊層即時渲染,底部為中文動詞面板;"Created and Designed by…" 等製作名單是遊戲的 VGA 美術圖,屬另議範圍。)*

---

## 那些你當年沒看懂的笑話,現在補上了

神通妙巫師的價值,九成在對白——尤其是對**托爾金**的致敬與吐槽,是全劇最好笑的部分。這一版把整場戲都翻了,舉幾段當年最經典的:

**托爾金迷**——森林洞穴裡一群 cosplay 成哈比人的「托爾金鑑賞協會」,一個扮成咕嚕、曬到中暑的傢伙在釣魚。你若敢問「托爾金是誰?」,換來暴怒:

> 「托爾金是有史以來最偉大的作家!你總聽過《手指飾品之王》吧?那《毛腳矮人》呢?」

*(Lord of the Finger Ornaments = 魔戒;The Short Man with Hairy Feet = 哈比人——連書名都在惡搞。)*

而惹毛森林女巫時,她拔劍喊出的經典台詞:

> 「以托爾金的神聖鬍鬚之名,準備受死吧!!!」
> *(By the sacred beard of J.R.R. Tolkien, prepare to DIE!!!)*

**巨魔橋**——一隻按劇本演出的巨魔,和一隻不想再被頂進河裡的比利山羊,吵起了勞資糾紛:

> 「在我得到滿足之前,任何人都不得通過這座橋。」
> 「你走運了,我正好是個到處推銷滿足的業務員。」

**會說話的蠹蟲**——你一句「抱歉,在我來的地方蠹蟲不會說話」,換來一整套控訴:

> 「這就是歧視——第三級的!你們這些該死的人類都一個樣。」

**巫師小子入門包**——花三十枚金幣入會當巫師,拿到的是⋯

> 「一枝巫師小子羽毛筆、巫師小子卷軸信紙⋯全裝在這個免費的巫師小子錢包裡。」

英式冷笑話的節奏、故意的無厘頭、對《魔戒》《睡美人》《傑克與魔豆》的惡搞,都盡量照原味譯出。

![字幕自動換行特寫](docs/img/subtitle_wrap.png)

*(字幕渲染特寫:長句自動按全形字寬換行——「你知道嗎 我可／是完全自學的」拆成兩行。)*

---

## 遊戲畫面(實際遊玩)

以下是 **640×480 高解析下實際遊玩**的畫面。滑鼠移到場景物件上,會即時顯示中文物件名(此處為「神祕掛毯」);底部動詞面板全程中文,懸停該格會反白:

![巫師書房——神祕掛毯](docs/img/hero_scene.png)

*(巫師書房:壁爐、會說話的魔鏡、通往花園的拱門;左下角「神祕掛毯」是懸停物件名,底部「走到/查看/打開/拿起/關上/使用/交談…」為中文動詞面板。)*

走出書房、來到魔法世界的鄉間,場景一樣是 640×480 高解析,中文物件名與動詞面板同樣清晰:

![草屋前的西蒙](docs/img/gameplay_cottage.png)

*(巫師小屋外的花園——懸停顯示「小屋後方」;天空、遠山、花叢都是原版 VGA 美術,中文疊層畫在上方不影響畫面。)*

---

## 影片旁白

▶ **影片已上線:[youtu.be/TTQcoItbF38](https://youtu.be/TTQcoItbF38)**

下面是這支短片的旁白(約 80 秒):

**【0:00–0:10 開場】**
1993 年的《神通妙巫師》是款讓你笑到肚子疼的英式冒險遊戲。三十年後,我們終於用繁體中文把它完整還原了——而且是原版從未有過的方式。

**【0:10–0:25 遊戲介紹】**
故事跟著十二歲男孩西蒙、一隻狗奇皮和一本《古老魔法書》展開。英國編劇筆下的台詞妙語如珠,每個角色都有話要說,滿是對傳奇文學和流行文化的惡搞。

**【0:25–0:42 CD 版的老毛病】**
但原版 CD 版有個問題。為了容納 170MB 的英文配音,開發者從資料檔裡砍掉了約四成字幕。所以你買的是完整配音,卻常常看到角色嘴巴在動、螢幕上一個字都沒有。

**【0:42–1:01 融合方案】**
我們換個辦法:拿軟磁片版完整的文字,配上 CD 版的英語配音,用引擎把兩者對齊。結果是全劇 4035 條對白全數繁中。按 F8 即時切換中英字幕——語音始終保持英文。

**【1:01–1:22 托爾金笑話與收尾】**
最有趣的是它對托爾金的惡搞。森林裡有群 cosplay 成哈比人的「托爾金鑑賞協會」,還有女巫拔劍大喝:「以托爾金的神聖鬍鬚之名,準備受死吧!」現在 Linux、Windows、Mac 都能玩,完整的故事在等你。

---

## 快速開始

需要:合法持有的《Simon the Sorcerer》**floppy 版**(提供完整文字+畫面)與 **CD 版的 `SIMON.VOC`**(提供語音)。

```bash
# 遊戲目錄需含: floppy 遊戲檔 + CD 的 SIMON.VOC + 三個 CHT 資產
#   simon_zh24.dcjk  simon_zh.tab  simon_voice.map
# 然後任一方式啟動:

# A) AppImage(已打包好的繁中 ScummVM)
./dist/SimonTheSorcerer-CHT-x86_64.AppImage -p /你的遊戲目錄 --auto-detect

# B) 本機腳本
bash scripts/play.sh
```

遊戲中 **F8** 切換中/英文字幕。

---

## 從原始碼重建(全 docker,不污染主機)

```bash
bash scripts/build_font.sh                                   # 烘 24×24 Big5 點陣字型
python3 tools/build_translation.py translations/zh.tsv fonts/simon_zh.tab   # 編譯譯表
bash scripts/build_scummvm.sh                               # 編譯 patched ScummVM(只啟 agos)
bash scripts/build_appimage.sh                              # 打包 AppImage
```

floppy 完整資料若只有安裝磁片(壓縮的 `GAME.RED`),用 `scripts/floppy_install_dosbox.sh`
在容器內以 DOSBox 自動跑原版安裝程式解出。

---

## 技術深潛

<a name="tech"></a>

這不是一般 ScummVM 中文化。SCUMM 引擎內建 CJK 基礎設施,補幾十行就能接;
AGOS 引擎**零 CJK 基礎**,且螢幕文字散在 6 個地方、分兩套渲染,還得先解決「英文版字幕缺四成」的資料問題。

核心架構(詳見 [`docs/FUSION_DESIGN.md`](docs/FUSION_DESIGN.md)):

- **以 floppy 為底**:字幕文字原生完整,零缺口。
- **注入以「行的身分」為 key**(floppy stringId),而非比對英文字串——這樣「有語音、無文字」的行也掛得上字幕。前一版用英文比對,天生救不了那些行。
- **對齊用引擎自己的反組譯器**:dump floppy 與 CD 兩版腳本,在文字 opcode 按位置配對 `speechId ↔ floppy 文字`(1655 子程式 1:1 對齊)。
- **語音注入**:floppy 版本無 talkie,patch 使其載入 CD `SIMON.VOC`,於對白 opcode 依對映播放對應語音。
- **CJK 24×24 渲染**:加大 AGOS 字幕文字緩衝(6400→40000 bytes)以容納全形字;視窗文字(動詞列/物件名)走獨立的 surface 繪字路徑。
- **硬編碼 UI**:動詞列(`verb.cpp`)、存讀檔訊息(`saveload.cpp`)在原始碼加 `ZH_TWN` 分支;防拷用引擎內建的 `_copyProtection=false` 自動填答路徑。

engine patch 新增 `engines/agos/cht_fusion.{h,cpp}`,並改動 `agos.cpp`、`string.cpp`、`charset.cpp`、`charset-fontdata.cpp`、`verb.cpp`、`saveload.cpp`、`event.cpp`、`res.cpp`。基準:ScummVM v2.9.1。

---

## 文件索引

| 文件 | 內容 |
|------|------|
| [PLAN.md](PLAN.md) | 完整中文化範圍、渲染策略、分階段計畫 |
| [strings/scope.md](strings/scope.md) | 權威翻譯範圍:6 類文字來源與驗收基準 |
| [docs/FUSION_DESIGN.md](docs/FUSION_DESIGN.md) | 融合架構:CD 語音 + floppy 字幕 + 中英切換 + 對齊實測 |
| [docs/LOCALIZATION_DIFFICULTY.md](docs/LOCALIZATION_DIFFICULTY.md) | 中文化難度討論:為何 AGOS 比一般 ScummVM 難 |
| [docs/COMPARISON.md](docs/COMPARISON.md) | 與前一版(deepseek+glm 產出)的逐項差異 |
| [docs/PREVIOUS_REPO_POSTMORTEM.md](docs/PREVIOUS_REPO_POSTMORTEM.md) | **前一版失敗分析**:六個症狀、一個根因、教訓對照 |
| [docs/PROMO_VIDEO_PLAN.md](docs/PROMO_VIDEO_PLAN.md) | **宣傳影片拍攝計畫**:三段 pipeline、分鏡、配樂(原版)、CPU-safe 骨架 |
| [docs/ANNOUNCEMENT.md](docs/ANNOUNCEMENT.md) | **介紹文案 / 貢獻說明**(含托爾金笑話,可直接發布) |
| [WORKLIST.md](WORKLIST.md) | 工作清單與進度 |

---

## 專案結構

```
simon-1-cht-claude/
├── translations/zh.tsv          # 繁中譯表(floppy id → 中文,4035 條)
├── fonts/                       # simon_zh24.dcjk / simon_zh.tab / simon_voice.map
├── build/scummvm-src/           # patched ScummVM(engines/agos/cht_fusion.*)
├── dist/                        # SimonTheSorcerer-CHT-x86_64.AppImage
├── tools/                       # 抽取 / 對齊 / 字型 / 譯表工具
├── scripts/                     # docker build / DOSBox 安裝 / dump / 截圖 / 打包
├── strings/ docs/               # 範圍、對齊資料、設計與難度文件
└── screenshots/                 # 驗證截圖
```

---

## 致謝

- **Adventure Soft** — 創造了這款經典。
- **Chris Barrie**(《紅矮星號》Rimmer)— 為 Simon 獻聲。
- **ScummVM 團隊** — 跨平台引擎與 AGOS 支援。

## 版權

- 遊戲《Simon the Sorcerer》版權屬 Adventure Soft 所有。
- ScummVM 以 GNU GPLv3 授權;本專案的 patch、工具與翻譯以 GNU GPLv3 發布。
- 本專案**不含**原始遊戲檔案,使用者需自行合法持有 floppy 與 CD 版。
