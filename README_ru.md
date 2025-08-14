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
Установщик выведет строку: **«Всё готово! Теперь откройте https://<домен>/ в браузере для дальнейшей настройки n8n.»**

---

## Что делает установщик

1. **Выбор языка (EN/RU)**  
2. **Запрашивает** домен, e-mail для LE, часовой пояс, каталог установки, тег Postgres, опцию UFW.  
3. **Выбор тега образа n8n**: **stable** *(рекомендуется)*, **latest** или **custom** (например, `1.81.1`, `nightly`).  
4. **Выбор сервиса сертификатов**: Let’s Encrypt **production** (доверяется) или **staging** (НЕ доверяется).  
5. **Проверка DNS** (предупреждение, если A/AAAA не совпадает с публичным IP).  
6. **Устанавливает Docker + compose v2**, если не установлены.  
7. **Готовит каталог** и генерирует секреты → пишет `.env`.  
8. **Создаёт каталоги данных и исправляет права** (`./n8n_data` → UID/GID **1000:1000**, `./postgres` → **999:999**).  
9. **Создаёт** `Caddyfile` и `docker-compose.yml` (с **healthcheck** Postgres и `depends_on: service_healthy`).  
10. **(Опционально) Настраивает UFW** (22/80/443).  
11. **Запускает** стек и ждёт готовности HTTPS.  
12. Печатает **OAuth** redirect URI (OAuth2 и OAuth1) и финальную подсказку про открытие ссылки в браузере.

---

## OAuth (Google/GitHub/Azure и др.)

Используйте следующие redirect URI в настройках вашего провайдера:

- **OAuth2**: `https://<домен>/rest/oauth2-credential/callback`  
- **OAuth1**: `https://<домен>/rest/oauth1-credential/callback`

> Установщик выводит эти URL в конце, а позже вы можете запустить `./oauth_info.sh`, чтобы снова их посмотреть.

В n8n откройте **Credentials**, создайте соответствующие OAuth-учётные данные и нажмите **Connect**.
