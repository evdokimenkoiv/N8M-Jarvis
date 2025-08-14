# N8N-Jarvis — n8n под Ubuntu (Docker + PostgreSQL + Caddy + Let’s Encrypt), готовый к продакшену

Этот репозиторий даёт **интерактивный установщик** для **n8n** с **PostgreSQL** и **Caddy** (reverse-proxy), автоматический HTTPS через **Let’s Encrypt**, опциональный **staging** CA и вспомогательные скрипты (**switch_ca.sh**, **oauth_info.sh**, **uninstall.sh**).  
Поддерживаются **EN/RU**, **OAuth** redirect URI, **Telegram** на **443**, и выполняются критичные **исправления прав** для предотвращения частых падений.

> Репозиторий: `https://github.com/evdokimenkoiv/N8N-Jarvis`

---

## Быстрый старт (Ubuntu)

```bash
# Скачать и запустить установщик
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N-Jarvis/main/install_n8n.sh -o install_n8n.sh
chmod +x install_n8n.sh && ./install_n8n.sh
```

В конце установщик напечатает:  
**«Всё готово! Теперь откройте `https://<домен>/` в браузере для дальнейшей настройки n8n.»**

---

## Что именно делает установщик

1. **Язык**: EN/RU.  
2. **Запрашивает**: домен (FQDN), e-mail для LE, часовой пояс, каталог установки, тег Postgres, тег образа n8n (**stable** рекомендуется; также `latest` или **custom**), опционально UFW.  
3. **Сертификаты**: выбор **Let’s Encrypt (prod)** или **Let’s Encrypt (staging)** (staging НЕ доверяется браузерами).  
4. **Проверки DNS и «белого» IP**: предупреждает, если DNS не указывает на публичный IP сервера, и если на интерфейсах **нет публичного (маршрутизируемого) IP** (NAT/CGNAT).  
5. **Ставит Docker и Compose v2** (если нет).  
6. **Генерирует секреты** → пишет `.env` (включая **постоянный** `N8N_ENCRYPTION_KEY`).  
7. **Фиксит права на данные** (очень часто это причина падений): `./n8n_data` — **1000:1000**, `./postgres` — **999:999**.  
8. **Создаёт** `Caddyfile` (с `email` + `acme_ca`) и `docker-compose.yml` (у Postgres есть **healthcheck**, n8n зависит от **service_healthy**).  
9. **(Опционально) Фаервол**: открывает 22/80/443 (UFW).  
10. **Стартует** стек и ждёт готовности HTTPS.  
11. Выводит **OAuth** redirect URI и финальную подсказку про открытие сайта в браузере.

---

## Файлы и структура

- `install_n8n.sh` — интерактивный установщик (EN/RU)  
- `switch_ca.sh` — переключение CA (LE prod/staging) + **перезапуск** Caddy; опционально **форс-перевыпуск** (удаляет старые сертификаты в контейнере и перезапускает)  
- `oauth_info.sh` — печатает **OAuth redirect URI**; работает **из любой папки**: пытается через Docker → `.env` в указанном каталоге → ручной ввод  
- `uninstall.sh` — останавливает и удаляет стек (данные не удаляются, если это явно не запрограммировано)  
- `docker-compose.yml`, `Caddyfile`, `.env` — создаются в каталоге установки (по умолчанию `/opt/n8n`)  
- Каталоги данных: `n8n_data/`, `postgres/`, `caddy_data/`, `caddy_config/`

---

## Порты, сеть и Telegram

- Публичный доступ — через **HTTPS 443** (и **HTTP 80** для ACME).  
- n8n слушает **5678** **внутри** Docker; **не** публикуйте этот порт наружу в продакшене.  
- **Telegram** принимает 443/80/88/8443 — здесь используется **443**.  
- `WEBHOOK_URL=https://<домен>/` формирует корректные публичные URL вебхуков.

---

## OAuth для n8n

Redirect URI для настройки у провайдера (Google, GitHub, Azure и др.):  
- **OAuth2**: `https://<домен>/rest/oauth2-credential/callback`  
- **OAuth1**: `https://<домен>/rest/oauth1-credential/callback`

Повторный вывод в любой момент:
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N-Jarvis/main/oauth_info.sh -o oauth_info.sh
chmod +x oauth_info.sh && ./oauth_info.sh
```
`oauth_info.sh` пытается автоматически определить домен из запущенного Docker-контейнера (читает `N8N_HOST`), затем из `.env` в указанном каталоге, и в крайнем случае попросит ввести вручную.

---

## Нет «белого» IP (NAT/CGNAT): ограничения и обходы

Если у сервера **нет публичного IP** напрямую, установщик предупреждает. Стек поднимется, но:

- **Авто-HTTPS** (ACME HTTP-01 / TLS-ALPN-01) может не пройти — Let’s Encrypt должен достучаться до **80/443** снаружи.  
- **Внешние вебхуки** (Telegram/Stripe/GitHub и др.) и **OAuth-callback** требуют **публичной HTTPS-точки**.  
- Доступ из Интернета в браузере невозможен без маршрутизируемого адреса или туннеля (локально — через SSH-туннель).

**Как обойти**:
1. Пробросьте **80/tcp** и **443/tcp** на этот хост; настройте DNS `A/AAAA` на публичный IP.  
2. **Cloudflare Tunnel** (cloudflared) — публикация домена без открытия портов (TLS на стороне Cloudflare).  
3. **Tailscale Funnel** — публикация n8n через Tailscale с HTTPS.  
4. **Reverse SSH-туннель** на VPS с «белым» IP, проксирование с него (Caddy/NGINX).  
5. **Для разработки**: временно использовать SSH-перенаправление портов или dev-туннель (ngrok/cloudflared).

> Проверка «белого» IP — эвристическая. В некоторых облаках интерфейс приватный, но есть 1:1 NAT на публичный IP. Если DNS уже указывает на доступный публичный IP и 80/443 проброшены на этот хост — предупреждение можно игнорировать.

---

## Выбор тега образа n8n

При установке задаётся тег образа n8n:
- **stable** — рекомендуемый для продакшена (по умолчанию).  
- **latest** — самые новые фичи, возможны нестабильности.  
- **custom** — явный тег (например, `1.81.1` или `nightly`).

Выбор сохраняется в `.env` как `N8N_IMAGE_TAG` и используется в `docker-compose.yml`.

**Сменить позже**:
1. Отредактируйте `.env` → `N8N_IMAGE_TAG=<нужный-тег>`  
2. `sudo docker compose pull && sudo docker compose up -d`

---

## Постоянный ключ шифрования (важно)

Установщик создаёт **`N8N_ENCRYPTION_KEY`**, пишет в `.env` и передаёт в контейнер.  
**Храните ключ безопасно** — потеря/замена сделает сохранённые креды нечитаемыми.

Минимум для бэкапа:
```
.env
n8n_data/
postgres/
caddy_data/
caddy_config/
```

> Повторный запуск установщика поверх боевой инсталляции может перезаписать `.env` (и ключ). **Не делайте** этого без бэкапа и ручной проверки.

---

## Быстрая диагностика

- Статусы:
  ```bash
  sudo docker compose ps
  ```

- Логи (последние 200 строк):
  ```bash
  sudo docker compose logs --tail=200 n8n
  sudo docker compose logs --tail=200 postgres
  sudo docker compose logs --tail=200 caddy
  ```

- Тест обратного прокси (изнутри Caddy):
  ```bash
  sudo docker compose exec caddy sh -lc 'apk add --no-cache curl >/dev/null 2>&1 || true; curl -sI http://n8n:5678 | head -n1'
  ```

- Частое решение проблем с правами:
  ```bash
  sudo chown -R 1000:1000 /opt/n8n/n8n_data
  sudo chown -R 999:999  /opt/n8n/postgres
  sudo docker compose restart n8n postgres
  ```

- Postgres ждём healthcheck’ом; `depends_on: service_healthy` уже настроен.

- 502 от Caddy при нормальном сертификате? Скорее всего `n8n` падает/не слушает порт или нет доступа к БД.

- Временная публикация `5678` (только для диагностики):
  ```yaml
  # во временных целях в docker-compose.yml
  ports:
    - "5678:5678"
  ```
  Затем:
  ```bash
  sudo docker compose up -d
  curl -I http://<ip_сервера>:5678
  ```

---

## Переключение сертификатного центра

`switch_ca.sh` переключает между **LE prod** и **LE staging**:
```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N-Jarvis/main/switch_ca.sh -o switch_ca.sh
chmod +x switch_ca.sh && ./switch_ca.sh
```
- Скрипт правит `acme_ca` в `Caddyfile`, **перезапускает** Caddy и при необходимости делает **форс-перевыпуск** (удаляет старые сертификаты в контейнере и перезапускает ещё раз).

> LE **staging** — только для тестов; браузеры ему не доверяют.

---

## Безопасность

- Держите `.env` в секрете (включает `N8N_ENCRYPTION_KEY`).  
- Не публикуйте **5678** наружу; используйте только HTTPS от Caddy.  
- Регулярно обновляйте образы и ОС:
  ```bash
  sudo docker compose pull && sudo docker compose up -d
  ```

---

## Удаление

```bash
curl -fsSL https://raw.githubusercontent.com/evdokimenkoiv/N8N-Jarvis/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh && ./uninstall.sh
```
Скрипт останавливает и удаляет контейнеры/сети. Каталоги данных остаются, если иное не прописано (проверьте скрипт перед использованием).
