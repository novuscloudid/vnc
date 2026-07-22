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
    xauth \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Setup password VNC
RUN mkdir -p ~/.vnc && \
    echo "password123" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Konfigurasi xstartup yang bersih untuk XFCE
RUN echo '#!/bin/bash' > ~/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources' >> ~/.vnc/xstartup && \
    echo 'startxfce4 &' >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Gunakan script startup yang memastikan VNC tidak mati dini
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
echo "Starting websockify proxy on port ${PORT:-8080}..."\n\
exec websockify --web /usr/share/novnc/ 0.0.0.0:${PORT:-8080} localhost:5901\n'\
> /root/start.sh && chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]
