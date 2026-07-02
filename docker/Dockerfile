FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq \
    build-essential libsdl2-dev libsdl2-net-dev libfreetype6-dev \
    libpng-dev libjpeg-turbo8-dev pkg-config zlib1g-dev nasm \
    python3 python3-freetype fonts-noto-cjk \
    xvfb imagemagick xdotool dosbox libsndio7.0 \
    && rm -rf /var/lib/apt/lists/*
