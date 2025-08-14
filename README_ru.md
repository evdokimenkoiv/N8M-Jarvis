# N8M-Jarvis — n8n + PostgreSQL + Caddy (Let’s Encrypt)

Интерактивный установщик разворачивает **n8n**, **PostgreSQL** и **Caddy** с автоматическими сертификатами Let’s Encrypt.  
Первый запрос — выбор **языка (EN/RU)**, по умолчанию — английский. Вебхуки Telegram работают на **443 порту**.

> Репозиторий: https://github.com/evdokimenkoiv/N8M-Jarvis

## Быстрый старт (Ubuntu)
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh
```

После установки откройте `https://<домен>/` и создайте первого администратора n8n.

---

## Что делает установщик

1. **Выбор языка (EN/RU)**  
2. **Запрашивает** домен, e-mail для LE, часовой пояс, каталог установки, тег Postgres, опцию UFW.  
3. **Выбор тега образа n8n**: **stable** *(рекомендуется)*, **latest** или **custom** (например, `1.81.1`, `nightly`). Выбор сохраняется в `.env` как `N8N_IMAGE_TAG` и используется в Compose.  
4. **Выбор сервиса сертификатов**: Let’s Encrypt **production** (доверяется) или **staging** (НЕ доверяется).  
5. **Проверка DNS** (предупреждение, если A/AAAA не совпадает с публичным IP).  
6. **Устанавливает Docker + compose v2**, если не установлены.  
7. **Готовит каталог** и генерирует секреты → пишет `.env`.  
8. **Создаёт каталоги данных и исправляет права** (`./n8n_data` → UID/GID **1000:1000**, `./postgres` → **999:999**). Это устраняет частый краш из‑за невозможности записи в bind-монты.  
9. **Создаёт** `Caddyfile` и `docker-compose.yml` (с **healthcheck** Postgres и `depends_on: service_healthy`).  
10. **(Опционально) Настраивает UFW** (22/80/443).  
11. **Запускает** стек и ждёт готовности HTTPS.

### Структура файлов
- `docker-compose.yml`, `Caddyfile`, `.env`  
- Данные: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`

### Вебхуки и сеть
- Публичный доступ — **HTTPS 443** (HTTP 80 для ACME).  
- `WEBHOOK_URL=https://<домен>/` — корректные публичные URL вебхуков.  
- Telegram допускает 443/80/88/8443 — используем 443.

---

## Переключение сервиса сертификатов

Воспользуйтесь скриптом:

```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/switch_ca.sh -o switch_ca.sh
chmod +x switch_ca.sh && ./switch_ca.sh
```
- Выберите **prod** или **staging**.  
- Скрипт **перезапускает** контейнер Caddy для применения изменений.  
- Опционально — **форсированное перевыпуск**: удаляет старые сертификаты внутри Caddy и снова перезапускает контейнер для триггера нового выпуска.

---

## Эксплуатация

**Обновление образов**
```bash
cd /opt/n8n   # или выбранный каталог
sudo docker compose pull
sudo docker compose up -d
```

**Резервное копирование**
Сохраните: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/` и `.env`.

**Восстановление**
Верните каталоги и выполните `sudo docker compose up -d`.

**Удаление**
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
