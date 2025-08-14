#!/usr/bin/env bash
set -euo pipefail

# Choose language
read -rp "Select language / Выберите язык [en/ru] (en): " LANG
LANG="${LANG,,}"; [[ "$LANG" == "ru" || "$LANG" == "en" ]] || LANG="en"

msg() { echo "$*"; }
if [[ "$LANG" == "ru" ]]; then
  T_TITLE="=== OAuth для n8n ==="
  P_DIR="Каталог установки [/opt/n8n] (Enter, чтобы пропустить): "
  P_DOMAIN="Домен (FQDN), например: example.com: "
  E_NOENV="Файл .env не найден, пропускаю этот способ..."
  I_DOCKER_TRY="Пробую определить домен через Docker (переменная окружения N8N_HOST)..."
  I_DOCKER_OK="Найден контейнер n8n и домен из N8N_HOST: %s"
  W_DOCKER_NONE="Контейнер с меткой com.docker.compose.service=n8n не найден или Docker недоступен."
  W_NO_DOMAIN="Не удалось автоматически определить домен."
  H_DOMAIN="Введите домен вручную, если знаете."
  OAUTH_HINTS=(
    "1) В консоли провайдера OAuth (Google, GitHub, Azure и т.д.) добавьте redirect URI ниже."
    "2) В n8n: Credentials → создайте OAuth (1.0/2.0), нажмите 'Connect'."
    "3) Если домен/HTTPS только что настроены — убедитесь, что URL доступен извне."
  )
else
  T_TITLE="=== n8n OAuth ==="
  P_DIR="Install directory [/opt/n8n] (press Enter to skip): "
  P_DOMAIN="Domain (FQDN), e.g.: example.com: "
  E_NOENV=".env file not found, skipping this method..."
  I_DOCKER_TRY="Trying to detect domain from Docker (N8N_HOST env)..."
  I_DOCKER_OK="Found n8n container; domain from N8N_HOST: %s"
  W_DOCKER_NONE="No container with label com.docker.compose.service=n8n found or Docker is unavailable."
  W_NO_DOMAIN="Could not auto-detect the domain."
  H_DOMAIN="Please enter your domain manually if you know it."
  OAUTH_HINTS=(
    "1) In your OAuth provider console (Google, GitHub, Azure, etc.) add the redirect URIs below."
    "2) In n8n: Credentials → create OAuth (1.0/2.0) and click 'Connect'."
    "3) If domain/HTTPS was just set, make sure the URL is reachable from the Internet."
  )
fi

echo "$T_TITLE"

DOMAIN="${DOMAIN:-}"

# 1) Try Docker auto-detection (N8N_HOST in the running n8n container)
if command -v docker >/dev/null 2>&1; then
  msg "$I_DOCKER_TRY"
  CID="$(docker ps -q --filter "label=com.docker.compose.service=n8n" | head -n1 || true)"
  if [[ -n "${CID:-}" ]]; then
    DOMAIN="$(docker inspect "$CID" -f '{{range .Config.Env}}{{println .}}{{end}}' \
      | awk -F= '/^N8N_HOST=/{print $2; exit}')"
    if [[ -n "${DOMAIN:-}" ]]; then
      printf "$I_DOCKER_OK\n" "$DOMAIN"
    fi
  else
    msg "$W_DOCKER_NONE"
  fi
fi

# 2) If still empty, offer to read from .env in install dir
if [[ -z "${DOMAIN:-}" ]]; then
  read -rp "$P_DIR" DIR
  DIR="${DIR:-}"
  if [[ -n "$DIR" ]]; then
    if [[ -f "$DIR/.env" ]]; then
      DOMAIN="$(grep -E '^DOMAIN=' "$DIR/.env" | head -n1 | cut -d= -f2- || true)"
    else
      echo "$E_NOENV"
    fi
  fi
fi

# 3) If still empty, ask manually
if [[ -z "${DOMAIN:-}" ]]; then
  echo "$W_NO_DOMAIN"
  echo "$H_DOMAIN"
  read -rp "$P_DOMAIN" DOMAIN
fi

# Validate non-empty
if [[ -z "${DOMAIN:-}" ]]; then
  if [[ "$LANG" == "ru" ]]; then
    echo "Домен не задан — прерываю."
  else
    echo "Domain is empty — aborting."
  fi
  exit 1
fi

OAUTH2="https://${DOMAIN}/rest/oauth2-credential/callback"
OAUTH1="https://${DOMAIN}/rest/oauth1-credential/callback"

echo
echo "Domain: $DOMAIN"
echo "OAuth2 redirect URI: $OAUTH2"
echo "OAuth1 redirect URI: $OAUTH1"
echo
printf "%s\n" "${OAUTH_HINTS[@]}"
