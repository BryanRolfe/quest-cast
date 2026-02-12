#!/usr/bin/env bash
# Quest Cast — local (non-Docker) installer for Ubuntu/Debian
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_USER="${SUDO_USER:-$USER}"
CHROME_DATA="/home/${SERVICE_USER}/.config/quest-cast-chrome"
RESOLUTION="1920x1080x24"

# ── Must run as root ─────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo:  sudo ./install.sh"
    exit 1
fi

echo "==> Installing Quest Cast for user: ${SERVICE_USER}"

# ── System packages ─────────────────────────────────────────────
echo "==> Installing system packages…"
apt-get update
apt-get install -y --no-install-recommends \
    xvfb x11vnc openbox \
    novnc websockify \
    fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libcups2 \
    libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 \
    libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 xdg-utils \
    libasound2 libpango-1.0-0 libcairo2 libxss1 libxtst6 \
    libvulkan1 wget \
    intel-media-va-driver vainfo \
    supervisor

# ── Google Chrome ────────────────────────────────────────────────
if ! command -v google-chrome &>/dev/null; then
    echo "==> Installing Google Chrome…"
    curl -fSL -o /tmp/chrome.deb \
        'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
    apt-get install -yf /tmp/chrome.deb
    rm -f /tmp/chrome.deb
else
    echo "==> Google Chrome already installed, skipping"
fi

# ── Chrome profile directory ─────────────────────────────────────
mkdir -p "${CHROME_DATA}"
chown -R "${SERVICE_USER}:${SERVICE_USER}" "${CHROME_DATA}"

# ── GPU permissions ──────────────────────────────────────────────
if [ -d /dev/dri ]; then
    usermod -aG render "${SERVICE_USER}" 2>/dev/null || true
    usermod -aG video "${SERVICE_USER}" 2>/dev/null || true
    echo "==> Added ${SERVICE_USER} to render and video groups"
fi

# ── Supervisor config ────────────────────────────────────────────
echo "==> Writing supervisor config…"
cat > /etc/supervisor/conf.d/quest-cast.conf <<SUPERVISOR
[supervisord]
nodaemon=false
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:xvfb]
command=Xvfb :99 -screen 0 ${RESOLUTION} -ac +extension GLX
autorestart=true
priority=10
stdout_logfile=/var/log/quest-cast/xvfb.log
stderr_logfile=/var/log/quest-cast/xvfb-err.log

[program:openbox]
command=openbox
user=${SERVICE_USER}
environment=DISPLAY=":99"
autorestart=true
priority=20
stdout_logfile=/var/log/quest-cast/openbox.log
stderr_logfile=/var/log/quest-cast/openbox-err.log

[program:chrome]
command=google-chrome
    --no-sandbox
    --disable-gpu-sandbox
    --user-data-dir=${CHROME_DATA}
    --no-first-run
    --disable-translate
    --disable-infobars
    --disable-features=TranslateUI
    --disable-session-crashed-bubble
    --autoplay-policy=no-user-gesture-required
    --no-default-browser-check
    --disable-background-networking
    --disable-sync
    --noerrdialogs
    --start-maximized
    --enable-features=VaapiVideoDecoder,VaapiVideoEncoder
    --use-gl=angle
    --use-angle=gl
    --disable-crash-reporter
    https://www.meta.com/casting
user=${SERVICE_USER}
environment=DISPLAY=":99",HOME="/home/${SERVICE_USER}"
autorestart=true
priority=30
startsecs=5
stdout_logfile=/var/log/quest-cast/chrome.log
stderr_logfile=/var/log/quest-cast/chrome-err.log

[program:x11vnc]
command=x11vnc -display :99 -rfbport 5900 -nopw -shared -forever -noxdamage -cursor arrow
autorestart=true
priority=40
startsecs=3
stdout_logfile=/var/log/quest-cast/x11vnc.log
stderr_logfile=/var/log/quest-cast/x11vnc-err.log

[program:novnc]
command=websockify --web /usr/share/novnc 6080 localhost:5900
autorestart=true
priority=50
startsecs=3
stdout_logfile=/var/log/quest-cast/novnc.log
stderr_logfile=/var/log/quest-cast/novnc-err.log
SUPERVISOR

mkdir -p /var/log/quest-cast

# ── Enable and start ─────────────────────────────────────────────
echo "==> Starting supervisor…"
systemctl enable supervisor
systemctl restart supervisor
supervisorctl reread
supervisorctl update

echo ""
echo "✅ Quest Cast installed!"
echo ""
echo "   noVNC viewer:  http://$(hostname -I | awk '{print $1}'):6080/vnc.html"
echo "   Logs:          /var/log/quest-cast/"
echo ""
echo "   Commands:"
echo "     sudo supervisorctl status          # check status"
echo "     sudo supervisorctl restart all     # restart all"
echo "     sudo supervisorctl stop all        # stop all"
echo ""
echo "   To uninstall:  sudo ./uninstall.sh"
