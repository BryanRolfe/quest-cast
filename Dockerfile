FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    RESOLUTION=1920x1080x24

# ── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        # X virtual framebuffer + VNC
        xvfb x11vnc \
        # Window manager (lightweight)
        openbox \
        # noVNC + websockify
        novnc websockify \
        # Chrome dependencies
        fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libcups2 \
        libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 \
        libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 xdg-utils \
        libasound2 libpango-1.0-0 libcairo2 libxss1 libxtst6 \
        libvulkan1 wget \
        # Intel GPU / VA-API
        intel-media-va-driver vainfo \
        # Utilities
        curl procps supervisor \
    && rm -rf /var/lib/apt/lists/*

# ── Install Google Chrome ────────────────────────────────────────
RUN curl -fSL -o /tmp/chrome.deb \
        'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' \
    && apt-get update && apt-get install -yf /tmp/chrome.deb \
    && rm -rf /tmp/chrome.deb /var/lib/apt/lists/*

# ── Create non-root user ────────────────────────────────────────
RUN useradd -m -s /bin/bash quest \
    && mkdir -p /home/quest/.config/quest-cast-chrome \
    && chown -R quest:quest /home/quest

# ── Supervisor config ───────────────────────────────────────────
COPY supervisord.conf /etc/supervisor/conf.d/quest-cast.conf

# ── Entrypoint ──────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6080

ENTRYPOINT ["/entrypoint.sh"]
