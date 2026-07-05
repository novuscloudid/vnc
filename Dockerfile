FROM ubuntu:22.04

# Mencegah prompt interaktif saat instalasi apt
ENV DEBIAN_FRONTEND=noninteractive

# Ganti password sesuai keinginanmu
ENV VNC_PASS="admin123" 

# Update dan install Desktop Environment (XFCE4), VNC Server, dan noVNC
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal \
    tigervnc-standalone-server \
    novnc websockify \
    curl wget git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup Password VNC
RUN mkdir -p /root/.vnc \
    && echo ${VNC_PASS} | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Setup script agar XFCE4 otomatis jalan saat VNC server dinyalakan
RUN echo '#!/bin/bash\n\
startxfce4 &\n\
' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# Entrypoint script untuk Railway
# Railway akan memberikan env variable $PORT secara dinamis (biasanya 8080 atau 3000)
RUN echo '#!/bin/bash\n\
export PORT=${PORT:-8080}\n\
# Hapus file lock jika container ter-restart paksa agar VNC tidak error\n\
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
# Jalankan VNC Server di display :1 (port 5901)\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
# Jalankan noVNC untuk menjembatani port 5901 ke $PORT Railway via HTTP/WebSockets\n\
websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT} localhost:5901\n\
' > /start.sh && chmod +x /start.sh

# Eksekusi script saat container berjalan
CMD ["/start.sh"]
