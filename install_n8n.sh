#!/usr/bin/env bash
set -euo pipefail

# --- helpers ---
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
info()   { printf "[-] %s\n" "$*"; }
ok()     { printf "[✓] %s\n" "$*"; }
warn()   { printf "[!] %s\n" "$*"; }
err()    { printf "[✗] %s\n" "$*"; }

trap 'err "${T_ERR:-Installation failed. See logs above.}"; exit 1' ERR

# --- language selection (default EN) ---
read -rp "Select language / Выберите язык [en/ru] (en): " LANG_CHOICE
LANG_CHOICE="${LANG_CHOICE,,}"
if [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]]; then LANG_CHOICE="en"; fi

if [[ "$LANG_CHOICE" == "ru" ]]; then
  T_TITLE="=== Установщик n8n (Docker + PostgreSQL + Caddy/Let’s Encrypt) ==="
  P_DOMAIN="Домен (FQDN), напр. example.com: "
  P_EMAIL="E-mail для Let’s Encrypt [admin@%s]: "
  P_TZ="Часовой пояс [Europe/Amsterdam]: "
  P_DIR="Каталог установки [/opt/n8n]: "
  P_PG="Версия PostgreSQL [15-alpine]: "
  P_TAG="Выберите тег образа n8n: 1) stable [рекомендуется], 2) latest, 3) custom. Введите [1/2/3] (1): "
  P_TAG_CUSTOM="Введите пользовательский тег n8n (например, 1.81.1, nightly, и т.п.): "
  P_UFW="Включить UFW и открыть 22/80/443? [Y/n]: "
  P_CA="Выберите сервис сертификатов: 1) Let’s Encrypt (prod) [по умолчанию], 2) Let’s Encrypt (staging — НЕ доверяется браузерами). Введите [1/2] (1): "
  M_DNSCHK1="Проверка DNS → публичного IP..."
  M_DNS_WARN="ВНИМАНИЕ: DNS %s → %s, а ваш публичный IP → %s. Выпуск сертификата может не получиться, если запись A/AAAA ещё не обновилась."
  M_DOCKER="Установка Docker и compose v2..."
  M_PREP="Подготовка каталога %s ..."
  M_ENV="Генерация секретов и .env..."
  M_DIRS="Создание каталогов данных и выставление прав (популярная причина падений n8n)..."
  M_CADDY="Создание Caddyfile..."
  M_COMPOSE="Создание docker-compose.yml..."
  M_UFW="Настройка UFW (SSH/HTTP/HTTPS)..."
  M_START="Запуск контейнеров..."
  M_WAIT="Ожидаю готовности HTTPS (до ~60 сек)..."
  M_DONE="Готово!"
  M_OPEN="Откройте: https://%s/"
  M_CERT="Проверка сертификата:    sudo docker logs caddy | grep -Ei 'acme|certificate|obtaining|renew'"
  M_PS="Статус контейнеров:      sudo docker compose -f %s/docker-compose.yml ps"
  M_TG="Telegram вебхуки: адрес будет вида https://%s/webhook/..."
  M_STAGE_NOTE="Если выбирали STAGING, браузеры НЕ доверяют таким сертификатам; для продакшена переключитесь на Let’s Encrypt prod."
  T_ERR="Ошибка установки. Смотрите лог выше."
else
  T_TITLE="=== n8n Installer (Docker + PostgreSQL + Caddy/Let’s Encrypt) ==="
  P_DOMAIN="Domain (FQDN), e.g. example.com: "
  P_EMAIL="E-mail for Let’s Encrypt [admin@%s]: "
  P_TZ="Time zone [Europe/Amsterdam]: "
  P_DIR="Install directory [/opt/n8n]: "
  P_PG="PostgreSQL image tag [15-alpine]: "
  P_TAG="Choose n8n image tag: 1) stable [recommended], 2) latest, 3) custom. Enter [1/2/3] (1): "
  P_TAG_CUSTOM="Enter custom n8n tag (e.g., 1.81.1, nightly, etc.): "
  P_UFW="Enable UFW and open 22/80/443? [Y/n]: "
  P_CA="Choose certificate authority: 1) Let’s Encrypt (prod) [default], 2) Let’s Encrypt (staging — NOT trusted by browsers). Enter [1/2] (1): "
  M_DNSCHK1="Checking DNS → public IP..."
  M_DNS_WARN="WARNING: DNS %s → %s, but your public IP is %s. Certificate issuance may fail if A/AAAA isn’t updated yet."
  M_DOCKER="Installing Docker and compose v2..."
  M_PREP="Preparing directory %s ..."
  M_ENV="Generating secrets and .env..."
  M_DIRS="Creating data directories and fixing ownership (common n8n crash cause)..."
  M_CADDY="Writing Caddyfile..."
  M_COMPOSE="Writing docker-compose.yml..."
  M_UFW="Configuring UFW (SSH/HTTP/HTTPS)..."
  M_START="Starting containers..."
  M_WAIT="Waiting for HTTPS to be ready (up to ~60s)..."
  M_DONE="Done!"
  M_OPEN="Open: https://%s/"
  M_CERT="Certificate logs:       sudo docker logs caddy | grep -Ei 'acme|certificate|obtaining|renew'"
  M_PS="Containers status:       sudo docker compose -f %s/docker-compose.yml ps"
  M_TG="Telegram webhooks: URL will be like https://%s/webhook/..."
  M_STAGE_NOTE="If you picked STAGING, browsers will NOT trust those certs; switch to Let’s Encrypt prod for production."
  T_ERR="Installation failed. See logs above."
fi

bold "$T_TITLE"

# --- inputs ---
read -rp "$P_DOMAIN" DOMAIN
while [[ -z "${DOMAIN:-}" ]]; do read -rp "$P_DOMAIN" DOMAIN; done

printf "$P_EMAIL" "$DOMAIN"
read -r EMAIL
EMAIL="${EMAIL:-admin@$DOMAIN}"

read -rp "$P_TZ" TZ
TZ="${TZ:-Europe/Amsterdam}"

read -rp "$P_DIR" INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/opt/n8n}"

read -rp "$P_PG" PG_TAG
PG_TAG="${PG_TAG:-15-alpine}"

read -rp "$P_TAG" N8N_SEL
N8N_SEL="${N8N_SEL:-1}"
case "$N8N_SEL" in
  2) N8N_IMAGE_TAG="latest" ;;
  3) read -rp "$P_TAG_CUSTOM" N8N_IMAGE_TAG ; N8N_IMAGE_TAG="${N8N_IMAGE_TAG:-stable}" ;;
  *) N8N_IMAGE_TAG="stable" ;;
esac

read -rp "$P_UFW" UFW_ANS
UFW_ANS="${UFW_ANS:-Y}"

read -rp "$P_CA" CA_SEL
CA_SEL="${CA_SEL:-1}"
if [[ "$CA_SEL" == "2" ]]; then
  ACME_URL="https://acme-staging-v02.api.letsencrypt.org/directory"
else
  ACME_URL="https://acme-v02.api.letsencrypt.org/directory"
fi

# --- preflight: DNS awareness (best-effort) ---
info "$M_DNSCHK1"
# --- public (white) IP detection on host ---
has_public_ip_v4=0
has_public_ip_v6=0

# parse IPv4 addresses on host
while read -r ip; do
  # skip empty
  [[ -z "$ip" ]] && continue
  # private/CGNAT ranges
  if [[ "$ip" == 10.* || "$ip" == 192.168.* || "$ip" == 127.* || "$ip" == 169.254.* ]]; then
    continue
  fi
  # 172.16.0.0 - 172.31.255.255
  if [[ "$ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\..* ]]; then
    continue
  fi
  # 100.64.0.0/10 (CGNAT)
  if [[ "$ip" =~ ^100\.(6[4-9]|[7-9][0-9]|1([0-1][0-9])|12[0-7])\..* ]]; then
    continue
  fi
  has_public_ip_v4=1
done < <(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1)

# parse IPv6 global addresses on host
while read -r ip6; do
  [[ -z "$ip6" ]] && continue
  # Exclude link-local fe80::/10, loopback ::1, and unique local fc00::/7 (fc00::/7 includes fd00::/8)
  if [[ "$ip6" =~ ^fe80:|^::1$|^(fc|fd) ]]; then
    continue
  fi
  has_public_ip_v6=1
done < <(ip -6 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1)

if [[ "$LANG_CHOICE" == "ru" ]]; then
  if [[ $has_public_ip_v4 -eq 0 && $has_public_ip_v6 -eq 0 ]]; then
    warn "Похоже, у сервера НЕТ напрямую назначенного 'белого' IP (обнаружены только приватные адреса/NAT)."
    warn "Стек поднимется, но с ограничениями (авто-HTTPS/вебхуки/OAuth могут не работать)."
    warn "Если у вас есть проброс портов 80/443 на этот хост и DNS указывает на публичный IP — всё может быть OK."
  else
    ok "Обнаружен публичный IP на интерфейсах (IPv4/IPv6)."
  fi
else
  if [[ $has_public_ip_v4 -eq 0 && $has_public_ip_v6 -eq 0 ]]; then
    warn "It looks like the host has NO directly-assigned public (routable) IP (only private/NAT)."
    warn "The stack will start, but with limitations (auto-HTTPS/webhooks/OAuth may not work)."
    warn "If you have port-forwarding of 80/443 to this host and DNS points to the public IP, you may still be fine."
  else
    ok "A public IP was detected on host interfaces (IPv4/IPv6)."
  fi
fi

PUB_IP="$(curl -fsS https://api.ipify.org || curl -fsS https://ifconfig.me || true)"
DNS_IP="$(getent ahosts "$DOMAIN" | awk '{print $1}' | head -n1 || true)"
if [[ -n "${PUB_IP:-}" && -n "${DNS_IP:-}" && "$PUB_IP" != "$DNS_IP" ]]; then
  printf "$M_DNS_WARN\n" "$DOMAIN" "$DNS_IP" "$PUB_IP"
fi

# --- docker install ---
info "$M_DOCKER"
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg openssl
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release; echo "$UBUNTU_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  ok "Docker already installed"
fi

# --- prepare dir ---
printf "$M_PREP\n" "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER":"$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- secrets & .env ---
info "$M_ENV"
POSTGRES_PASSWORD="$(openssl rand -base64 32 | tr -d "\n")"
N8N_ENCRYPTION_KEY="$(openssl rand -base64 24 | tr -d "\n")"

cat > .env <<EOF
# ---- base ----
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
GENERIC_TIMEZONE=${TZ}
PG_TAG=${PG_TAG}
N8N_IMAGE_TAG=${N8N_IMAGE_TAG}

# ---- n8n ----
N8N_HOST=${DOMAIN}
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://${DOMAIN}/
WEBHOOK_URL=https://${DOMAIN}/
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_SECURE_COOKIE=true
N8N_DIAGNOSTICS_ENABLED=false

# ---- postgres ----
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
EOF

# --- runtime dirs & permissions fix ---
info "$M_DIRS"
mkdir -p ./n8n_data ./postgres
# node user in n8n image is UID/GID 1000; postgres (alpine) commonly uses 999
sudo chown -R 1000:1000 ./n8n_data || true
sudo chown -R 999:999  ./postgres   || true

# --- Caddyfile ---
info "$M_CADDY"
{
  echo "{"
  echo "  email ${EMAIL}"
  echo "  acme_ca ${ACME_URL}"
  echo "}"
  echo
  echo "${DOMAIN} {"
  echo "  encode zstd gzip"
  echo "  reverse_proxy n8n:5678"
  echo "}"
} > Caddyfile

# --- docker-compose.yml ---
info "$M_COMPOSE"
cat > docker-compose.yml <<'YAML'
services:
  postgres:
    image: postgres:${PG_TAG}
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: n8n
    volumes:
      - ./postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U n8n -d n8n -h 127.0.0.1"]
      interval: 5s
      timeout: 3s
      retries: 20

  n8n:
    image: n8nio/n8n:${N8N_IMAGE_TAG}
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: n8n
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}
      N8N_HOST: ${DOMAIN}
      N8N_PORT: 5678
      N8N_PROTOCOL: https
      N8N_EDITOR_BASE_URL: https://${DOMAIN}/
      WEBHOOK_URL: https://${DOMAIN}/
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}
      GENERIC_TIMEZONE: ${GENERIC_TIMEZONE}
      N8N_SECURE_COOKIE: "true"
      N8N_DIAGNOSTICS_ENABLED: "false"
    volumes:
      - ./n8n_data:/home/node/.n8n

  caddy:
    image: caddy:alpine
    restart: unless-stopped
    depends_on:
      - n8n
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
YAML

# --- UFW ---
if [[ "${UFW_ANS^^}" != "N" ]]; then
  info "$M_UFW"
  if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow OpenSSH || true
    sudo ufw allow http || true
    sudo ufw allow https || true
    sudo ufw --force enable || true
  else
    warn "ufw not found — skipping firewall step."
  fi
fi

# --- start ---
info "$M_START"
sudo docker compose pull
sudo docker compose up -d

info "$M_WAIT"
for _ in $(seq 1 60); do
  if curl -fsI "https://${DOMAIN}" >/dev/null 2>&1; then break; fi
  sleep 2
done

bold "$M_DONE"
printf "$M_OPEN\n" "$DOMAIN"
echo "$M_CERT"
printf "$M_PS\n" "$INSTALL_DIR"
printf "$M_TG\n" "$DOMAIN"

# OAuth info
if [[ "$LANG_CHOICE" == "ru" ]]; then
  echo "OAuth2 redirect URI: https://${DOMAIN}/rest/oauth2-credential/callback"
  echo "OAuth1 redirect URI: https://${DOMAIN}/rest/oauth1-credential/callback"
  echo "Добавьте эти URL в настройках OAuth вашего провайдера (Google, GitHub и др.)."
else
  echo "OAuth2 redirect URI: https://${DOMAIN}/rest/oauth2-credential/callback"
  echo "OAuth1 redirect URI: https://${DOMAIN}/rest/oauth1-credential/callback"
  echo "Add these URLs to your OAuth provider settings (Google, GitHub, etc.)."
fi

echo "$M_STAGE_NOTE"

# Final browser instruction
if [[ "$LANG_CHOICE" == "ru" ]]; then
  echo "Всё готово! Теперь откройте https://${DOMAIN}/ в браузере для дальнейшей настройки n8n."
else
  echo "All set! Now open https://${DOMAIN}/ in your browser to finish the initial n8n setup."
fi
