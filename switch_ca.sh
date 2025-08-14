#!/usr/bin/env bash
set -euo pipefail

bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
info()   { printf "[-] %s\n" "$*"; }
ok()     { printf "[✓] %s\n" "$*"; }
warn()   { printf "[!] %s\n" "$*"; }
err()    { printf "[✗] %s\n" "$*"; }

trap 'err "${T_ERR:-Switch failed. See logs above.}"; exit 1' ERR

# Language (default EN)
read -rp "Select language / Выберите язык [en/ru] (en): " LANG_CHOICE
LANG_CHOICE="${LANG_CHOICE,,}"
if [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]]; then LANG_CHOICE="en"; fi

if [[ "$LANG_CHOICE" == "ru" ]]; then
  T_TITLE="=== Переключение сервиса сертификатов для Caddy ==="
  P_DIR="Каталог установки [/opt/n8n]: "
  P_CA="Выберите сервис: 1) Let’s Encrypt (prod), 2) Let’s Encrypt (staging — НЕ доверяется браузерами). Введите [1/2] (1): "
  P_FORCE="Принудительно перевыпустить сертификат (удалить старые)? [y/N]: "
  M_NOFILE="Файл Caddyfile не найден в каталоге: %s"
  M_NODEV="docker-compose.yml не найден в каталоге: %s"
  M_UPD="Обновляю Caddyfile и перезапускаю Caddy..."
  M_FORCE="Удаляю старые сертификаты в контейнере Caddy для домена %s ..."
  M_DONE="Готово."
  T_ERR="Ошибка переключения. Смотрите лог выше."
else
  T_TITLE="=== Switch certificate authority for Caddy ==="
  P_DIR="Install directory [/opt/n8n]: "
  P_CA="Choose CA: 1) Let’s Encrypt (prod), 2) Let’s Encrypt (staging — NOT trusted by browsers). Enter [1/2] (1): "
  P_FORCE="Force re-issue (delete old certs)? [y/N]: "
  M_NOFILE="Caddyfile not found in directory: %s"
  M_NODEV="docker-compose.yml not found in directory: %s"
  M_UPD="Updating Caddyfile and restarting Caddy..."
  M_FORCE="Deleting old certs inside Caddy container for domain %s ..."
  M_DONE="Done."
  T_ERR="Switch failed. See logs above."
fi

bold "$T_TITLE"

read -rp "$P_DIR" INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/opt/n8n}"
CADDYFILE="${INSTALL_DIR}/Caddyfile"
COMPOSE="${INSTALL_DIR}/docker-compose.yml"

if [[ ! -f "$CADDYFILE" ]]; then
  printf "$M_NOFILE\n" "$INSTALL_DIR"; exit 1
fi
if [[ ! -f "$COMPOSE" ]]; then
  printf "$M_NODEV\n" "$INSTALL_DIR"; exit 1
fi

read -rp "$P_CA" CA_SEL
CA_SEL="${CA_SEL:-1}"
if [[ "$CA_SEL" == "2" ]]; then
  ACME_URL="https://acme-staging-v02.api.letsencrypt.org/directory"
else
  ACME_URL="https://acme-v02.api.letsencrypt.org/directory"
fi

# Ensure acme_ca line exists or is replaced
if grep -qE '^\s*acme_ca\s+' "$CADDYFILE"; then
  sed -i "s#^\s*acme_ca\s\+.*#  acme_ca ${ACME_URL}#g" "$CADDYFILE"
else
  # insert after email line inside global options block
  sed -i "/^\s*email\s\+.*$/a \  acme_ca ${ACME_URL}" "$CADDYFILE"
fi

info "$M_UPD"
sudo docker compose -f "$COMPOSE" up -d caddy

# Force re-issue?
read -rp "$P_FORCE" FORCE
FORCE="${FORCE:-N}"
if [[ "${FORCE^^}" == "Y" ]]; then
  # Try to get DOMAIN from .env; fallback to ask
  DOMAIN="$(grep -E '^DOMAIN=' "${INSTALL_DIR}/.env" 2>/dev/null | head -n1 | cut -d= -f2- || true)"
  if [[ -z "${DOMAIN:-}" ]]; then
    read -rp "Domain / Домен (FQDN): " DOMAIN
  fi
  if [[ -n "${DOMAIN:-}" ]]; then
    printf "$M_FORCE\n" "$DOMAIN"
    sudo docker compose -f "$COMPOSE" exec -T caddy sh -lc "rm -rf /data/caddy/certificates/*/*${DOMAIN}* || true && caddy reload --config /etc/caddy/Caddyfile || true"
  fi
fi

ok "$M_DONE"
