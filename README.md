# N8M-Jarvis — n8n + PostgreSQL + Caddy (Let’s Encrypt)

Interactive installer that deploys **n8n**, **PostgreSQL**, and **Caddy** with automatic HTTPS certificates via Let’s Encrypt.  
First prompt asks for **language (EN/RU)** — English is default. Telegram webhooks work out of the box on **port 443**.

> Repository: https://github.com/evdokimenkoiv/N8M-Jarvis

## Quick start (Ubuntu)
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh
```

After installation, open `https://<domain>/` and create the first n8n admin user.

---

## What the installer does

1. **Language selection (EN/RU)**  
2. **Prompts for** domain, LE e-mail, time zone, install directory, Postgres tag, UFW option.  
3. **Choose n8n image tag**: **stable** *(recommended)*, **latest**, or a **custom** tag (e.g. `1.81.1`, `nightly`). The choice is stored as `N8N_IMAGE_TAG` and used in Compose.  
4. **Choose certificate authority**: Let’s Encrypt **production** (trusted) or **staging** (NOT trusted).  
5. **DNS awareness** (warns if A/AAAA doesn’t match server public IP).  
6. **Installs Docker + compose v2** if missing.  
7. **Prepares install dir** and generates secrets → writes `.env`.  
8. **Creates data directories and fixes permissions** (`./n8n_data` → UID/GID **1000:1000**, `./postgres` → **999:999**). This eliminates a common crash where n8n/postgres can’t write to bind-mounted folders.  
9. **Creates** `Caddyfile` and `docker-compose.yml` (with Postgres **healthcheck** & `depends_on: service_healthy`).  
10. **(Optional) Configures UFW** (22/80/443).  
11. **Starts** the stack and waits for HTTPS readiness.

### Files & layout
- `docker-compose.yml`, `Caddyfile`, `.env`  
- Data: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`

### Webhooks & networking
- Public endpoint via **HTTPS 443** (HTTP 80 for ACME).  
- `WEBHOOK_URL=https://<domain>/` ensures proper public webhook URLs.  
- Telegram allows 443/80/88/8443 — 443 is used here.

---

## Switch certificate authority later

Use the helper:

```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/switch_ca.sh -o switch_ca.sh
chmod +x switch_ca.sh && ./switch_ca.sh
```
- Choose **prod** or **staging**.  
- The script **restarts** the Caddy container to apply changes.  
- Optional **force re-issue**: deletes old certs inside Caddy and restarts again to trigger fresh issuance.

> Note: Staging certificates are intentionally untrusted in browsers.

---

## Operations

**Update images**
```bash
cd /opt/n8n   # or your chosen directory
sudo docker compose pull
sudo docker compose up -d
```

**Backup**
Save: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`, and `.env`.

**Restore**
Place the folders back and run `sudo docker compose up -d`.

**Uninstall**
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
