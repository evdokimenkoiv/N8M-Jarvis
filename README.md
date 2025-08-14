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
The installer will print: **“All set! Now open https://<domain>/ in your browser to finish the initial n8n setup.”**

---

## What the installer does

1. **Language selection (EN/RU)**  
2. **Prompts for** domain, LE e-mail, time zone, install directory, Postgres tag, UFW option.  
3. **Choose n8n image tag**: **stable** *(recommended)*, **latest**, or a **custom** tag (e.g. `1.81.1`, `nightly`). The choice is stored as `N8N_IMAGE_TAG` and used in Compose.  
4. **Choose certificate authority**: Let’s Encrypt **production** (trusted) or **staging** (NOT trusted).  
5. **DNS awareness** (warns if A/AAAA doesn’t match server public IP).  
6. **Installs Docker + compose v2** if missing.  
7. **Prepares install dir** and generates secrets → writes `.env`.  
8. **Creates data directories and fixes permissions** (`./n8n_data` → UID/GID **1000:1000**, `./postgres` → **999:999**).  
9. **Creates** `Caddyfile` and `docker-compose.yml` (with Postgres **healthcheck** & `depends_on: service_healthy`).  
10. **(Optional) Configures UFW** (22/80/443).  
11. **Starts** the stack and waits for HTTPS readiness.  
12. Prints **OAuth** redirect URIs (OAuth2 & OAuth1) and the final browser instruction.

---

## OAuth (Google/GitHub/Azure/etc.)

Use these redirect URIs in your provider settings:

- **OAuth2**: `https://<domain>/rest/oauth2-credential/callback`  
- **OAuth1**: `https://<domain>/rest/oauth1-credential/callback`

> The installer prints these at the end, and you can run `./oauth_info.sh` later to display them again.

In n8n, go to **Credentials**, create the corresponding OAuth credential and click **Connect**.
