#!/usr/bin/env bash
# 魔法師西蒙繁中融合版 推廣片合成(CPU-safe 靜態+fade,不用 zoompan)
set -eu
# ===== 設計 token =====
BG='#2a1a4a'; BGD='#0c0818'; GOLD='#c9a227'; GOLDSH='#6b4e12'; CREAM='#f2ead2'; DIM='#a892d0'; BLOOD='#8c1c13'
FB=/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
FR=/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc
W=1280; H=720; FPS=25
SHOT=/shots; OUT=/out; MUS=/music; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"

# 標題卡: zh 中標 / en 英標 / sub 副標
card(){ local o=$1 zh=$2 en=$3 sub=$4
  convert -size ${W}x${H} "radial-gradient:#3a2668-${BGD}" \
    -font "$FB" -gravity center \
    -fill "$GOLDSH" -pointsize 96 -annotate +4+4 "$zh" -fill "$GOLD" -pointsize 96 -annotate +0-10 "$zh" \
    -font "$FR" -fill "$CREAM" -pointsize 46 -annotate +0+80 "$en" \
    -fill "$DIM" -pointsize 30 -annotate +0+150 "$sub" "$o"; }

# 對白卡: scene 場景標 / zh 中文台詞(自動換行) / en 英文原文
dcard(){ local o=$1 scene=$2 zh=$3 en=$4
  convert -size ${W}x${H} "gradient:${BG}-${BGD}" "$TMP/db.png"
  convert -background none -fill "$CREAM" -font "$FR" -pointsize 52 -size $((W-240))x -gravity center caption:"$zh" "$TMP/dz.png"
  convert "$TMP/db.png" \
    -font "$FB" -fill "$GOLD" -gravity north -pointsize 34 -annotate +0+70 "◆ $scene ◆" \
    "$TMP/dz.png" -gravity center -geometry +0+0 -composite \
    -font "$FR" -fill "$DIM" -gravity south -pointsize 26 -annotate +0+70 "$en" "$o"; }

# 截圖卡: 遊戲截圖加金框 + 底部說明
slide(){ local o=$1 sc=$2 cap=$3
  convert -size ${W}x${H} "gradient:${BG}-${BGD}" "$TMP/sb.png"
  convert "$SHOT/$sc" -filter point -resize x520 -bordercolor "$GOLD" -border 3 "$TMP/ss.png"
  convert "$TMP/sb.png" "$TMP/ss.png" -gravity north -geometry +0+40 -composite \
    -fill "#00000099" -draw "rectangle 0,632 ${W},720" \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 34 -annotate +0+28 "$cap" "$o"; }

# 靜態 + 淡入淡出(不用 zoompan!)
kb(){ local img=$1 o=$2 s=$3; local fo; fo=$(awk "BEGIN{print $s-0.6}")
  ffmpeg -y -loglevel error -loop 1 -i "$img" -t "$s" -r $FPS \
    -vf "fade=t=in:st=0:d=0.6,fade=t=out:st=$fo:d=0.6,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$o"; }

# ===== 分鏡 =====
card  "$TMP/00.png" "魔法師西蒙" "Simon the Sorcerer" "繁體中文化 · CD 語音 × 完整字幕"
dcard "$TMP/01.png" "問題" "英文 CD 版,其實沒有完整字幕。" "English CD version doesn't have full subtitles."
dcard "$TMP/02.png" "現象" "角色嘴巴在動,你卻一個字都看不到。" "The characters talk — but nothing appears on screen."
dcard "$TMP/03.png" "解法" "用 floppy 版完整文字,融合 CD 版英語配音。" "Floppy's complete text + CD's English voice, fused."
slide "$TMP/04.png" sc_hero.png       "完整中文字幕,一句不漏"
slide "$TMP/05.png" sc_hat.png        "24×24 點陣中文,自動換行"
dcard "$TMP/06.png" "巨魔橋" "你走運了,我正好是個到處推銷滿足的業務員。" "Luckily for you, I'm a travelling satisfaction salesman."
dcard "$TMP/07.png" "托爾金迷" "以托爾金的神聖鬍鬚之名,準備受死吧!!!" "By the sacred beard of J.R.R.Tolkien, prepare to DIE!!!"
dcard "$TMP/08.png" "會說話的蠹蟲" "這就是歧視——第三級的!你們這些人類都一個樣。" "It's just racism — to the third degree!"
slide "$TMP/09.png" sc_selftaught.png "當年沒看懂的英式冷笑話,終於補上"
card  "$TMP/10.png" "英語原聲 · 完整字幕" "F8 中英即時切換" "防拷免手冊 · 全程 patch 引擎不改原檔"
card  "$TMP/11.png" "魔法師西蒙 繁中化" "github.com/wicanr2" "simon-the-sorcerer-cht"

# ===== 逐段編碼 + concat =====
LIST="$TMP/list.txt"; : > "$LIST"
declare -A SEC=( [00]=6 [01]=5 [02]=5 [03]=5 [04]=6 [05]=6 [06]=6 [07]=6 [08]=6 [09]=6 [10]=6 [11]=6 )
for f in 00 01 02 03 04 05 06 07 08 09 10 11; do
  kb "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"
  echo "file '$TMP/s_$f.mp4'" >> "$LIST"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"

# ===== 鋪原版遊戲配樂(afade)=====
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4")
FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$MUS/simon_title_bgm.wav" \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3,volume=1.6[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/simon-cht-promo.mp4"
echo "=== 產出 ==="; ls -lh "$OUT/simon-cht-promo.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/simon-cht-promo.mp4"
