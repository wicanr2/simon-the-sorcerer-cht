# WORKLIST — 魔法師西蒙 繁中融合中文化

> 狀態:`[ ]` 待辦 / `[~]` 進行中 / `[x]` 完成。以 code 與實機為真相,不以自我標記為準。

## 第一階段:範圍與資料(完成)
- [x] 用 AGOS 原始碼釐清完整中文化範圍(6 類來源 / 2 渲染體系)→ `strings/scope.md`
- [x] 診斷前一版問題:動詞列硬編碼未翻、CD 字幕不全、假 16px 字型
- [x] DOSBox 自動安裝解出完整 floppy 資料
- [x] 抽出 floppy 完整英文母本 4036 條 → `strings/floppy_text.tsv`
- [x] 用引擎反組譯器對齊 floppy↔CD 腳本 → `speech_to_floppy` / `floppy_to_speech`
- [x] 烘 24×24 Big5 點陣字型 → `fonts/simon_zh24.dcjk`(驗證字形正確)

## 第二階段:引擎 patch(核心完成,已實機驗證)
- [x] cht_fusion 模組(字型/譯表/語音對映載入、Big5 索引)— 編譯通過
- [x] `getStringPtrByID` 依 floppy id 注入 Big5 譯文
- [x] `chtRenderStringCJK` 字幕 24px 繪製 + 加大文字緩衝(6400→40000)
- [x] 完整 floppy 資料就位(VGA 全解,325 檔)+ **實機驗證中文字幕**(片頭多行 CJK 正確渲染)
- [x] `windowPutChar` / `chtDrawBig5OnSurface` 視窗文字 CJK(物件名/動詞列,前進 3 欄)
- [x] 中 / 英字幕切換(F8 `_chtSubLang`)
- [x] CD 語音注入(floppy 載入 SIMON.VOC + `simon_voice.map` 播 speechId,只播音不做 talkie 動畫)— **語音+字幕共存不崩**
- [x] 動詞列 `verb.cpp` 加 `cht_verb_names[]` + ZH 分支
- [ ] 存讀檔 `saveload.cpp` 加 `ZH_TWN` 繁中分支(後續)

## 第三階段:翻譯(完成)
- [x] `translations/zh.tsv`:**全部 4035 條翻譯完成**(字串表 693 + 對白 3342),0 非-Big5 字
- [x] 優先序:動詞列(source)/物件名/短句 → 全劇對白
- [x] 驗收:未翻 id 歸零(comm 比對 all_ids 全覆蓋)

## 第四階段:打包與驗證
- [x] 實機驗證:字幕 CJK ✓、語音+字幕共存不崩 ✓
- [x] 完整譯表已編入 `fonts/simon_zh.tab` + `run_floppy/`(可執行)
- [ ] Linux AppImage 打包(floppy 資料 + CD 語音 + CHT 資產)— 後續
- [ ] 存讀檔 saveload.cpp ZH_TWN 分支 — 後續
- [x] 與前一版差異比較 → `docs/COMPARISON.md`

## 文件
- [x] PLAN.md / scope.md / FUSION_DESIGN.md / LOCALIZATION_DIFFICULTY.md / README(索引)
