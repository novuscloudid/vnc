FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install komponen desktop XFCE, VNC, dan noVNC
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    net-tools \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Setup password VNC (ubah "password123" sesuai keinginan Anda)
RUN mkdir -p ~/.vnc && \
    echo "password123" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Buat file xstartup agar XFCE berjalan otomatis saat VNC aktif
RUN mkdir -p ~/.vnc && \
    echo "#!/bin/bash" > ~/.vnc/xstartup && \
    echo "xrdb $HOME/.Xresources" >> ~/.vnc/xstartup && \
    echo "startxfce4 &" >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Script startup untuk menjalankan VNC server & websockify dengan port Railway
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n\
vncserver :1 -geometry 1280x720 -depth 24\n\
# Menjalankan websockify agar meneruskan trafik HTTP/WS ke port VNC (5901)\n\
exec websockify --web /usr/share/novnc/ 0.0.0.0:${PORT:-8080} localhost:5901\n'\
> /root/start.sh && chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]
