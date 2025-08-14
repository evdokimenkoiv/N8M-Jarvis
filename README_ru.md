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
3. **Выбор сервиса сертификатов**:  
   - **Let’s Encrypt (production)** — **доверяется** браузерами *(рекомендуется)*  
   - **Let’s Encrypt (staging)** — **НЕ доверяется** браузерами *(только для тестов)*  
   Выбор записывается строкой `acme_ca <url>` в `Caddyfile`.
4. **Проверка DNS** (предупреждение, если A/AAAA не совпадает с публичным IP).  
5. **Устанавливает Docker + compose v2**, если не установлены.  
6. **Готовит каталог** и генерирует секреты → пишет `.env`.  
7. **Создаёт** `Caddyfile` и `docker-compose.yml`.  
8. **(Опционально) Настраивает UFW** (22/80/443).  
9. **Запускает** стек и ждёт готовности HTTPS.

### Структура файлов
- `docker-compose.yml`, `Caddyfile`, `.env`  
- Данные: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`

### Вебхуки и сеть
- Публичная точка входа — **HTTPS 443** (HTTP 80 для ACME).  
- `WEBHOOK_URL=https://<домен>/` — корректные публичные вебхуки.  
- Telegram допускает 443/80/88/8443 — используется 443.

---

## Переключение сервиса сертификатов

Используйте вспомогательный скрипт:

```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/switch_ca.sh -o switch_ca.sh
chmod +x switch_ca.sh && ./switch_ca.sh
```
- Выберите **Let’s Encrypt (prod)** или **Let’s Encrypt (staging)**.  
- При желании **принудительно перевыпустите** сертификаты (удаляет старые внутри контейнера Caddy и перегружает конфиг).

> Важно: сертификаты staging **умышленно** не доверены браузерами.

---

## Эксплуатация

**Обновление образов**
```bash
cd /opt/n8n   # или выбранный каталог
sudo docker compose pull
sudo docker compose up -d
```

**Резервное копирование**
Сохраняйте: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`, а также `.env`.

**Восстановление**
Верните каталоги и выполните `sudo docker compose up -d`.

**Удаление**
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8M-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
