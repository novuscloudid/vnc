# Menggunakan base image Debian Bookworm (versi stabil)
FROM debian:bookworm-slim

# Mencegah prompt interaktif selama instalasi package
ENV DEBIAN_FRONTEND=noninteractive

# Update sistem dan install tools esensial serta ttyd (web terminal)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    sudo \
    procps \
    net-tools \
    openssh-server \
    ttyd \
    && rm -rf /var/lib/apt/lists/*

# Konfigurasi SSH Server
RUN mkdir /var/run/sshd

# Set password root menjadi "root123" (SILAHKAN GANTI DI BAWAH INI)
RUN echo 'root:root123' | chpasswd

# Izinkan root login via SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise, user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/profile

# Expose port SSH (22) dan port Ttyd (7681)
EXPOSE 22 7681

# Buat script startup untuk menjalankan SSH dan Ttyd secara bersamaan
RUN echo '#!/bin/bash\nservice ssh start\nttyd -p 7681 -i 0.0.0.0 -W bash' > /start.sh && chmod +x /start.sh

# Jalankan script startup saat container menyala
CMD ["/start.sh"]
