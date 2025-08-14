#!/usr/bin/env bash
set -euo pipefail

read -rp "Select language / Выберите язык [en/ru] (en): " LANG
LANG="${LANG,,}"; [[ "$LANG" == "ru" || "$LANG" == "en" ]] || LANG="en"

P_DIR="Install directory [/opt/n8n]: "
[[ "$LANG" == "ru" ]] && P_DIR="Каталог установки [/opt/n8n]: "

read -rp "$P_DIR" DIR
DIR="${DIR:-/opt/n8n}"

if [[ ! -f "$DIR/.env" ]]; then
  if [[ "$LANG" == "ru" ]]; then
    echo "Файл $DIR/.env не найден"; exit 1
  else
    echo "File $DIR/.env not found"; exit 1
  fi
fi

DOMAIN="$(grep -E '^DOMAIN=' "$DIR/.env" | head -n1 | cut -d= -f2-)"

OAUTH2="https://${DOMAIN}/rest/oauth2-credential/callback"
OAUTH1="https://${DOMAIN}/rest/oauth1-credential/callback"

if [[ "$LANG" == "ru" ]]; then
  echo "=== OAuth для n8n ==="
  echo "Домен: $DOMAIN"
  echo "OAuth2 redirect URI: $OAUTH2"
  echo "OAuth1 redirect URI: $OAUTH1"
  echo
  echo "Подсказки:"
  echo "1) В консоли провайдера OAuth (Google, GitHub, Azure и т.д.) добавьте redirect URI."
  echo "2) В n8n: Credentials → создайте OAuth (1.0/2.0), нажмите 'Connect'."
  echo "3) Если домен/HTTPS недавно настраивались — проверьте, что URL открывается снаружи."
else
  echo "=== n8n OAuth ==="
  echo "Domain: $DOMAIN"
  echo "OAuth2 redirect URI: $OAUTH2"
  echo "OAuth1 redirect URI: $OAUTH1"
  echo
  echo "Tips:"
  echo "1) In your OAuth provider console (Google, GitHub, Azure, etc.) add the redirect URI."
  echo "2) In n8n: Credentials → create OAuth (1.0/2.0) and click 'Connect'."
  echo "3) If domain/HTTPS was just set up, make sure the URL is reachable from the Internet."
fi
