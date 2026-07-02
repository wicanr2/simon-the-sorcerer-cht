# scope.md — Simon 1 中文化「權威範圍」與驗收基準

> 本文件是翻譯的**分母定義**。以 ScummVM AGOS 原始碼為 oracle,對齊引擎真實的文字模型(而非檔案 offset)。
> 驗收時逐類確認「已中文化 / 已知不做(附理由)」。證據根目錄:`scummvm-src/engines/agos/`。
> 分類代號與 `PLAN.md §1` 一致(A/B/C/D/E/F)。

---

## A. GAMEPC 內建字串表(物品名、房間名、短提示)

- **來源**:GAMEPC 檔,`stringId < 0x8000` → `_stringTabPtr[stringId]`。
- **條數(權威)= 368**。依據:GAMEPC 檔頭第 4 個 `UInt32BE` = `stringTableNum`(`res.cpp:118` 讀取順序 itemArraySize→version(0x80)→itemArrayInited→stringTableNum);實測檔頭 bytes `00 00 01 70` = 368。
- **覆蓋機制**:走 `getStringPtrByID`,可被 `translateInPlace` 查表替換。✅
- **渲染**:多數走「體系二」`windowDrawChar`(物品名經 `printNameOf`→`showActionString`);部分走「體系一」字幕。
- ⚠ 前一版把檔案 offset(如 `0x1010`=4112,遠超 368)當 ID,枚舉未對齊引擎 → 覆蓋率無法驗證。

## B. SIMON.GME 對白 / 旁白(TEXT02–TEXT30)

- **來源**:`stringId >= 0x8000` → `getLocalStringByID`(`string.cpp:172`)→ 必要時 `loadTextIntoMem`(`:322`)分頁載入 SIMON.GME 的 TEXTxx;STRIPPED.TXT 為檔名/範圍索引。`_textIndexBase = 1500/4`(`agos.cpp:819`)。
- **條數(估計)≈ 1461**(前一版萃取去重;**待 P1 動態 dump 精確化**)。
- **覆蓋機制**:走 `getStringPtrByID`,可查表替換。✅
- **渲染**:「體系一」`printScreenText`→`renderString(CJK)` 寫進 VGA sprite buffer。
- **精確化方法**:build 後開 dump 模式(`getStringPtrByID` 出口 log `CHTMISS`),用既有存檔逐場景 + 完整走一輪,收集引擎「實際請求過」的每一條 → 真實 runtime 宇宙。

## C. 物品欄描述(右鍵 examine)

- **來源**:A 或 B。**渲染**:`script_s1.cpp` `os1_screenTextPObj`(opcode 177)→ `printScreenText`(體系一)。
- **覆蓋機制**:走 `getStringPtrByID`。✅ 併入 A/B 計數。

## D. 動詞列(操作選單)— 引擎硬編碼 ❗前一版完全漏做

- **來源**:`verb.cpp:123-136` `english_verb_names[]`、`:189-193` `english_verb_prep_names[]`。`printVerbOf`(`:255-323`)依 `_language` switch 選陣列,**無 `ZH_TWN` → 落回英文**。
- **不經 `getStringPtrByID`**(`txt` 直接餵 `showActionString`)→ 查表替換攔不到。❌
- **正解**:`verb.cpp` 加 `case Common::ZH_TWN` + 新增 `cht_verb_names[]` / `cht_verb_prep_names[]`(Big5)。
- **清單(14 條)**:

  | idx | 英文 | 建議中文 |
  |----|------|---------|
  | 0 | Walk to | 走到 |
  | 1 | Look at | 查看 |
  | 2 | Open | 打開 |
  | 3 | Move | 移動 |
  | 4 | Consume | 吃/喝 |
  | 5 | Pick up | 拿起 |
  | 6 | Close | 關上 |
  | 7 | Use | 使用 |
  | 8 | Talk to | 交談 |
  | 9 | Remove | 脫下 |
  | 10 | Wear | 穿上 |
  | 11 | Give | 給予 |
  | prep[7] | with what ? | 要用什麼? |
  | prep[11] | to whom ? | 給誰? |

  (中文為初稿,實作時定稿。)

## E. 存/讀檔系統訊息 — 引擎硬編碼 ❗前一版完全漏做

- **來源**:`saveload.cpp` `fileError`(`:930-1013`,各語言 switch,**無 ZH_TWN**)+ 覆寫確認(`:247-251`)。
- **不經查表**。❌ **正解**:各處加 `ZH_TWN` 分支(Big5)。
- **清單(已知,約 8 條)**:
  - 存檔失敗:`"Save failed."` / `"Disk error."`(`:969-970`)
  - 讀檔失敗:`"Load failed."` / `"File not found."`(`:1009-1010`)
  - 覆寫確認:`"File already exists."` / `"Overwrite it ?"` / `"Yes       No"`(`:248-250`)
  - 存檔名輸入提示 / 選單標題:實作 P4 時在 saveload.cpp 全檔 grep 補齊。

## F. 片頭 logo / 片尾 credits / 面板美術上的字 — VGA 預繪點陣圖

- **來源**:美術資源(VGA sprite),**不經任何文字函式**。❌(改字串無效)
- Simon1 無 intro/credits 文字函式(`intro`/`credits` 在 agos 僅命中 PN 引擎)。
- **處理**:列 P6 獨立階段,盤點後評估改圖;依「完整性 > 投報」不預先砍,做不到也誠實標「未完成 + 方法」,不寫「低投報」。

---

## 驗收基準(replaces 前一版「自稱條數」)

| 類 | 分母 | 覆蓋機制 | 驗收方式 |
|---|---|---|---|
| A | 368 | 查表(getStringPtrByID) | dump 模式 `CHTMISS` 歸零 |
| B | ~1461(待動態精確化) | 查表 | dump 模式 `CHTMISS` 歸零 |
| C | 併 A/B | 查表 | 同上 |
| D | 14 | **原始碼 ZH_TWN 分支** | 實機看動詞列/介系詞為中文 |
| E | ~8 | **原始碼 ZH_TWN 分支** | 實機觸發存讀檔錯誤/覆寫看中文 |
| F | 美術(另計) | 改圖 | 實機看片頭/credits |

**核心原則**:驗收以「實機 + dump 歸零」為真相,不以翻譯表條數自稱完成(前一版教訓)。
