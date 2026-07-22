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

# Buat file .Xresources kosong agar tidak error "No such file or directory"
RUN touch ~/.Xresources

# Buat file xstartup yang benar dan stabil untuk XFCE
RUN echo '#!/bin/bash' > ~/.vnc/xstartup && \
    echo 'unset SESSION_MANAGER' >> ~/.vnc/xstartup && \
    echo 'unset DBUS_SESSION_BUS_ADDRESS' >> ~/.vnc/xstartup && \
    echo 'startxfce4 &' >> ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Script startup: Menjalankan VNC server dengan penanganan log dan websockify
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X*-lock /tmp/.X11-unix/*\n\
vncserver :1 -geometry 1280x720 -depth 24\n\
echo "Starting websockify proxy on port ${PORT:-8080}..."\n\
exec websockify --web /usr/share/novnc/ 0.0.0.0:${PORT:-8080} localhost:5901\n'\
> /root/start.sh && chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]
