#!/usr/bin/env bash
set -e

# Ensure the Chrome profile dir exists and is owned by quest
mkdir -p /home/quest/.config/quest-cast-chrome
chown -R quest:quest /home/quest/.config/quest-cast-chrome

# Fix permissions on /dev/dri if present (Intel GPU passthrough)
if [ -d /dev/dri ]; then
    chmod -R 777 /dev/dri 2>/dev/null || true
    echo "[quest-cast] GPU devices:"
    ls -la /dev/dri/
fi

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/quest-cast.conf
