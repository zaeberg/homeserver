# Deploy Homepage на сервере

Эта инструкция описывает шаги для развёртывания Homepage на homelab сервере.

## Предварительные требования

- Сервер должен быть настроен согласно `docs/02_server_bootstrap.md`
- Traefik и traefik-avahi-helper должны быть запущены
- Avahi-daemon должен быть установлен на хост-системе

## Шаги деплоя

### 1. Подключиться к серверу

```bash
ssh user@your-server-ip
cd /srv/homelab/homelab-server
```

### 2. Обновить репозиторий

```bash
git pull
```

### 3. Создать директорию для конфигов Homepage

```bash
sudo mkdir -p /srv/data/homepage/config
```

### 4. Скопировать примеры конфигов

```bash
sudo cp infra/homepage/config-examples/*.yaml /srv/data/homepage/config/
```

### 5. Проверить конфигурацию (опционально)

```bash
# Проверить что compose конфиг валиден
docker compose -f compose/compose.yml config

# Или использовать скрипт валидации
./scripts/validate.sh
```

### 6. Запустить Homepage

```bash
# Запустить только контейнер Homepage
docker compose -f compose/compose.yml up -d homepage

# Или перезапустить весь стек
./scripts/deploy.sh
```

### 7. Проверить что контейнер запустился

```bash
# Проверить статус контейнера
docker ps | grep homepage

# Проверить логи на ошибки
docker logs homelab-homepage
```

### 8. Проверить работоспособность

#### С сервера (curl)

```bash
# Проверить HTTP ответ
curl -I http://home.local

# Ожидаемый результат: HTTP/1.1 200 OK
```

#### С клиента (браузер)

1. Открыть браузер на устройстве в локальной сети
2. Перейти на http://home.local
3. Проверить что:
   - Загружается главная страница Homepage
   - Отображается закладка на Traefik в группе "Infrastructure"
   - Можно перейти на Traefik Dashboard

#### Проверить в Traefik Dashboard (опционально)

1. Открыть http://traefik.home.local/dashboard/
2. Перейти в HTTP Routers
3. Найти router `homepage@docker`
4. Проверить что он показывает статус зеленый (Active)

## Troubleshooting

### Сервис недоступен по home.local

**Проблема:** `curl: (6) Could not resolve host: home.local`

**Решение:**

1. Проверить что `avahi.homeserver.service` label добавлен:
   ```bash
   docker inspect homelab-homepage | grep avahi
   ```

2. Проверить что `traefik-avahi` контейнер запущен:
   ```bash
   docker ps | grep avahi
   ```

3. Проверить логи `traefik-avahi`:
   ```bash
   docker logs homelab-traefik-avahi-helper
   ```

4. Проверить что avahi-daemon установлен на хосте:
   ```bash
   systemctl status avahi-daemon
   ```

### 502 Bad Gateway от Traefik

**Проблема:** Traefik показывает ошибку 502

**Решение:**

1. Проверить что контейнер homepage запущен:
   ```bash
   docker ps | grep homepage
   ```

2. Проверить логи контейнера:
   ```bash
   docker logs homelab-homepage
   ```

3. Проверить что контейнер в сети `internal`:
   ```bash
   docker inspect homelab-homepage | grep -A 10 Networks
   ```

### Конфигурационные файлы не применяются

**Проблема:** Изменения в конфигах не отображаются

**Решение:**

1. Проверить что файлы скопированы правильно:
   ```bash
   ls -la /srv/data/homepage/config/
   ```

2. Перезапустить контейнер:
   ```bash
   docker compose -f compose/compose.yml restart homepage
   ```

3. Проверить логи на ошибки парсинга YAML:
   ```bash
   docker logs homelab-homepage
   ```

## Следующие шаги

После успешного деплоя можно:

1. Добавить больше закладок в `/srv/data/homepage/config/bookmarks.yaml`
2. Настроить виджеты в `/srv/data/homepage/config/widgets.yaml`
3. Добавить мониторинг сервисов в `/srv/data/homepage/config/services.yaml`
4. Кастомизировать тему в `/srv/data/homepage/config/settings.yaml`

Документация: https://gethomepage.dev/
