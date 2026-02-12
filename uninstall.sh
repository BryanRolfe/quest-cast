#!/usr/bin/env bash
# Quest Cast — uninstaller (handles both Docker and local installs)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUND=false

# ── Docker ───────────────────────────────────────────────────────
if command -v docker &>/dev/null && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q quest-cast; then
    FOUND=true
    echo "==> Found Docker install, removing…"
    cd "${SCRIPT_DIR}"
    docker compose down --rmi all --volumes 2>/dev/null || docker rm -f quest-cast 2>/dev/null || true
    echo "    ✅ Docker container, image, and volume removed"
fi

# ── Local (supervisor) ───────────────────────────────────────────
if [ -f /etc/supervisor/conf.d/quest-cast.conf ]; then
    FOUND=true
    if [[ $EUID -ne 0 ]]; then
        echo "Local install detected — re-run with sudo:  sudo ./uninstall.sh"
        exit 1
    fi

    echo "==> Found local install, removing…"
    supervisorctl stop all 2>/dev/null || true
    rm -f /etc/supervisor/conf.d/quest-cast.conf
    supervisorctl reread 2>/dev/null || true
    supervisorctl update 2>/dev/null || true
    rm -rf /var/log/quest-cast
    echo "    ✅ Supervisor config and logs removed"
fi

if [ "$FOUND" = false ]; then
    echo "No Quest Cast installation found."
    exit 0
fi

echo ""
echo "✅ Quest Cast uninstalled!"
echo ""
echo "   Chrome profile was left intact. To remove it:"
echo "     rm -rf ~/.config/quest-cast-chrome"
