# Menggunakan base image Debian Bookworm slim
FROM debian:bookworm-slim

# Mencegah prompt interaktif
ENV DEBIAN_FRONTEND=noninteractive

# Update dan install paket dasar (tanpa ttyd)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    sudo \
    procps \
    net-tools \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Download dan pasang ttyd secara manual versi terbaru langsung dari GitHub
RUN wget -O /usr/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 && \
    chmod +x /usr/bin/ttyd

# Konfigurasi SSH
RUN mkdir /var/run/sshd
RUN echo 'root:root123' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/profile

# Buat startup script dengan penanganan port dinamis Railway ($PORT)
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'PORT="${PORT:-7681}"' >> /start.sh && \
    echo 'exec ttyd -p "$PORT" -i 0.0.0.0 -W bash' >> /start.sh && \
    chmod +x /start.sh

# Expose port (opsional)
EXPOSE 22

# Jalankan script
CMD ["/start.sh"]
