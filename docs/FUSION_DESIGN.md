# 融合設計 — CD 英語語音 + Floppy 完整字幕 + 中/英字幕切換

> 目標(使用者指定):以 **CD talkie 版**為底(英語語音 + 畫面 + 帶 speechId 的腳本),
> 字幕文字改用 **floppy 版的完整文字**(每句都有字),並提供**中文 / 英文字幕即時切換**;**語音固定英語**。
> 這是「嘴巴在動、沒有文字」問題的正解:CD 英文版資料本身字幕不全(`agos.cpp:695` 官方註解),
> floppy 版(1993 純文字、無語音)則字幕完整。

---

## 1. 為什麼非得引入 floppy 文字

- CD 英文版:部分配音行在資料裡 `stringId==0xFFFF` 或空字串 → 顯示判斷式(`script_s1.cpp:377`)不成立 → 只有嘴動、沒有字。查表替換也救不了(**沒有英文原文可比對/替換**)。
- floppy 版:pre-talkie,每句對白都有文字。把它當「字幕的權威來源」,CD 的語音照放。

## 2. 核心設計轉折:字幕以「行的身分」為 key,不用英文原文比對

- **前人做法**(要淘汰):`translateInPlace` 拿螢幕上的英文字串去查表換中文。→ 語音-only 行**沒有英文字串**,天生無解。
- **融合做法**:建一份**字幕資料庫**,以行的身分為 key、值為 `{EN, ZH}` 兩種文字:
  - 有語音的行 → key = `speechId`(唯一對應一段語音 clip)。
  - 純旁白/無語音行 → key = `stringId`。
  - 顯示時依 key 取 EN 或 ZH,**即使 CD 原本沒有文字也能掛上字幕**。

## 3. 架構總覽

```
[離線 pipeline]                              [執行期 engine patch]
floppy GAME.RED ──解壓──▶ floppy 全文字         載入 subtitles.dat + CJK 24px 字型
   (GAMEPC + TEXT 表)         │                強制 _speech=true, _subtitles=true
CD 腳本 ──dump──▶ (stringId, speechId) 對照     opcode 162/177 顯示點:
   │                          │                  取行 key(speechId 優先, 否則 stringId)
   └────── 對齊 align ────────┤                  查 subtitles.dat[key] → 依 _subLang 取 EN/ZH
                              ▼                  顯示字幕(CD 空字串也照掛), 語音照放
                     subtitles.dat               F 鍵切換 _subLang ∈ {中, 英}(語音恆英語)
                     key → {EN, ZH}              渲染: 中=CJK 24px / 英=放大 ASCII, 於 640×400 畫布
```

## 4. 離線資料 pipeline

1. **抽 floppy 完整文字**:解壓 `GAME.RED`(RR 安裝格式)→ 得 floppy `GAMEPC`(字串表 + 腳本)+ TEXT 表 → 列出 floppy 全部字串(依 floppy stringId)。
   - 取得手段(擇一):① DOSBox 跑 `INSTALL.EXE` 安裝產生解壓後檔案(權威);② 逆向 "RR" 格式寫解壓器。
2. **抽 CD 行對照**:instrument CD 版 dump(opcode 162 `os1_screenTextMsg`、177 `os1_screenTextPObj`),記錄每個顯示點的 `(stringId, speechId)`,以及 CD 當下是否有文字。
3. **對齊 floppy 文字 ↔ CD 行**:
   - **快路徑**:若 floppy 與 CD 的 `stringId` 空間相同(同一套遊戲 DB 編號)→ 直接 `stringId → floppy 文字`。
   - **穩健路徑**:若不對齊 → 用「CD 有文字的行(EN 內容比對)」錨定 `speechId ↔ floppy 行`,其餘語音-only 行以播放順序/內容補齊 → 產 `key → EN`。
   - ⚠ **先驗證對齊方式**(§6),決定走哪條。
4. **翻譯 EN → ZH**:分母 = floppy 完整文字(比前人大、且完整)。
5. **產 `subtitles.dat`**:`key → {EN Big5/ASCII, ZH Big5}`;工具 `tools/build_subtitles.py`。

## 5. 執行期 engine patch(重寫,不引用前人 code)

- **初始化**:載入 `subtitles.dat` + `simon_zh24.dcjk`;`_speech=true; _subtitles=true`(語音+字幕都開)。
- **字幕解析 hook**:在 `os1_screenTextMsg` / `os1_screenTextPObj` 顯示前:
  - 算 key(有 `speechId` 用 speechId,否則 stringId)。
  - `txt = subtitles[key][_subLang]`;放寬顯示條件,使 `stringPtr` 為空但 subtitles 有值時仍顯示。
  - 語音維持 `playSpeech(speechId)`(英語)。
- **切換鍵**:一個鍵(暫定 F8;沿用前人 event.cpp:558 攔截點)循環 `_subLang ∈ {ZH, EN}`;語音不動。
- **渲染**(接續已定的 rule 81 決策:640×400 畫布 + 底圖 nearest 放大):
  - 中文:CJK 24×24 點陣。
  - 英文:原 6×8 ASCII 在 640 畫布會過小 → 英文字幕用 **2× 放大 ASCII**(或 12×16)保持可讀。
  - 換行:中文按 24px 全形重算,英文按放大後半形重算。
- **buffer 上限**:原 `getStringPtrByID` 用 180 bytes;floppy 長對白 + Big5(每字 2 bytes)可能超限 → 字幕解析改走獨立 buffer,不受 180 限制。

## 6. 必先驗證(讓計畫從假設變確定)

1. **floppy vs CD stringId 是否對齊**:解出 floppy GAMEPC 字串表後,取數條已知 CD 文字比對同 id 的 floppy 文字是否為同句 → 決定 §4.3 快/穩健路徑。
2. **語音-only 規模**:CD dump 統計 `speechId!=0 && (stringId==0xFFFF || CD 文字空)` 的行數 → 確認 floppy 補字的量。
3. **speechId ↔ floppy 行可對齊性**:確認每個 CD speechId 都能對到一句 floppy 文字。

## 7. 對既有文件的影響

- `PLAN.md`:專案目標升級為「融合版(語音+完整字幕+中英切換)」;翻譯分母改為 floppy 完整文字。
- `strings/scope.md`:B 類(對白)來源從「CD GME 部分文字」改為「floppy 完整文字」;新增「語音-only 行」與「字幕語言切換」項。
- 硬編碼 UI(動詞列 D、存讀檔 E)仍需 source `ZH_TWN` 分支(不變);英文字幕模式下這些也要能顯示英文(原生即是)。

## 8. 實測發現(2026-07-02,已解出完整 floppy)

用 docker DOSBox 自動跑 `INSTALL.EXE` 解出完整 floppy(`original_game_floppy/installed/`),實測:

| 項目 | floppy(完整) | CD(現況) | 結論 |
|---|---|---|---|
| GAMEPC 字串表(id<0x8000) | **694** | 368 | CD 少 326 條 |
| 對白(id>=0x8000) | **3342**(去重 ~2407) | ~1461 | CD 少約 900+ 條 |
| SIMON.VOC 語音 clip | — | **~3624** | 與 floppy 文字數同級 |
| `TBLLIST` | ← 兩版 **byte 完全相同** → | | **腳本/子程式結構一致** |
| `STRIPPED.TXT` | 不同 | 不同 | 對白 id 範圍不同 |
| 字串表 id 順序 | id0=`Pink splodge` | id0=`Witch's Cottage` | **短字串 id 不對齊** |

**推論**:CD 版砍掉約 40% 文字 → 「嘴動無字」的規模;floppy 是完整字幕唯一來源(已抽成 `strings/floppy_text.tsv`,4036 條 id→text)。

### 對齊現實與策略(定稿)

- floppy 與 CD 的 **stringId 不對齊**(字串表順序不同、對白 id 範圍不同)→ 不能用 id 直接對映。
- 但 **TBLLIST 相同 → 兩版子程式/腳本結構一致 → 對白出現順序一致**。
- **對齊做法(穩健,採用)**:平行走訪 floppy 與 CD 的 GAMEPC/TABLES 子程式,於每個文字 opcode(o_screenTextMsg / o_screenTextPObj)配對:
  - floppy 端取 `stringId_floppy` → floppy 完整文字
  - CD 端取 `stringId_cd` + `speechId`
  - 配成 `speechId ↔ floppy 完整文字`(以及 `stringId_cd ↔ floppy 文字`)
  - 需實作 AGOS 子程式 bytecode parser(item array + subroutine + opcode operand 編碼)。
- 由此產出 `subtitles.dat`:`speechId → {EN(floppy), ZH}` 與 `stringId_cd → {EN, ZH}`。

### 對齊實測結果(引擎 disassembler dump 兩版腳本,`tools/align_subtitles.py`)

- floppy 與 CD **子程式按 ID + PRINT_STR 位置 1:1 對齊**(1655 共同 sub,僅 34 結構不符)。
- 配對 2611 條 PRINT_STR(opcode 162):**CD 有 2609 條是 NULL_STRING(voice-only,無字幕)**——CD 角色對白幾乎全無字幕,證實「嘴動無字」普遍。
- CD 有字的 2 條與 floppy **完全一致**(0 mismatch)→ 位置對齊正確。
- speechId=9999 是「無語音」哨兵(旁白/過場,如三隻山羊 sub 1022),531 條;真實 speechId 唯一。
- 產出:`strings/speech_to_floppy.tsv`(2075:speechId→floppy 文字)、`strings/floppy_to_speech.tsv`(1807:floppy id→speechId,voiced)。

### 架構定案(修正):**以 floppy 為底 + 注入 CD 語音**

改採 floppy 為底,因它**原生保證字幕 100% 完整**(含旁白/過場),直接守住使用者第一優先。

- 底:**floppy 版**(原生完整文字 + 圖 + 腳本)。字幕文字全部原生可顯示,無缺口、無需位置追蹤。
- 翻譯:直接翻 `strings/floppy_text.tsv`(floppy id→text,4036 條)→ ZH。
- 字幕語言切換:F 鍵 `_subLang ∈ {中,英}`;英=原生 floppy 文字,中=譯表。
- 語音(次要):floppy 版本無 talkie,patch 使其載入 CD 的 `SIMON.VOC`;於 opcode 162 用 `floppy_to_speech.tsv` 查 speechId → `playSpeech`(英語)。重用台詞 270 處可能配錯語音,**不影響字幕正確**(可日後以 (sub_id, opcode offset) 精準化)。
- 渲染:中=CJK 24×24 / 英=放大 ASCII,於 640×400 畫布(rule 81)。

> 對比:若以 CD 為底,534 條 speechId=9999 旁白因無 key 需 runtime 位置追蹤才顯示字幕(風險落在「字幕」這個優先項);floppy-base 把不完美推到「語音」次要項,較穩健。

## 9. 目前狀態

- [x] DOSBox 自動安裝解出完整 floppy(`original_game_floppy/installed/`,173 檔)
- [x] 抽出 floppy 完整文字 `strings/floppy_text.tsv`(694 字串表 + 3342 對白 = 4036)
- [x] 量化 CD 缺口(短字串 -326、對白 -900+)、確認 id 不對齊但 TBLLIST 相同
- [ ] 抽 CD 完整 id→text(同法,從 SIMON.GME)
- [ ] 實作 AGOS 子程式 parser → 平行對齊產 `subtitles.dat`(speechId↔floppy 文字)
- [ ] 引擎 patch(字幕解析 hook + 中英切換 + 640×400 + CJK 24px)
- [ ] 翻譯 floppy 完整文字 → ZH
- [ ] 硬編碼 UI(動詞列/存讀檔)ZH_TWN 分支
- [ ] 打包 + 實機驗證
