#!/usr/bin/env bash
# 神通妙巫師繁中融合版 推廣片 v5(640 crisp 重拍)
# Theme:「羊皮紙與魔法書」— token 萃取自遊戲本身(閣樓暖木、臥室磚紅、遊戲字幕綠)
# 骨架 E:實機錄影混剪為主。v5 相對 v4:畫面 320→640 crisp;live 段用均勻 1.5x pillarbox 保清晰;
#   新增 split_hires 糊→清對比(同一句「謝謝你,奇皮」舊 320 vs 新 640);分鏡增加實機遊玩(書房+戶外)、精簡對白卡
set -eu
# ===== theme.sh(Simon 專屬)=====
WOOD_D='#120b06'; WOOD_L='#3a2412'                 # 暖木底(閣樓深木色)
PARCH='#e8d9b0'; PARCH_BD='#8a5a20'                # 羊皮紙面板
AMBER='#d98e2b'; AMBER_SH='#6b3d10'                # 琥珀標題(閣樓木光)
TEXT='#f0e6d0'; SUBTLE='#a08a68'                   # 米白/淡褐
GREEN='#1b6103'; GREEN_L='#2f9e0a'                 # 遊戲字幕綠(對白專用)
BRICK='#ac301c'                                    # 磚紅(場景標)
FB=/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
FR=/usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc
W=1280; H=720; FPS=25
SHOT=/shots; CLIP=/clips; OUT=/out; MUS=/music; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"

wood(){ convert -size ${W}x${H} "radial-gradient:${WOOD_L}-${WOOD_D}" "$1"; }

# 標題卡:暖木底 + 琥珀浮雕
card(){ local o=$1 zh=$2 en=$3 sub=$4; wood "$TMP/_b.png"
  convert "$TMP/_b.png" -font "$FB" -gravity center \
    -fill "$AMBER_SH" -pointsize 76 -annotate +3+3 "$zh" -fill "$AMBER" -pointsize 76 -annotate +0-8 "$zh" \
    -font "$FR" -fill "$TEXT" -pointsize 36 -annotate +0+66 "$en" \
    -fill "$SUBTLE" -pointsize 25 -annotate +0+124 "$sub" "$o"; }

# 對白卡:羊皮紙面板 + 墨綠對白(遊戲字幕綠)+ 磚紅場景標
dcard(){ local o=$1 scene=$2 zh=$3 en=$4; wood "$TMP/_b.png"
  convert -size $((W-260))x$((H-220)) xc:"$PARCH" -bordercolor "$PARCH_BD" -border 4 \
    \( +clone -background black -shadow 60x8+0+8 \) +swap -background none -layers merge +repage "$TMP/_p.png"
  convert -background none -fill "$GREEN" -font "$FB" -pointsize 38 -size $((W-380))x -gravity center caption:"$zh" "$TMP/_z.png"
  convert "$TMP/_b.png" "$TMP/_p.png" -gravity center -composite \
    -font "$FB" -fill "$BRICK" -gravity north -pointsize 26 -annotate +0+104 "— $scene —" \
    "$TMP/_z.png" -gravity center -geometry +0+10 -composite \
    -font "$FR" -fill "$SUBTLE" -gravity south -pointsize 21 -annotate +0+64 "$en" "$o"; }

# 靜圖框卡(羊皮紙細框)
slide_frame(){ local o=$1 sc=$2 cap=$3; wood "$TMP/_b.png"
  convert "$SHOT/$sc" -filter point -resize x520 -bordercolor "$PARCH" -border 4 -bordercolor "$PARCH_BD" -border 2 "$TMP/_f.png"
  convert "$TMP/_b.png" "$TMP/_f.png" -gravity north -geometry +0+44 -composite \
    -font "$FR" -fill "$TEXT" -gravity south -pointsize 28 -annotate +0+36 "$cap" "$o"; }

# F8 對比:左遊戲綠中文 | 右淡褐英文
split_ba(){ local o=$1 zh=$2 en=$3; wood "$TMP/_b.png"
  convert -background none -fill "$GREEN_L" -font "$FB" -pointsize 34 -size 500x -gravity center caption:"$zh" "$TMP/_l.png"
  convert -background none -fill "$SUBTLE"  -font "$FR" -pointsize 32 -size 500x -gravity center caption:"$en" "$TMP/_r.png"
  convert "$TMP/_b.png" \
    "$TMP/_l.png" -gravity west -geometry +80+20 -composite \
    "$TMP/_r.png" -gravity east -geometry +80+20 -composite \
    -font "$FB" -fill "$AMBER" -gravity center -pointsize 52 -annotate +0-20 "F8" \
    -font "$FR" -fill "$AMBER" -gravity center -pointsize 26 -annotate +0+40 "◀ ▶" \
    -font "$FR" -fill "$SUBTLE" -gravity north -pointsize 26 -annotate +0+70 "一鍵切換 中 / 英字幕(語音維持英語)" "$o"; }

# 糊→清 對比:左舊 320 糊 | 右新 640 清(同一句字幕)
split_hires(){ local o=$1 oldimg=$2 newimg=$3; wood "$TMP/_b.png"
  convert "$SHOT/$oldimg" -filter point -resize 500x -bordercolor "$PARCH_BD" -border 3 "$TMP/_ho.png"
  convert "$SHOT/$newimg" -filter point -resize 500x -bordercolor "$AMBER" -border 3 "$TMP/_hn.png"
  convert "$TMP/_b.png" \
    "$TMP/_ho.png" -gravity west -geometry +50+10 -composite \
    "$TMP/_hn.png" -gravity east -geometry +50+10 -composite \
    -font "$FB" -fill "$SUBTLE" -gravity northwest -pointsize 30 -annotate +150+130 "舊 320  糊" \
    -font "$FB" -fill "$AMBER"  -gravity northeast -pointsize 30 -annotate +150+130 "新 640  清" \
    -font "$FB" -fill "$AMBER"  -gravity center -pointsize 64 -annotate +0-10 "▶" \
    -font "$FR" -fill "$TEXT"   -gravity south -pointsize 31 -annotate +0+48 "同一句「謝謝你,奇皮。」—— 高解析後字更清晰" "$o"; }

# live clip 字幕條(深木底 + 琥珀線)
capbar(){ local o=$1 cap=$2
  convert -size ${W}x${H} xc:none \
    -fill "#1a0f06d8" -draw "rectangle 0,$((H-88)) ${W},${H}" \
    -fill "$AMBER" -draw "rectangle 0,$((H-92)) ${W},$((H-88))" \
    -font "$FR" -fill "$TEXT" -gravity south -pointsize 28 -annotate +0+28 "$cap" "$o"; }

enc(){ local img=$1 o=$2 s=$3; local fo; fo=$(awk "BEGIN{print $s-0.6}")
  ffmpeg -y -loglevel error -loop 1 -i "$img" -t "$s" -r $FPS \
    -vf "fade=t=in:st=0:d=0.6,fade=t=out:st=$fo:d=0.6,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$o"; }

clip(){ local src=$1 ss=$2 dur=$3 cap=$4 o=$5; local fo; fo=$(awk "BEGIN{print $dur-0.6}")
  capbar "$TMP/_cap.png" "$cap"
  # 640×480 素材均勻 1.5x → 960×720 pillarbox 置中(不變形);neighbor 保 crisp 像素
  ffmpeg -y -loglevel error -ss "$ss" -t "$dur" -i "$CLIP/$src" -i "$TMP/_cap.png" \
    -filter_complex "[0:v]scale=960:720:flags=neighbor,pad=${W}:${H}:160:0:color=${WOOD_D}[v];[v][1:v]overlay=0:0,fade=t=in:st=0:d=0.6,fade=t=out:st=${fo}:d=0.6,format=yuv420p" \
    -r $FPS -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p -an "$o"; }

# ===== 分鏡 v5(骨架 E:實機為主;更多遊玩畫面 + 糊→清對比)=====
# live 段用新 640 crisp 錄影(r1_intro 片頭 / r2_gameplay 書房→戶外)
clip r1_intro.mp4    2   5  "Simon the Sorcerer · 1993 · Adventure Soft"          "$TMP/s_00.mp4"   # logo 開場
card  "$TMP/01.png" "神通妙巫師" "繁體中文化" "CD 語音 × Floppy 完整字幕 融合版"
dcard "$TMP/02.png" "問題" $'英文 CD 版沒有完整字幕。\n嘴巴在動,一個字都看不到。' "English CD has no full subtitles."
clip r1_intro.mp4    52  7  "片頭魔術秀——中文字幕即時渲染(640 高解析)"          "$TMP/s_04.mp4"
split_hires "$TMP/HR.png" cmp_old.png cmp_new.png                                                 # 糊→清 對比
clip r2_gameplay.mp4 1   9  "實機遊玩:巫師書房,場景全程 640 高解析"               "$TMP/s_05.mp4"
split_ba "$TMP/06.png" "謝謝你,奇皮。" "Thank-you, Chippy."
clip r2_gameplay.mp4 44  11 "走出戶外——花園草屋,懸停即時顯示中文物件名"          "$TMP/s_08.mp4"
dcard "$TMP/09.png" "托爾金迷" $'以托爾金的神聖鬍鬚之名,\n準備受死吧!!!' "By the sacred beard of J.R.R.Tolkien, prepare to DIE!!!"
card  "$TMP/10.png" "全劇 4035 條" "一句不漏" "英語原聲 · F8 中英切換 · 防拷免手冊"
card  "$TMP/11.png" "神通妙巫師 繁中化" "github.com/wicanr2" "simon-the-sorcerer-cht"

# ===== 編碼 + concat =====
LIST="$TMP/list.txt"; : > "$LIST"
declare -A SEC=( [01]=5 [02]=5 [HR]=6 [06]=5 [09]=6 [10]=5 [11]=6 )
for f in 01 02 HR 06 09 10 11; do enc "$TMP/$f.png" "$TMP/s_$f.mp4" "${SEC[$f]}"; done
for f in 00 01 02 04 HR 05 06 08 09 10 11; do echo "file '$TMP/s_$f.mp4'" >> "$LIST"; done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"

# ===== 原版配樂 =====
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4"); FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$MUS/simon_title_bgm.wav" \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3,volume=1.6[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/simon-cht-promo.mp4"
echo "=== 產出 ==="; ls -lh "$OUT/simon-cht-promo.mp4"; ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/simon-cht-promo.mp4"
