FROM debian:bookworm-slim

# Hindari interaktif prompt saat instalasi
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies: XFCE desktop, TigerVNC, noVNC, dan browser pendukung
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    net-tools \
    curl \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Set direktori kerja
WORKDIR /root

# Konfigurasi VNC (Password default: password123, silakan ubah sesuai keinginan)
RUN mkdir -p ~/.vnc && \
    echo "password123" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Buat script startup untuk menjalankan VNC dan noVNC secara bersamaan
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n\
vncserver :1 -geometry 1280x720 -depth 24\n\
websockify --web /usr/share/novnc/ --wrap-mode ignore 0.0.0.0:${PORT:-8080} localhost:5901\n'\
> /root/start.sh && chmod +x /root/start.sh

# Port bawaan Railway akan membaca variabel $PORT
EXPOSE 8080

# Jalankan script utama
CMD ["/root/start.sh"]
