/* Simon the Sorcerer 繁體中文化 (CD 語音 + floppy 完整字幕 融合) — 非上游模組。
 * 資料: simon_zh24.dcjk (Big5 24x24 點陣), simon_zh.tab (id→Big5 譯表),
 *       simon_voice.map (floppy stringId→CD speechId 語音對映)。
 */
#ifndef AGOS_CHT_FUSION_H
#define AGOS_CHT_FUSION_H

#include "common/scummsys.h"
#include "common/hashmap.h"
#include "common/str.h"

namespace AGOS {

// Big5 線性索引 (與 build_cjk_font.py 對齊): (lead-0x81)*157 + trailOffset
inline bool chtIsBig5Lead(byte c) { return c >= 0x81 && c <= 0xFE; }

inline int chtBig5Index(byte lead, byte trail) {
	if (lead < 0x81 || lead > 0xFE)
		return -1;
	int to;
	if (trail >= 0x40 && trail <= 0x7E)
		to = trail - 0x40;
	else if (trail >= 0xA1 && trail <= 0xFE)
		to = 63 + (trail - 0xA1);
	else
		return -1;
	return (lead - 0x81) * 157 + to;
}

struct ChtFusion {
	// 字型
	byte *font = nullptr;      // DCJK glyph 區起點 (跳過 15-byte header)
	int fontW = 0, fontH = 0, fontBpr = 0;
	uint32 numGlyphs = 0;
	// 譯表: floppy stringId -> Big5 字串
	Common::HashMap<uint32, Common::String> table;
	// 語音: floppy stringId -> CD speechId
	Common::HashMap<uint32, uint16> voice;

	bool fontLoaded() const { return font != nullptr; }
	bool hasTable() const { return !table.empty(); }

	// 取得某 Big5 字的 glyph bitmap (fontBpr*fontH bytes), 找不到回 nullptr
	const byte *glyph(byte lead, byte trail) const {
		if (!font) return nullptr;
		int idx = chtBig5Index(lead, trail);
		if (idx < 0 || (uint32)idx >= numGlyphs) return nullptr;
		return font + (uint32)idx * fontBpr * fontH;
	}
};

bool chtLoadFont(ChtFusion &fus, const char *filename);
bool chtLoadTable(ChtFusion &fus, const char *filename);
bool chtLoadVoiceMap(ChtFusion &fus, const char *filename);

} // namespace AGOS

#endif
