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

---

## No public IP (NAT/CGNAT): limitations & workarounds

If the server has **no directly-assigned public IP** (behind NAT/CGNAT), the installer will warn you. The stack will still run, but expect these **limitations**:

- **Automatic HTTPS (ACME HTTP-01 / TLS-ALPN-01)** may fail because Let’s Encrypt must reach ports **80/443** from the Internet. Without inbound reachability, no trusted certificate will be issued.
- **External webhooks** (Telegram, Stripe, GitHub, etc.) require a **public HTTPS endpoint**. Delivery will fail if your instance isn’t reachable from the Internet.
- **OAuth flows** (Google/GitHub/Azure, etc.) need a public callback (`/rest/oauth*`). They will not complete without inbound reachability.
- **Telegram**: you can technically use a self-signed cert by uploading it on `setWebhook`, but **your server must still be reachable** from the Internet.
- Browser access from the public Internet will not work without a routable address or a tunnel. Local access (SSH tunnel) is still possible.

**Workarounds** (choose one):

1. **Port forwarding on your router / firewall**: forward **80/tcp and 443/tcp** to this host; make DNS `A/AAAA` point to your public IP; open the ports in any firewalls.
2. **Cloudflare Tunnel** (cloudflared): expose your domain without opening ports; terminate TLS at Cloudflare. Adjust Caddy to serve HTTP origin (or use CF Origin Cert / Full Strict).
3. **Tailscale Funnel**: publish your n8n service via Tailscale with HTTPS.
4. **Reverse SSH tunnel** to a VPS with a public IP, then proxy from that VPS (Caddy/NGINX) to your local n8n.
5. **Development only**: temporarily expose `5678` locally and use **SSH port-forwarding** or a dev tunnel (e.g., ngrok/Cloudflared) for testing webhooks.

> The installer’s public-IP check is heuristic. Some cloud providers assign only private NICs but still map a public IP with 1:1 NAT. If your domain already points to a reachable public IP with ports 80/443 forwarded to this host, you can ignore the warning.


**Tip:** `oauth_info.sh` can **auto-detect** your domain from the running Docker container (looks for label `com.docker.compose.service=n8n` and reads `N8N_HOST`). If that fails, it can read `.env` from an install directory you specify, or ask you to type the domain manually.
