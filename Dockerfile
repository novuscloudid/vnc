FROM ubuntu:22.04

# Hindari interaktif prompt saat instalasi
ENV DEBIAN_FRONTEND=noninteractive

# Update dan install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    websockify \
    dbus-x11 \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Buat direktori kerja
WORKDIR /app

# Download noVNC versi terbaru langsung dari GitHub
RUN git clone https://github.com/novnc/noVNC.git /app/novNC

# Konfigurasi VNC Password dan Resolusi Default
ENV USER=root
ENV PASSWORD=passwordku
ENV RESOLUTION=1280x720

RUN mkdir -p ~/.vnc \
    && echo "$PASSWORD" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd

# Buat script startup: Menjalankan VNC server dan websockify dengan root folder ke /app/novNC
RUN echo '#!/bin/bash\n' \
    'rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n' \
    'vncserver :1 -geometry $RESOLUTION -depth 24\n' \
    'websockify --web=/app/novNC/ 6901 localhost:5901' > /app/start.sh \
    && chmod +x /app/start.sh

# Port web noVNC
EXPOSE 6901

# Jalankan script utama
CMD ["/app/start.sh"]
