# N8M-Jarvis
Simply Install N8N on your own server/



# n8n + PostgreSQL + Caddy (Let’s Encrypt) — Installer

Интерактивный установщик спрашивает язык (RU/EN), домен, e-mail для LE, часовой пояс, каталог, тэг Postgres, опции UFW и STAGING-CA.  
Автоматически ставит Docker/Compose и разворачивает `n8n`, `PostgreSQL`, `Caddy` с автоматическими сертификатами Let’s Encrypt.  
`WEBHOOK_URL` настроен на `https://<домен>/` — Telegram вебхуки будут работать на 443 порту.

## Установка (на сервере Ubuntu)
```bash
# вариант через curl
curl -fsSL https://raw.githubusercontent.com/<YOUR_ORG>/<YOUR_REPO>/main/install_n8n.sh -o install_n8n.sh
bash install_n8n.sh
