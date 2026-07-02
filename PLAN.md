# PLAN — 魔法師西蒙(Simon the Sorcerer 1)繁體中文化(接手重做)

> 本專案接手前一版(`~/scummvm/simon-1`,deepseek + glm5.2 產出)。前一版問題不在翻譯文筆(抽樣品質其實不錯),
> 而在**沒有先把「中文化範圍」對齊引擎的真實文字模型就開工**,導致覆蓋不完整、方法有結構性盲點。
> 本 PLAN 的第一要務:用 ScummVM AGOS 原始碼當 oracle,把**完整、權威的中文化範圍**定義清楚,再談實作。
>
> 工作目錄:`~/scummvm/simon-1-cht-claude`(對應 repo `simon-the-sorcerer-cht.git`)。舊資料夾只讀不改。
> 所有斷言附「檔案:行號」證據,證據根目錄:`scummvm-src/engines/agos/`。

---

## 0. 第一性原理:中文化到底要換掉哪些字?

「遊戲中文化 = 把螢幕上出現的每一個英文字,換成中文字並正確畫出來。」

要做到「完整」,必須先回答兩個引擎層問題,而不是憑檔案 `strings` 掃出來的字面猜:

1. **這個字從哪讀出來?**(來源 / provenance)——決定它能不能被「查表替換」攔到。
2. **這個字最後怎麼畫到螢幕?**(渲染路徑)——決定要 patch 哪個繪字函式才畫得出中文。

前一版只處理了「經過 `getStringPtrByID()` 查表替換」這**一條**路徑,就宣告完成。實際上 Simon 1 的螢幕文字有
**6 大來源、2 大渲染體系**,其中至少 3 類**根本不經過那條路徑**,因此無論翻譯表多完整都不會變中文。

---

## 1. 完整中文化範圍(權威枚舉)

下表是本專案的**翻譯分母定義**。每一列都要在最終驗收時確認「已中文化 / 已知不做(附理由)」。

| # | 螢幕文字類別 | 來源(provenance) | 讀取/渲染證據 | 能否靠「查表替換」攔到 | 前一版狀態 |
|---|---|---|---|---|---|
| A | 物品名、房間名、短提示 | **GAMEPC 內建字串表**(`stringId < 0x8000`,索引 `_stringTabPtr`) | `res.cpp:107-142` 讀表；`string.cpp:131-136` 分流；`string.cpp:470-490` `printNameOf` | ✅ 可(走 `getStringPtrByID`) | 部分翻 |
| B | 對白字幕、旁白 | **SIMON.GME 內 TEXT02–TEXT30**(`stringId >= 0x8000`,按需分頁載入) | `string.cpp:172-192` `getLocalStringByID`；`:322-369` `loadTextIntoMem`;STRIPPED.TXT 為索引 | ✅ 可(走 `getStringPtrByID`) | 部分翻(~880/~1461) |
| C | 物品欄描述(右鍵 examine) | A 或 B | `script_s1.cpp` `os1_screenTextPObj`(opcode 177)→ `printScreenText` | ✅ 可 | 部分翻 |
| **D** | **動詞列 Walk to / Look at / …** | **引擎硬編碼 C 陣列** `english_verb_names[]` | `verb.cpp:123-136`(名)、`:189-193`(介系詞)、`:255-323` `printVerbOf` 依 `_language` 選陣列,**無 ZH_TWN** | ❌ **不經 `getStringPtrByID`**,查表攔不到 | **未做**(zh.tsv 有譯但為死條目) |
| **E** | **存/讀檔系統訊息**(Save failed / Disk error / File already exists / Overwrite it? / Yes No …) | **引擎硬編碼** | `saveload.cpp:930-1013` `fileError`(各語言 switch,**無 ZH_TWN**);`:225-266` 覆寫確認訊息 | ❌ 硬編碼,查表攔不到 | **未做** |
| **F** | 片頭 logo / 片尾 credits / 面板美術上的字 | **VGA 預繪點陣圖**(美術資源,非文字系統) | `intro`/`credits` 在 agos 全域僅命中 PN 引擎;Simon1 片頭是 VGA sprite 腳本 | ❌ 不經任何文字函式 | 未做(需改美術,或明確標「不做」) |

### 各來源的真實數量(權威分母)

- **A. GAMEPC 字串表 = 368 條**(權威值:GAMEPC 檔頭第 4 個 `UInt32BE` = `stringTableNum`;`res.cpp:118` + 實測檔頭 `00 00 01 70` = 368)。
  - ⚠ 前一版 `strings/gamepc_all_strings.txt` 有 1015 行、`still_untranslated.txt` 用 `0x1010`(=4112)這種 hex 當「ID」——**4112 遠超過 368 的索引上限**,證明那些 hex 是**檔案 offset,不是引擎的 string ID**。前一版的枚舉從一開始就沒對齊引擎的 ID 空間。
- **B. GME 對白 ≈ 1461 條**(前一版萃取去重估計;本專案將以 runtime dump 精確化,見 §3.1)。
- **C.** 併入 A/B 計算。
- **D. 動詞 12 個 + 介系詞 2 個 = 14 條**(`verb.cpp:123-193`,有限且固定)。
- **E. 系統訊息 ≈ 6–10 條**(`saveload.cpp` 硬編碼,有限)。
- **F.** 美術資源,不計入文字分母(範圍邊界,見 §5)。

> **權威翻譯分母 ≈ 368(A) + ~1461(B) + 14(D) + ~8(E) ≈ 1850 條可即時繪字文字**(F 另計)。
> 前一版聲稱「總計 1237 / ~1237 ✅ 完成」——分母 `~1237` 是**捏造**的,真實分母約 1850,且完全漏掉 D、E、F。

---

## 2. 兩大渲染體系(決定 patch 哪個繪字函式)

| 體系 | 用途 | 入口 → 繪字函式 | 畫布 |
|---|---|---|---|
| **一、VGA sprite 字幕疊圖** | 對白 / 旁白 / 物品描述(B、C) | `printScreenText`(`string.cpp:495`)→ `renderString`(`charset-fontdata.cpp:1206`)→ 寫進 `vgaFile2` sprite buffer,`animate` 疊圖 | 320×200 |
| **二、即時繪字到 surface** | 動詞列 / 物品名 / 存讀檔選單(A、D、E) | `windowPutChar`(`charset.cpp:236`)→ `windowDrawChar`(`charset-fontdata.cpp:2983`)直接畫到 backend surface | 320×200 |

- ASCII 字型本身也是**硬編碼點陣** `english_simonFont[]`(`charset-fontdata.cpp:1468`,每字 w=6 h=8)。
- 兩體系都要有 CJK 分支才畫得出中文;前一版兩條都改了(`renderStringCJK` / `windowDrawChar` override),**渲染管線本身是通的**——這不是前一版的問題所在。

---

## 3. 前一版三個結構性缺陷(本專案要修正的重點)

1. **範圍未對齊引擎 ID 空間**:枚舉用檔案 offset 當 ID(§1),沒用引擎真實的 368 字串表 + 0x8000+ 對白模型,導致覆蓋率無從驗證,漏譯一大片(`still_untranslated.txt` 尚有大量條目)。
2. **完全漏掉「不經查表」的硬編碼文字(D、E)**:動詞列「Walk to…」與存讀檔訊息寫死在 `verb.cpp` / `saveload.cpp`,`getStringPtrByID` 的查表注入碰不到 → 玩家看到的操作選單永遠是英文(**使用者已實測回報**)。正解是在**原始碼**加 `Common::ZH_TWN` 分支,提供 `cht_verb_names[]` 等 Big5 陣列。
3. **CJK 字太小 + 假字型**(違反 retro CJK 鐵則):
   - `simon_zh16.dcjk` 與 `simon_zh12.dcjk` **byte 完全相同**,檔頭都是 `w=12 h=12`——宣稱的「16×16 大字對白」是假的,實際只有 12×12。
   - 12×12 中文筆畫糊成一團、幾乎不可讀。retro CJK 正解是**拉高內部畫布、用正常字級(24×24)**,不是把中文縮小塞進原本 6×8 的小字位。

---

## 4. 渲染策略(rule 81:拉高畫布,別縮字)

**鐵則**:老遊戲低解析(320×200)做 CJK,不縮字塞小位;拉高內部畫布 + 底圖 nearest 放大 + 中文用正常字級。

- **目標(建議)**:內部畫布 320×200 → **640×400(乾淨 2× 整數放大)**,原始 VGA 背景/sprite 用 nearest-neighbor 放大保持銳利,CJK 以 **24×24** 繪製,字幕/動作列自動換行按 24px 全形重算。
  - AGOS 具備高解析先例:`AGOSEngine_Feeble`(Feeble Files)本身跑 640×480,引擎有高解析 plumbing 可借鏡。
  - 座標重映射:hit-area、滑鼠命中、window 座標需一併 ×2(§4 gotchas:raw 座標 widget 與滑鼠 hit-test 要同步)。
- **fallback(若 640 畫布改動風險過高)**:維持 320×200,CJK 以 **16×16** 繪製(Big5 可讀下限,經典 SCUMM/AGOS 中文化慣用值),靠 ScummVM 後端放大到大視窗。**16×16 不算違反鐵則**(它比原版 6×8 大,非「縮小塞小位」);**12×12 才是要淘汰的錯誤**。

> 這是本專案唯一需要使用者拍板的取捨(fidelity ↔ 工作量/風險)。實作前會單獨確認;預設走「640×400 + 24×24」。

---

## 5. 範圍邊界(明確標示,不含糊帶過)

- **F 類(片頭 logo / credits / 美術上的字)**:屬 VGA 預繪點陣圖,需改美術資源而非改字串。依「完整性 > 投報」原則**不預先砍**,列為獨立階段(P6),先做完 A–E 的全文字中文化,再評估美術改圖;真的當下不做也要誠實標「未完成 + 具體方法」,不寫「低投報」。
- 語音(SIMON.VOC / EFFECTS.VOC):英文語音保留,不在中文化範圍(中文化 = 字幕);CJK 模式強制開字幕(`loadCJKFont` 設 `_subtitles=true`)。

---

## 6. 分階段工作計畫

> 每階段結束更新 `WORKLIST.md`;狀態以「code 為真相」驗證,不信自我標記(避免重蹈前一版「自稱完成」)。

### P0 — 環境與 baseline(docker)
- [ ] 取乾淨 ScummVM 原始碼(不沿用被前人 patch 過的 `~/scummvm/simon-1/scummvm-src`,避免污染),docker build 只啟用 `--enable-engine=agos`。
- [ ] 確認原版(未 patch)可跑 Simon 1 CD 版,建立截圖 baseline。

### P1 — 建立權威範圍(最重要,對應本 PLAN §1)
- [ ] 靜態:確認 A=368 條字串表;解析 STRIPPED.TXT / TBLLIST 對應 TEXT02–TEXT30,列出 B 的檔案切分與各檔條數。
- [ ] 動態:實作/沿用 `getStringPtrByID` 的 dump 機制(`CHTMISS`),**跑一輪完整遊玩(或用既有存檔逐場景)**,把引擎實際請求過的每一條字串(含 A+B+C)以真實 buffer 內容為 key dump 出來 → 這就是 runtime 真實宇宙。
- [ ] 靜態:列出 D(verb.cpp:123-193)、E(saveload.cpp:930-1013 等)全部硬編碼英文字串。
- [ ] 產出 `strings/scope.md`:A/B/C/D/E/F 各類清單 + 條數 + 覆蓋機制,當作驗收基準。

### P2 — CJK 字型(24×24 真字型)
- [ ] `tools/build_cjk_font.py`(docker + freetype)烘 **真正的 `simon_zh24.dcjk`(24×24)**,Big5 線性索引(`(lead-0x81)*157 + trail_offset`)。
- [ ] 系統字型(Noto Sans CJK TC / 文泉驛),1bpp `FT_LOAD_TARGET_MONO`;docker 產出後修正檔案權限(前人踩過 root-owned 雷)。
- [ ] (若走 fallback)另烘 16×16。**不再產生假的重複字型檔**。

### P3 — 引擎 patch:高解析畫布 + CJK 兩體系繪字
- [ ] 依 §4 拉高內部畫布(640×400)+ 底圖 nearest 放大 + 座標/hit-test 重映射。
- [ ] 體系一 `renderStringCJK`:24×24 繪進(放大後)sprite buffer,換行按全形重算。
- [ ] 體系二 `windowDrawChar` override:24×24 Big5 雙位元組狀態機繪到 surface。
- [ ] `cjk_cht.{h,cpp}`:DCJK 載入、Big5 index、翻譯查表、`translateInPlace`、dump 模式(自己重寫,不引用前人 code)。
- [ ] `getStringPtrByID` 出口注入 `translateInPlace`(涵蓋 A+B+C)。

### P4 — 硬編碼 UI 的原始碼中文化(修正前人最大盲點)
- [ ] `verb.cpp`:`printVerbOf` 加 `case Common::ZH_TWN`,提供 `cht_verb_names[]` / `cht_verb_prep_names[]`(Big5)。
- [ ] `saveload.cpp`:`fileError` 及存讀檔確認訊息加 `ZH_TWN` 分支(Big5)。
- [ ] 存檔名輸入:確認玩家輸入/顯示在 CJK 模式下不破圖(必要時限定 ASCII 輸入)。

### P5 — 完整翻譯
- [ ] 以 P1 的 `scope.md` 為分母,建 `translations/zh.tsv`(UTF-8 TSV)。
- [ ] `tools/build_translation.py`:UTF-8 TSV → Big5 `.tab`;非 Big5 字元報警。
- [ ] 翻譯優先序:動詞列/系統訊息(D/E)→ 物品名/描述(A/C)→ 對白(B)。
- [ ] **驗收 = dump 模式跑到 `CHTMISS` 歸零**(而非自稱條數)。

### P6 — 美術文字(F 類)評估
- [ ] 盤點片頭/credits 圖片中的英文;評估改圖工作量;做或誠實標「未完成 + 方法」。

### P7 — 打包、實機驗證、比較
- [ ] Linux AppImage(+ Windows 跨編譯)。
- [ ] **實機正常玩家路徑驗證**(非只 headless 截圖):動詞列、對白、存讀檔、換行、F8 中英切換都要親眼確認中文。
- [ ] 產出 `docs/COMPARISON.md`:本專案 vs 前一版逐維度差異(範圍完整度、硬編碼 UI、字級、字型真偽、驗收方法)。

---

## 7. 安全鐵則

- 遊戲原始檔(`original_game/`、`*.GME`、`*.VOC`、ISO)**絕不進 git**。
- 只 push 工具、patch、`translations/`、`fonts/*.dcjk`(非版權字型 atlas)、docs。
- CJK 字型用系統字型烘製,不內嵌版權字型檔。
- 不直接複製前一版 / atlantis 的任何 engine code(可參考做法,重新實作)。
- 編譯一律走 docker;Python 一律 docker uv/venv,不污染系統。
- 驗收以 code 與實機為真相,不信任 WORKLIST 自我標記(前一版教訓)。
