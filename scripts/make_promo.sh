#!/usr/bin/env bash
# 魔法師西蒙繁中融合版 推廣片 v2(多版面破除單調;CPU-safe)
# 變化:分幕配色、滿版/框內兩種截圖、大引號對白卡、Ken Burns 動態(單幀安全法)、F8 前後對比
set -eu
GOLD='#c9a227'; GOLDSH='#6b4e12'; CREAM='#f2ead2'; DIM='#a892d0'; INK='#0c0818'
FB=/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
FR=/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc
W=1280; H=720; FPS=25
SHOT=/shots; OUT=/out; MUS=/music; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"

# 分幕背景主題(換氛圍):$1=out $2=theme
bg(){ local o=$1 t=$2
  case "$t" in
    intro)   convert -size ${W}x${H} "radial-gradient:#3a2668-${INK}" "$o";;
    problem) convert -size ${W}x${H} "radial-gradient:#4a1420-#0a0608" "$o";;      # 暗紅=問題
    solve)   convert -size ${W}x${H} "radial-gradient:#12403a-#050f0c" "$o";;       # 青綠=解法
    show)    convert -size ${W}x${H} "gradient:#241844-${INK}" "$o";;
    gold)    convert -size ${W}x${H} "radial-gradient:#2a2410-${INK}" "$o";;
  esac; }

# 標題卡(置中鎏金浮雕)
card(){ local o=$1 th=$2 zh=$3 en=$4 sub=$5; bg "$TMP/_b.png" "$th"
  convert "$TMP/_b.png" -font "$FB" -gravity center \
    -fill "$GOLDSH" -pointsize 96 -annotate +4+4 "$zh" -fill "$GOLD" -pointsize 96 -annotate +0-10 "$zh" \
    -font "$FR" -fill "$CREAM" -pointsize 46 -annotate +0+80 "$en" \
    -fill "$DIM" -pointsize 30 -annotate +0+150 "$sub" "$o"; }

# 大引號對白卡(左對齊、巨型引號、場景標)—— 與置中卡不同視覺
dcard(){ local o=$1 th=$2 scene=$3 zh=$4 en=$5; bg "$TMP/_b.png" "$th"
  convert -background none -fill "$CREAM" -font "$FR" -pointsize 54 -size $((W-320))x caption:"$zh" "$TMP/_z.png"
  convert "$TMP/_b.png" \
    -font "$FB" -fill "$GOLD" -gravity northwest -pointsize 30 -annotate +90+80 "◆ $scene" \
    -font "$FB" -fill "#ffffff22" -gravity northwest -pointsize 220 -annotate +40+70 "“" \
    "$TMP/_z.png" -gravity west -geometry +140+10 -composite \
    -font "$FR" -fill "$DIM" -gravity southeast -pointsize 24 -annotate +90+70 "$en" "$o"; }

# 滿版截圖(填滿、下三分之一字幕條)—— 沉浸感
slide_full(){ local o=$1 sc=$2 cap=$3
  convert "$SHOT/$sc" -filter point -resize ${W}x${H}^ -gravity center -extent ${W}x${H} "$TMP/_s.png"
  convert "$TMP/_s.png" -fill "#000000cc" -draw "rectangle 0,$((H-96)) ${W},${H}" \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 36 -annotate +0+30 "$cap" \
    -fill "$GOLD" -gravity south -draw "rectangle 0,$((H-100)) ${W},$((H-96))" "$o"; }

# 框內截圖(金框置中)—— 與滿版交替
slide_frame(){ local o=$1 th=$2 sc=$3 cap=$4; bg "$TMP/_b.png" "$th"
  convert "$SHOT/$sc" -filter point -resize x520 -bordercolor "$GOLD" -border 3 "$TMP/_f.png"
  convert "$TMP/_b.png" "$TMP/_f.png" -gravity north -geometry +0+44 -composite \
    -font "$FR" -fill "$CREAM" -gravity south -pointsize 34 -annotate +0+34 "$cap" "$o"; }

# F8 前後對比(左中/右英,中間金色 F8)
split_ba(){ local o=$1 zh=$2 en=$3; bg "$TMP/_b.png" show
  convert -background none -fill "$CREAM" -font "$FR" -pointsize 40 -size 500x -gravity center caption:"$zh" "$TMP/_l.png"
  convert -background none -fill "$DIM"   -font "$FR" -pointsize 40 -size 500x -gravity center caption:"$en" "$TMP/_r.png"
  convert "$TMP/_b.png" \
    "$TMP/_l.png" -gravity west  -geometry +80+20 -composite \
    "$TMP/_r.png" -gravity east  -geometry +80+20 -composite \
    -font "$FB" -fill "$GOLD" -gravity center -pointsize 60 -annotate +0-20 "F8" \
    -font "$FR" -fill "$GOLD" -gravity center -pointsize 26 -annotate +0+40 "◀ ▶" \
    -font "$FR" -fill "$DIM" -gravity north -pointsize 30 -annotate +0+70 "一鍵切換 中 / 英字幕" "$o"; }

# 靜態 + fade
enc(){ local img=$1 o=$2 s=$3; local fo; fo=$(awk "BEGIN{print $s-0.6}")
  ffmpeg -y -loglevel error -loop 1 -i "$img" -t "$s" -r $FPS \
    -vf "fade=t=in:st=0:d=0.6,fade=t=out:st=$fo:d=0.6,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$o"; }

# Ken Burns 動態(單幀安全法:單輸入幀 + d=總幀 + -frames:v 收;不要前置 fps/-t)
kb(){ local img=$1 o=$2 s=$3; local n=$((FPS*s)); local fo; fo=$(awk "BEGIN{print $s-0.6}")
  convert "$img" -filter point -resize ${W}x${H}^ -gravity center -extent ${W}x${H} "$TMP/_kb.png"
  ffmpeg -y -loglevel error -loop 1 -i "$TMP/_kb.png" \
    -vf "scale=2560:1440,zoompan=z='min(zoom+0.0009,1.14)':d=${n}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${W}x${H}:fps=${FPS},fade=t=in:st=0:d=0.6,fade=t=out:st=${fo}:d=0.6,format=yuv420p" \
    -frames:v ${n} -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$o"; }

# ===== 分鏡(版面刻意交替)=====
card       "$TMP/00.png" intro   "魔法師西蒙" "Simon the Sorcerer" "繁體中文化 · CD 語音 × 完整字幕"
dcard      "$TMP/01.png" problem "問題" "英文 CD 版,其實沒有完整字幕。" "English CD version — no full subtitles."
dcard      "$TMP/02.png" problem "現象" "角色嘴巴在動,你卻一個字都看不到。" "Mouths move — but nothing appears."
dcard      "$TMP/03.png" solve   "解法" "floppy 完整文字 × CD 英語配音,融合。" "Floppy text + CD voice, fused."
slide_full "$TMP/04.png" sc_hero.png "完整中文字幕,一句不漏"                          # 此圖在編碼段套 Ken Burns 動態
slide_full "$TMP/05.png" sc_hat.png "24×24 點陣中文,自動換行"                        # 滿版
split_ba   "$TMP/06.png" "謝謝你,奇皮。" "Thank-you, Chippy."                        # F8 前後對比
dcard      "$TMP/07.png" gold    "托爾金迷" "以托爾金的神聖鬍鬚之名,準備受死吧!!!" "By the sacred beard of J.R.R.Tolkien, prepare to DIE!!!"
dcard      "$TMP/08.png" show    "巨魔橋" "你走運了,我正好是個到處推銷滿足的業務員。" "Luckily, I'm a travelling satisfaction salesman."
slide_frame "$TMP/09.png" show sc_selftaught.png "當年沒看懂的英式冷笑話,終於補上"    # 框內
card       "$TMP/10.png" gold    "英語原聲 · 完整字幕" "F8 中英切換 · 防拷免手冊" "全程 patch 引擎 · 不改原檔"
card       "$TMP/11.png" intro   "魔法師西蒙 繁中化" "github.com/wicanr2" "simon-the-sorcerer-cht"

# ===== 編碼(04 用 Ken Burns 動態,其餘靜態 enc;依序 append)=====
LIST="$TMP/list.txt"; : > "$LIST"
declare -A SEC=( [00]=6 [01]=5 [02]=5 [03]=5 [04]=6 [05]=6 [06]=6 [07]=6 [08]=6 [09]=6 [10]=6 [11]=6 )
for f in 00 01 02 03 04 05 06 07 08 09 10 11; do
  if [ "$f" = "04" ]; then kb "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"
  else enc "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"; fi
  echo "file '$TMP/s_$f.mp4'" >> "$LIST"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"

# ===== 原版配樂 =====
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4"); FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$MUS/simon_title_bgm.wav" \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3,volume=1.6[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/simon-cht-promo.mp4"
echo "=== 產出 ==="; ls -lh "$OUT/simon-cht-promo.mp4"; ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/simon-cht-promo.mp4"
