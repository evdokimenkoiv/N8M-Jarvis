# N8M-Jarvis — n8n + PostgreSQL + Caddy (Let’s Encrypt)

Interactive installer that deploys **n8n**, **PostgreSQL**, and **Caddy** with automatic HTTPS certificates via Let’s Encrypt.  
The first prompt asks for **language (EN/RU)** — English is the default. Telegram webhooks work out of the box on **port 443** thanks to the reverse proxy.

> Repository: https://github.com/evdokimenkoiv/N8M-Jarvis

## Quick start (Ubuntu)
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh
```

After installation, open `https://<domain>/` and create the first n8n admin user.

---

## What the installer does (step by step)

1. **Language selection (EN/RU)**  
   Prompts you to choose the interface language for the session.

2. **Collects inputs**  
   - **Domain (FQDN)** — e.g. `automation.example.com`  
   - **Let’s Encrypt e‑mail** — used by the CA for notifications (default: `admin@<domain>`)  
   - **Time zone** — applied to n8n (default: `Europe/Amsterdam`)  
   - **Install directory** — where files & data live (default: `/opt/n8n`)  
   - **PostgreSQL image tag** — e.g. `15-alpine` (default)  
   - **UFW setup** — open ports **22/80/443** and enable firewall (optional)  
   - **LE STAGING CA** — use Let’s Encrypt staging endpoint for testing (optional)

3. **Pre-flight DNS awareness** (best-effort)  
   Resolves your domain and compares it to the server’s public IP; warns if they differ (issuance may fail until DNS propagates).

4. **Installs Docker Engine + compose v2** (if not present)  
   Adds Docker APT repo, installs `docker-ce`, `docker-compose-plugin`, etc.

5. **Prepares install directory**  
   Creates the chosen directory (default `/opt/n8n`) and switches into it.

6. **Generates secrets & writes `.env`**  
   - `POSTGRES_PASSWORD` — random strong password  
   - `N8N_ENCRYPTION_KEY` — used by n8n to encrypt credentials  
   - Base variables (domain, email, timezone, Postgres tag)  
   - n8n URLs: `N8N_EDITOR_BASE_URL`, `WEBHOOK_URL` set to **`https://<domain>/`**

7. **Creates a `Caddyfile`**  
   - Configures ACME email and optionally **staging** CA  
   - Proxies `https://<domain>/` → `n8n:5678`  
   - Caddy will automatically obtain and **renew** certificates (no certbot needed).

8. **Creates `docker-compose.yml`** with three services:  
   - `postgres` — persistent database for n8n  
   - `n8n` — workflow automation engine (uses the DB and env from `.env`)  
   - `caddy` — reverse proxy terminating TLS on **80/443** (auto HTTPS)  
   Data is persisted via bind mounts/volumes in the install directory.

9. **(Optional) Configures UFW**  
   Opens **OpenSSH/HTTP/HTTPS** and enables `ufw` if present.

10. **Starts the stack**  
    Runs `docker compose up -d`, waits up to ~60s for `https://<domain>` to respond, then prints helpful next steps.

---

## Requirements & assumptions

- Ubuntu server with `sudo` access (tested on modern LTS releases).  
- Public **ports 80 and 443** reachable from the Internet.  
- DNS **A/AAAA** record for your domain points to the server’s public IP.  
- Outbound HTTPS allowed (Caddy needs to talk to Let’s Encrypt).

---

## Files and data layout (inside install directory)

- `docker-compose.yml` — service definitions  
- `Caddyfile` — reverse-proxy and ACME settings  
- `.env` — generated secrets and environment variables  
- `n8n_data/` — n8n persistent data (credentials, settings, etc.)  
- `postgres/` — PostgreSQL data directory  
- `caddy_data/`, `caddy_config/` — Caddy certificate storage/config volumes

> **Keep `.env` and `n8n_data/` safe** — they contain encryption material and application state.

---

## Network & webhooks

- External access is via **HTTPS 443** (and HTTP 80 for ACME).  
- `WEBHOOK_URL=https://<domain>/` ensures n8n generates public webhook URLs without exposing port 5678.  
- **Telegram** accepts webhooks on 443/80/88/8443 — 443 is used here, so no extra port work is required.

---

## Operations

### Update n8n / images
```bash
cd /opt/n8n               # or your chosen path
sudo docker compose pull
sudo docker compose up -d
```

### Backup
- Save: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`, and `.env`.

### Restore
- Place the saved folders back into your install directory and run:
```bash
sudo docker compose up -d
```

### Uninstall
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
You can choose to remove volumes (persistent data), the install directory, and even Docker Engine.

---

## Changing domain after install

1. Stop the stack: `sudo docker compose down`  
2. Update `DOMAIN` (and related URLs) in `.env` and `Caddyfile`  
3. Start again: `sudo docker compose up -d`

> Certificates will be reissued for the new domain by Caddy automatically (ensure DNS is updated and ports 80/443 are open).

---

## Troubleshooting

- **Certificate issuance failed / still HTTP only**  
  - Ensure DNS points to the server public IP and has propagated.  
  - Confirm ports **80/443** are open in any cloud/provider firewall and `ufw`.  
  - Check logs: `sudo docker logs caddy | grep -Ei 'acme|certificate|obtaining|renew'`

- **Using staging first, then switching to production**  
  - Re-run the installer without the staging option **or** edit `Caddyfile` to remove the `acme_ca` line, then:  
    ```bash
    sudo docker compose up -d
    ```

- **Port conflicts**  
  - If another daemon already uses 80/443, stop/disable it or change its ports. Caddy must bind 80/443 to get and serve certificates.

---

## Uninstaller script

`uninstall.sh` stops and removes the stack, and optionally deletes:  
- Docker **volumes** (data loss!),  
- the **install directory** (files/configs),  
- **Docker Engine** packages that were installed via APT.

---
