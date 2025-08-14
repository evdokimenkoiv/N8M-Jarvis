# N8M-Jarvis
Simply Install N8N on your own server/

**Fast start from Github / Быстрый запуск с GitHub**

# install
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh

# uninstall (при необходимости)
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh



# n8n + PostgreSQL + Caddy (Let’s Encrypt) — One-Command Installer

Interactive installer asks for language (EN/RU), domain, Let’s Encrypt e-mail, time zone, install directory, Postgres tag, UFW, and optional **STAGING** CA.  
It installs Docker/Compose and deploys **n8n**, **PostgreSQL**, and **Caddy** with automatic HTTPS certificates.  
`WEBHOOK_URL` is `https://<domain>/`, so Telegram webhooks work on port **443** (no custom ports needed).

## Quick start (Ubuntu)
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh


After installation, open https://<domain>/ and create the first n8n admin user.

Update
bash
Копировать
Редактировать
cd /opt/n8n           # or your chosen directory
sudo docker compose pull
sudo docker compose up -d
Uninstall
bash
Копировать
Редактировать
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
The uninstaller stops the stack and can optionally remove Docker volumes (persistent data), the install directory, and even Docker Engine.

Backups
Keep: n8n_data/, postgres/, and Caddy volumes (caddy_data, caddy_config).
To restore, place these back into the install directory and run sudo docker compose up -d.

Примечания (RU)
DNS A/AAAA вашего домена должен указывать на публичный IP сервера до выпуска сертификата.

Caddy сам получает и продлевает сертификаты Let’s Encrypt (certbot/cron не нужен).

Telegram принимает вебхуки на портах 443/80/88/8443 — мы используем 443.


