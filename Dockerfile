FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASS="admin123"
ENV VNC_USER="developer" 

# Tambahan dbus-x11 agar XFCE4 berjalan stabil di container
RUN apt-get update && apt-get install -y \
    sudo \
    xfce4 xfce4-terminal dbus-x11 \
    tigervnc-standalone-server \
    novnc websockify \
    curl wget git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ${VNC_USER} \
    && echo "${VNC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER ${VNC_USER}
WORKDIR /home/${VNC_USER}

RUN mkdir -p /home/${VNC_USER}/.vnc \
    && echo ${VNC_PASS} | vncpasswd -f > /home/${VNC_USER}/.vnc/passwd \
    && chmod 600 /home/${VNC_USER}/.vnc/passwd

# REVISI UTAMA: Menggunakan 'exec' dan menonaktifkan session bawaan
RUN echo '#!/bin/bash\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec startxfce4\n\
' > /home/${VNC_USER}/.vnc/xstartup && chmod +x /home/${VNC_USER}/.vnc/xstartup

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
