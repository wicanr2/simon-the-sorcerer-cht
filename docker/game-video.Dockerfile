# 重建 game-video:latest 工具 image(推廣片合成 + AppImage 打包用)
# 原本是 docker/Dockerfile 的 image commit 加裝 ffmpeg/file/wget 而成,這裡補成可重建的 Dockerfile。
# 用法:
#   docker build -f docker/game-video.Dockerfile -t game-video:latest .
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq \
    build-essential libsdl2-dev libsdl2-net-dev libfreetype6-dev \
    libpng-dev libjpeg-turbo8-dev pkg-config zlib1g-dev nasm \
    python3 python3-freetype fonts-noto-cjk \
    xvfb imagemagick xdotool dosbox libsndio7.0 \
    ffmpeg file wget \
    && rm -rf /var/lib/apt/lists/*
# ImageMagick policy:允許讀本地 @ 檔(make_promo.sh 的 caption:@ 需要)
RUN sed -i 's/rights="none" pattern="@\*"/rights="read" pattern="@*"/' /etc/ImageMagick-6/policy.xml || true
