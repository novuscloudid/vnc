FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASS="admin123"
ENV VNC_USER="developer" 

# Menghapus software-properties-common yang error di Debian Trixie
RUN apt-get update && apt-get install -y \
    sudo \
    xfce4 xfce4-terminal dbus-x11 \
    tigervnc-standalone-server \
    novnc websockify \
    curl wget git build-essential \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Membuat user, memberikan akses sudo penuh tanpa password, dan set password sistem
RUN useradd -m -s /bin/bash ${VNC_USER} \
    && echo "${VNC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "${VNC_USER}:${VNC_PASS}" | chpasswd

USER ${VNC_USER}
WORKDIR /home/${VNC_USER}

# Konfigurasi password VNC
RUN mkdir -p /home/${VNC_USER}/.vnc \
    && echo -n "${VNC_PASS}" | vncpasswd -f > /home/${VNC_USER}/.vnc/passwd \
    && chmod 600 /home/${VNC_USER}/.vnc/passwd

# Konfigurasi xstartup dan mematikan screensaver agar layar tidak terkunci otomatis
RUN echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xset s off\n\
xset -dpms\n\
xset s noblank\n\
exec startxfce4\n\
' > /home/${VNC_USER}/.vnc/xstartup && chmod +x /home/${VNC_USER}/.vnc/xstartup

# Script untuk menjalankan VNC, noVNC, dan websockify
RUN echo '#!/bin/bash\n\
export PORT=${PORT:-8080}\n\
vncserver -kill :1 >/dev/null 2>&1 || true\n\
sudo rm -rf /tmp/.X* /tmp/.X11-unix\n\
sudo mkdir -p /tmp/.X11-unix\n\
sudo chmod 1777 /tmp/.X11-unix\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
sleep 2\n\
websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT} localhost:5901\n\
' > /home/${VNC_USER}/start.sh && chmod +x /home/${VNC_USER}/start.sh

CMD ["/home/developer/start.sh"]
