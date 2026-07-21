FROM ubuntu:22.04

# Hindari interaktif prompt saat instalasi
ENV DEBIAN_FRONTEND=noninteractive

# Update dan install dependencies (XFCE4 desktop, TightVNC, noVNC, websockify, dan utilitas pendukung)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    dbus-x11 \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Buat direktori kerja
WORKDIR /app

# Konfigurasi VNC Password dan Resolusi Default
ENV USER=root
ENV PASSWORD=passwordku
ENV RESOLUTION=1280x720

RUN mkdir -p ~/.vnc \
    && echo "$PASSWORD" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd

# Buat script startup untuk menjalankan VNC server dan noVNC
RUN echo '#!/bin/bash\n' \
    'rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n' \
    'vncserver :1 -geometry $RESOLUTION -depth 24\n' \
    'websockify --web=/usr/share/novnc/ 6901 localhost:5901' > /app/start.sh \
    && chmod +x /app/start.sh

# Port web noVNC (sesuaikan dengan port bawaan platform cloud, misal 6901 atau 7860)
EXPOSE 6901

# Jalankan script utama
CMD ["/app/start.sh"]
