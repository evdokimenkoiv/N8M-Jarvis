#!/usr/bin/env bash
set -euo pipefail

bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
info()   { printf "[-] %s\n" "$*"; }
ok()     { printf "[✓] %s\n" "$*"; }
warn()   { printf "[!] %s\n" "$*"; }
err()    { printf "[✗] %s\n" "$*"; }

trap 'err "${T_ERR:-Uninstall failed. See logs above.}"; exit 1' ERR

# --- language (default EN) ---
read -rp "Select language / Выберите язык [en/ru] (en): " LANG_CHOICE
LANG_CHOICE="${LANG_CHOICE,,}"
if [[ "$LANG_CHOICE" != "en" && "$LANG_CHOICE" != "ru" ]]; then LANG_CHOICE="en"; fi

if [[ "$LANG_CHOICE" == "ru" ]]; then
  T_TITLE="=== Деинсталляция n8n (Docker stack) ==="
  P_DIR="Каталог установки [/opt/n8n]: "
  P_RMVOLS="Удалить Docker-тома (персистентные данные: БД/конфиги Caddy)? [y/N]: "
  P_RMDIR="Удалить файлы установки (каталог со всеми файлами)? [y/N]: "
  P_RMDOCKER="Удалить Docker Engine и компоненты? [y/N]: "
  E_NOCMP="Файл docker-compose.yml не найден в каталоге: %s"
  M_STOP="Остановка и удаление контейнеров..."
  M_RMVOLS="Удаление томов Docker (включая caddy_data/caddy_config)..."
  M_RMDATA="Удаление каталога установки..."
  M_RMDOCKER="Удаление Docker Engine и компонентов..."
  M_DONE="Готово."
  T_ERR="Ошибка удаления. Смотрите лог выше."
else
  T_TITLE="=== n8n Uninstaller (Docker stack) ==="
  P_DIR="Install directory [/opt/n8n]: "
  P_RMVOLS="Remove Docker volumes (persistent data: DB/Caddy configs)? [y/N]: "
  P_RMDIR="Remove install files (entire directory)? [y/N]: "
  P_RMDOCKER="Remove Docker Engine and components? [y/N]: "
  E_NOCMP="docker-compose.yml not found in directory: %s"
  M_STOP="Stopping and removing containers..."
  M_RMVOLS="Removing Docker volumes (including caddy_data/caddy_config)..."
  M_RMDATA="Removing install directory..."
  M_RMDOCKER="Removing Docker Engine and components..."
  M_DONE="Done."
  T_ERR="Uninstall failed. See logs above."
fi

bold "$T_TITLE"

read -rp "$P_DIR" INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/opt/n8n}"

if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
  printf "$E_NOCMP\n" "$INSTALL_DIR"
  exit 1
fi

read -rp "$P_RMVOLS" RM_VOLUMES
RM_VOLUMES="${RM_VOLUMES:-N}"
read -rp "$P_RMDIR" RM_DIR
RM_DIR="${RM_DIR:-N}"
read -rp "$P_RMDOCKER" RM_DOCKER
RM_DOCKER="${RM_DOCKER:-N}"

cd "$INSTALL_DIR"

info "$M_STOP"
if [[ "${RM_VOLUMES^^}" == "Y" ]]; then
  sudo docker compose down -v || true
else
  sudo docker compose down || true
fi
ok "Stack removed"

if [[ "${RM_DIR^^}" == "Y" ]]; then
  info "$M_RMDATA"
  sudo rm -rf "$INSTALL_DIR"
  ok "Install directory removed"
fi

if [[ "${RM_DOCKER^^}" == "Y" ]]; then
  info "$M_RMDOCKER"
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
  sudo apt-get autoremove -y || true
  sudo rm -f /etc/apt/sources.list.d/docker.list || true
  sudo rm -f /etc/apt/keyrings/docker.gpg || true
  ok "Docker removed (if it was installed via apt)"
fi

ok "$M_DONE"
