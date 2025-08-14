# N8N — Production-ready n8n on Ubuntu (Docker + PostgreSQL + Caddy + Let’s Encrypt)

This repository provides an **interactive installer** for **n8n** with **PostgreSQL** and **Caddy** reverse-proxy, automatic HTTPS via **Let’s Encrypt**, optional **staging** CA, and a set of helper scripts (**switch_ca.sh**, **oauth_info.sh**, **uninstall.sh**).  
The installer supports **EN/RU**, **OAuth** redirect URIs, **Telegram-friendly** HTTPS on **443**, and performs critical **permissions fixes** to prevent common crashes.

> Repo: `https://github.com/evdokimenkoiv/N8N`

---

## Quick start (Ubuntu)

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh
```

At the end the installer prints:  
**“All set! Now open `https://<domain>/` in your browser to finish the initial n8n setup.”**

---

## What the installer does (high level)

1. **Language**: asks for EN/RU.  
2. **Prompts**: domain (FQDN), email for LE, timezone, install directory, Postgres tag, n8n image tag (**stable** recommended; `latest` or **custom** supported), optional UFW.  
3. **Certificate Authority**: choose **Let’s Encrypt (prod)** or **Let’s Encrypt (staging)** (staging is NOT trusted by browsers).  
4. **DNS & public IP checks**: warns if DNS doesn’t point to this server public IP, and if **no public (routable) IP** is detected on interfaces (NAT/CGNAT).  
5. **Installs Docker & Compose v2** (if missing).  
6. **Generates secrets** → writes `.env` (includes **persistent** `N8N_ENCRYPTION_KEY`).  
7. **Fixes data directory permissions** (common crash fix): `./n8n_data` owned by **1000:1000**, `./postgres` by **999:999**.  
8. **Creates** `Caddyfile` (with `email` + `acme_ca`) and `docker-compose.yml` (Postgres **healthcheck**; n8n depends on **service_healthy**).  
9. **Optional firewall**: opens 22/80/443 with UFW.  
10. **Starts** the stack and waits for HTTPS.  
11. Prints **OAuth** redirect URIs and final browser instruction.

---

## Files & layout

- `install_n8n.sh` — interactive installer (EN/RU)  
- `switch_ca.sh` — switch CA (LE prod/staging) + **container restart**; optional **force re-issue** (deletes old certs inside Caddy and restarts)  
- `oauth_info.sh` — prints OAuth **redirect URIs**; works from **any directory**: tries Docker → `.env` in a user-specified install dir → manual input  
- `uninstall.sh` — stops and removes the stack (data folders are not deleted unless explicitly scripted)  
- `docker-compose.yml`, `Caddyfile`, `.env` — created in your chosen install directory (default `/opt/n8n`)  
- Data directories: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`

---

## Ports, networking, and Telegram

- Public access is via **HTTPS 443** (and **HTTP 80** for ACME).  
- n8n listens on **5678** **inside** Docker; do **not** expose it publicly in production.  
- **Telegram** accepts 443/80/88/8443 — this setup uses **443**, suitable for webhooks.  
- `WEBHOOK_URL=https://<domain>/` ensures proper public webhook URLs.

---

## OAuth for n8n

Use these redirect URIs in your OAuth provider settings (Google, GitHub, Azure, etc.):  
- **OAuth2**: `https://<domain>/rest/oauth2-credential/callback`  
- **OAuth1**: `https://<domain>/rest/oauth1-credential/callback`

You can re-print them anytime:
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N/main/oauth_info.sh -o oauth_info.sh
chmod +x oauth_info.sh && ./oauth_info.sh
```
`oauth_info.sh` auto-detects domain from the running Docker container (reads `N8N_HOST`), or from `.env` in a directory you specify, or asks you to type it.

---

## No public IP (NAT/CGNAT): limitations & workarounds

If the server has **no directly-assigned public IP**, the installer warns you. The stack will still run, but expect limitations:

- **Automatic HTTPS** (ACME HTTP-01 / TLS-ALPN-01) may fail; LE must reach ports **80/443** from the Internet.  
- **External webhooks** (Telegram, Stripe, GitHub, etc.) and **OAuth** callbacks need a **public HTTPS endpoint**.  
- Browser access from the Internet won’t work without a routable address or a tunnel (SSH tunnel works for local access).

**Workarounds**:
1. Port forwarding of **80/tcp** and **443/tcp** to this host; point DNS `A/AAAA` to your public IP.  
2. **Cloudflare Tunnel** (cloudflared) — expose your domain without opening ports (TLS at Cloudflare).  
3. **Tailscale Funnel** — publish your n8n via Tailscale with HTTPS.  
4. **Reverse SSH tunnel** to a VPS with a public IP, proxy there with Caddy/NGINX.  
5. **Dev only**: temporary exposure via SSH port-forwarding or a dev tunnel (ngrok/cloudflared) for testing.

> The public-IP check is heuristic. Some clouds assign only private NICs but map a public IP with 1:1 NAT. If DNS already points to a reachable public IP with ports 80/443 forwarded to this host, you can ignore the warning.

---

## Choosing the n8n image tag

During install, you pick the **n8n** tag:
- **stable** — recommended for production (default).  
- **latest** — newest features, may be unstable.  
- **custom** — type an explicit tag (e.g., `1.81.1` or `nightly`).

The choice is saved to `.env` as `N8N_IMAGE_TAG` and used in `docker-compose.yml`.

**Change later**:
1. Edit `.env` → `N8N_IMAGE_TAG=<new-tag>`  
2. `sudo docker compose pull && sudo docker compose up -d`

---

## Persistent encryption key (critical)

The installer creates **`N8N_ENCRYPTION_KEY`** and writes it to `.env`, then passes it into the container.  
**Keep this key safe** — existing credentials become unreadable if the key is lost or changed.

Back up at least:
```
.env
n8n_data/
postgres/
caddy_data/
caddy_config/
```

> Re-running the installer over an existing deployment can overwrite `.env` (thus the key). **Avoid** re-running on top of production without a backup and manual review.

---

## Troubleshooting (quick cheats)

- Check statuses:
  ```bash
  sudo docker compose ps
  ```

- Logs (last 200 lines):
  ```bash
  sudo docker compose logs --tail=200 n8n
  sudo docker compose logs --tail=200 postgres
  sudo docker compose logs --tail=200 caddy
  ```

- Reverse-proxy upstream test (from inside Caddy):
  ```bash
  sudo docker compose exec caddy sh -lc 'apk add --no-cache curl >/dev/null 2>&1 || true; curl -sI http://n8n:5678 | head -n1'
  ```

- Fix common permissions problems:
  ```bash
  sudo chown -R 1000:1000 /opt/n8n/n8n_data
  sudo chown -R 999:999  /opt/n8n/postgres
  sudo docker compose restart n8n postgres
  ```

- Wait for Postgres before n8n: Compose already includes **healthcheck** and `depends_on: service_healthy`.

- 502 from Caddy but LE cert OK? Usually `n8n` is down/restarting or cannot reach Postgres.

- Temporary publish `5678` for diagnostics only:
  ```yaml
  # in docker-compose.yml (temporary!)
  ports:
    - "5678:5678"
  ```
  Then:
  ```bash
  sudo docker compose up -d
  curl -I http://<server_ip>:5678
  ```

---

## Switching the certificate authority

Use `switch_ca.sh` to change between **LE prod** and **LE staging**:
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N/main/switch_ca.sh -o switch_ca.sh
chmod +x switch_ca.sh && ./switch_ca.sh
```
- The script updates `acme_ca` in `Caddyfile`, **restarts** Caddy, and optionally **forces re-issue** by deleting old certs inside the container and restarting again.

> LE **staging** is for testing; browsers will not trust staging certs.

---

## Security notes

- Keep `.env` private (contains secrets including `N8N_ENCRYPTION_KEY`).  
- Do not expose port **5678** publicly. Use the Caddy HTTPS endpoint only.  
- Consider regular OS updates and container image updates:
  ```bash
  sudo docker compose pull && sudo docker compose up -d
  ```

---

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
This stops and removes containers/networks. Data directories remain unless the script explicitly deletes them (review before use).
