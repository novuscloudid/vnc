FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASS="admin123"
ENV VNC_USER="developer" 

# Instalasi paket sistem, XFCE4, Node.js, dan tools pendukung
RUN apt-get update && apt-get install -y \
    sudo \
    xfce4 xfce4-terminal dbus-x11 \
    tigervnc-standalone-server \
    websockify \
    curl wget git build-essential \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download noVNC resmi dan arahkan index.html ke vnc_lite.html agar bebas dari error UIJS
RUN mkdir -p /usr/share/novnc \
    && curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xz -C /usr/share/novnc --strip-components=1 \
    && ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Membuat user, memberikan akses sudo penuh, dan set password sistem
RUN useradd -m -s /bin/bash ${VNC_USER} \
    && echo "${VNC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "${VNC_USER}:${VNC_PASS}" | chpasswd

USER ${VNC_USER}
WORKDIR /home/${VNC_USER}

# Konfigurasi xstartup dan mematikan screensaver agar layar tidak terkunci otomatis
RUN mkdir -p /home/${VNC_USER}/.vnc \
    && echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xset s off\n\
xset -dpms\n\
xset s noblank\n\
exec startxfce4\n\
' > /home/${VNC_USER}/.vnc/xstartup && chmod +x /home/${VNC_USER}/.vnc/xstartup

# Script untuk generate password VNC, membersihkan lock, dan menjalankan server
RUN echo '#!/bin/bash\n\
export PORT=${PORT:-8080}\n\
mkdir -p /home/developer/.vnc\n\
echo -n "${VNC_PASS}" | vncpasswd -f > /home/developer/.vnc/passwd\n\
chmod 600 /home/developer/.vnc/passwd\n\
vncserver -kill :1 >/dev/null 2>&1 || true\n\
sudo rm -rf /tmp/.X* /tmp/.X11-unix\n\
sudo mkdir -p /tmp/.X11-unix\n\
sudo chmod 1777 /tmp/.X11-unix\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
sleep 2\n\
websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT} localhost:5901\n\
' > /home/${VNC_USER}/start.sh && chmod +x /home/${VNC_USER}/start.sh

CMD ["/home/developer/start.sh"]
