#!/bin/bash

# Gunakan port dari Railway, default ke 8080 jika tidak diset
PORT="${PORT:-8080}"

# Bersihkan lock VNC jika ada
vncserver -kill :1 &>/dev/null
rm -rf /tmp/.X11-unix/X1 2>/dev/null

# Jalankan VNC Server
vncserver :1 -geometry 1024x768 -localhost no -SecurityTypes None --I-KNOW-THIS-IS-INSECURE

# Buat sertifikat SSL self-signed jika belum ada
if [ ! -f "self.pem" ]; then
    openssl req -new -subj "/C=ID/ST=Jakarta/L=Jakarta/O=App/CN=railway.app" -x509 -days 365 -nodes -out self.pem -keyout self.pem
fi

# Jalankan websockify dengan port dinamis dari Railway
echo "Starting noVNC on port $PORT..."
websockify --web=/usr/share/novnc/ --cert=self.pem "$PORT" localhost:5901
