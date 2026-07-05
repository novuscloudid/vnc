FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV VNC_PASS="admin123"
# Tentukan nama user baru yang kamu inginkan
ENV VNC_USER="developer" 

# 1. Install sudo beserta Desktop Environment dan VNC
RUN apt-get update && apt-get install -y \
    sudo \
    xfce4 xfce4-terminal \
    tigervnc-standalone-server \
    novnc websockify \
    curl wget git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Buat user baru dan masukkan ke grup sudo
RUN useradd -m -s /bin/bash ${VNC_USER} \
    && echo "${VNC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 3. Pindah ke user baru (mulai dari sini, semua perintah dijalankan sebagai user biasa)
USER ${VNC_USER}
WORKDIR /home/${VNC_USER}

# 4. Setup Password VNC untuk user baru
RUN mkdir -p /home/${VNC_USER}/.vnc \
    && echo ${VNC_PASS} | vncpasswd -f > /home/${VNC_USER}/.vnc/passwd \
    && chmod 600 /home/${VNC_USER}/.vnc/passwd

# 5. Setup script xstartup
RUN echo '#!/bin/bash\n\
startxfce4 &\n\
' > /home/${VNC_USER}/.vnc/xstartup && chmod +x /home/${VNC_USER}/.vnc/xstartup

# 6. Entrypoint script (harus ditulis menggunakan sudo agar bisa menghapus file lock system jika diperlukan)
RUN echo '#!/bin/bash\n\
export PORT=${PORT:-8080}\n\
sudo rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1\n\
vncserver :1 -geometry 1280x720 -depth 24 -localhost no\n\
websockify --web=/usr/share/novnc/ 0.0.0.0:${PORT} localhost:5901\n\
' > /home/${VNC_USER}/start.sh && chmod +x /home/${VNC_USER}/start.sh

# Eksekusi script saat container berjalan
CMD ["/home/developer/start.sh"]
