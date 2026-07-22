FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    net-tools \
    curl \
    procps \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Setup password VNC
RUN mkdir -p ~/.vnc && \
    echo "password123" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Konfigurasi xstartup XFCE
RUN echo "#!/bin/bash" > ~/.vnc/xstartup && \
    echo "xrdb $HOME/.Xresources" >> ~/.vnc/xstartup && \
    echo "startxfce4 &" >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Script startup: membersihkan lock file lama, jalankan vnc, lalu novnc proxy
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n\
vncserver :1 -geometry 1280x720 -depth 24\n\
echo "Starting noVNC proxy..."\n\
exec /usr/share/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:${PORT:-8080}\n'\
> /root/start.sh && chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]
