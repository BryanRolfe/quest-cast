# 🥽 Quest Cast

> **Cast your Meta Quest 3 to any device on your network — no apps needed.**

A headless Linux server runs Chrome on Meta's casting page behind a noVNC web viewer. Open a URL from your phone, tablet, laptop — anything with a browser — and watch your Quest stream instantly.

---

## ✨ How It Works

**Xvfb** (virtual display) → **Chrome** (casting receiver) → **x11vnc** (screen capture) → **noVNC** (web viewer)

Intel VA-API provides hardware-accelerated video decoding via GPU passthrough. 🚀

---

## 📋 Requirements

- 🐧 Linux host (tested on Ubuntu 22.04, Debian 12)
- 🎮 Intel GPU with VA-API support
- 👤 Meta account linked to your Quest 3
- 🐳 Docker **or** sudo access

---

## 🐳 Docker Install (Recommended)

```bash
git clone https://github.com/BryanRolfe/quest-cast.git
cd quest-cast
docker compose up -d --build
```

```bash
docker compose ps              # 📊 status
docker compose logs -f         # 📜 logs
docker compose restart         # 🔄 restart
docker compose down            # ⏹️  stop
docker compose up -d --build   # 🔨 rebuild
```

<details>
<summary>⚙️ Configuration</summary>

| Setting | Default | How to Change |
|---------|---------|---------------|
| noVNC port | `6080` | Change `ports` in `docker-compose.yml` |
| Resolution | `1920x1080x24` | Set `RESOLUTION` env var |
| Shared memory | `2 GB` | Change `shm_size` in `docker-compose.yml` |

</details>

---

## 🖥️ Local Install

```bash
git clone https://github.com/BryanRolfe/quest-cast.git
cd quest-cast
sudo ./install.sh
```

Installs everything, sets up supervisor, starts automatically, survives reboots. ✅

```bash
sudo supervisorctl status          # 📊 status
sudo supervisorctl restart all     # 🔄 restart
sudo supervisorctl stop all        # ⏹️  stop
```

Logs → `/var/log/quest-cast/`

---

## 🚀 First-Time Setup

1. 🌐 Open `http://<server-ip>:6080/vnc.html` in any browser
2. 🔑 Log in to your Meta account on the casting page
3. 🥽 On Quest 3: **Quick Settings → Cast → Computer**
4. ✅ Done! Casting persists across restarts — no re-login for weeks

View the stream from any device on your network at `http://<server-ip>:6080/vnc.html` — no app required. 📱

---

## 🗑️ Uninstall

```bash
./uninstall.sh        # Docker
sudo ./uninstall.sh   # local (or both)
```

Auto-detects the install type. Chrome profile (`~/.config/quest-cast-chrome`) is left intact.

---

## 📺 Twitch Streaming

Stream your Quest cast directly to Twitch with hardware-accelerated encoding (Intel VA-API).

### Getting Your Stream Key

1. Go to [dashboard.twitch.tv/settings/stream](https://dashboard.twitch.tv/settings/stream)
2. Click **Copy** next to your Primary Stream Key
3. Keep this secret — anyone with the key can stream to your channel

### Docker

Add your stream key to `docker-compose.yml` under the `environment` section:

```yaml
    environment:
      - RESOLUTION=1920x1080x24
      - TWITCH_STREAM_KEY=live_xxxxxxxxxxxx   # ← your key here
      - TWITCH_AUTOSTART=true                 # ← set to true to stream on startup
```

Then rebuild:

```bash
docker compose up -d --build
```

Or start/stop the stream on-demand without editing the file:

```bash
docker exec quest-cast supervisorctl start twitch-stream    # ▶️  go live
docker exec quest-cast supervisorctl stop twitch-stream     # ⏹️  stop
```

### Local Install

Edit `/etc/supervisor/conf.d/quest-cast.conf` and replace `CHANGE_ME` with your Twitch stream key, then:

```bash
sudo supervisorctl reread && sudo supervisorctl update
sudo supervisorctl start twitch-stream    # ▶️  go live
sudo supervisorctl stop twitch-stream     # ⏹️  stop
```

---

## ⚠️ Limitations

- 🌐 Cast stream routes through **Meta's cloud servers** (requires internet, adds some latency)
- 🔑 Meta login session expires after a few weeks — occasional re-login needed
- 🖼️ Video is cropped to ~16:9 from the right-eye view
