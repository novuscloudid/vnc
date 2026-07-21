FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASS="12345"
ENV VNC_USER="developer" 

# Instalasi sistem, XFCE4, Node.js, dan tools pendukung dengan akses bebas penuh
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

# Download noVNC resmi dan gunakan vnc_lite.html
RUN mkdir -p /usr/share/novnc \
    && curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xz -C /usr/share/novnc --strip-components=1 \
    && ln -s /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html

# Membuat user, akses sudo penuh tanpa sandi, serta menyelaraskan password sistem & VNC menjadi "12345"
RUN useradd -m -s /bin/bash ${VNC_USER} \
    && echo "${VNC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && echo "${VNC_USER}:${VNC_PASS}" | chpasswd

USER ${VNC_USER}
WORKDIR /home/${VNC_USER}

# Konfigurasi xstartup, mematikan screensaver & dpms total agar tidak pernah lockscreen
RUN mkdir -p /home/${VNC_USER}/.vnc \
    && echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
xset s off\n\
xset -dpms\n\
xset s noblank\n\
exec startxfce4\n\
' > /home/${VNC_USER}/.vnc/xstartup && chmod +x /home/${VNC_USER}/.vnc/xstartup

# Membuat direktori token untuk mapping port aman websockify
RUN mkdir -p /home/${VNC_USER}/novnc_tokens \
    && echo "aps: localhost:5901" > /home/${VNC_USER}/novnc_tokens/vnc

# Script inisialisasi dinamis yang membaca port Railway secara mutlak
RUN echo '#!/bin/bash\n\
# Menggunakan port dinamis yang diberikan oleh Railway secara mutlak\n\
TARGET_PORT="${PORT:-8080}"\n\
\n\
mkdir -p /home/developer/.vnc\n\
echo -n "${VNC_PASS}" | vncpasswd -f > /home/developer/.vnc/passwd\n\
chmod 600 /home/developer/.vnc/passwd\n\
\n\
vncserver -kill :1 >/dev/null 2>&1 || true\n\
sudo rm -rf /tmp/.X* /tmp/.X11-unix\n\
sudo mkdir -p /tmp/.X11-unix\n\
sudo chmod 1777 /tmp/.X11-unix\n\
\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
sleep 2\n\
\n\
echo "Starting websockify on dynamic port ${TARGET_PORT} with token routing..."\n\
exec websockify --web=/usr/share/novnc/ --target-config=/home/developer/novnc_tokens/ 0.0.0.0:${TARGET_PORT}\n\
' > /home/${VNC_USER}/start.sh && chmod +x /home/${VNC_USER}/start.sh

CMD ["/home/developer/start.sh"]
