# Deploy Guide

## Требования к серверу

- Ubuntu Server 24.04 LTS
- Docker Engine + Docker Compose v2
- Пользователь с доступом к Docker
- Минимум 2GB RAM, 20GB диска

## Пошаговый деплой

### 1. Подготовка сервера

Если вы ещё не выполнили bootstrap ОС, см. `02_server_bootstrap.md`.

Проверьте, что:
- Docker установлен и пользователь в группе `docker`
- Директории созданы: `/srv/homelab` и `/srv/data`
- Порты 80/tcp, 443/tcp, 8080/tcp и 22/tcp открыты в firewall

### 2. Размещение репозитория

```bash
# Клонировать или скопировать репозиторий
sudo mkdir -p /srv/homelab
cd /srv/homelab

# Если используете git:
git clone <repo-url> homelab-server

# Или скопировать файлы (scp/rsync)
# sudo cp -r /path/to/repo /srv/homelab/homelab-server

cd /srv/homelab/homelab-server
```

### 3. Создание .env файла

```bash
# Создать .env из шаблона
cp compose/.env.example compose/.env

# Ограничить права доступа (только для владельца)
chmod 600 compose/.env

# Отредактировать .env
nano compose/.env
```

**Минимальная конфигурация:**
```bash
# Базовый URL (для Traefik dashboard)
BASE_URL=http://home.local

# Restic (если используете бэкапы)
RESTIC_REPO=/mnt/backup/restic
RESTIC_PASSWORD=your_restic_password
```

### 4. Создание директорий для данных

```bash
# Создать все необходимые директории
sudo mkdir -p /srv/data/{traefik,backup}

# Назначить права доступа
sudo chown -R $USER:$USER /srv/data
chmod -R 755 /srv/data
```

### 5. Валидация конфигурации (опционально)

```bash
# Проверить конфигурацию перед запуском
./scripts/validate.sh
```

Ожидаемый вывод:
```
✓ File exists: compose/compose.yml
✓ File exists: compose/.env.example
✓ Files exist: traefik/traefik.yml, traefik/dynamic.yml
✓ Docker Compose configuration is valid
✓ No 'latest' image tags found
✓ No .env files found in repository
✓ All validation checks passed!
```

### 6. Деплой сервисов

```bash
# Запустить деплой
./scripts/deploy.sh
```

Скрипт выполнит:
1. Проверку наличия `.env`
2. Остановку существующих контейнеров (если есть)
3. Pull новых Docker образов
4. Запуск всех сервисов
5. Вывод статуса контейнеров
6. Healthcheck сервисов

### 7. Проверка работоспособности

```bash
# Проверить статус контейнеров
docker compose ps

# Проверить логи Traefik
docker compose logs traefik
```

Откройте в браузере:
- http://SERVER_IP:8080 — Traefik Dashboard (Basic Auth: test/test)
- http://SERVER_IP — Traefik default frontend (если настроен)

**Примечание**: Для доступа к dashboard по доменному имени (`traefik.home.local`) настройте DNS или добавьте запись в `/etc/hosts`:
```
SERVER_IP traefik.home.local
```

## Что делать после деплоя

### 1. Изменить Basic Auth для Traefik Dashboard

Текущие учётные данные: `test:test` — **измените их!**

Отредактируйте `compose/compose.yml`, найдите секцию с `traefik.http.middlewares.auth.basicauth.users` и замените на сгенерированный хеш:

```bash
# Сгенерировать хеш пароля
htpasswd -nb username password | sed -e s/\\$/\\$\\$/g

# Пример вывода: username:$apr1$hash...
```

Замените `test:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wjC` на вашу строку.

Перезапустите Traefik:
```bash
cd /srv/homelab/homelab-server
docker compose --env-file compose/.env -f compose/compose.yml restart traefik
```

### 2. Настроить HTTPS (опционально)

Traefik поддерживает автоматическое получение SSL сертификатов через Let's Encrypt.

Раскомментируйте и настройте секцию `certificatesResolvers` в `compose/traefik/traefik.yml`:
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

Добавьте `certResolver: letsencrypt` к router labels в `compose/compose.yml`.

### 3. Добавить сервисы

Теперь вы можете добавлять сервисы, просто добавляя их в `compose/compose.yml` с правильными Docker labels. Traefik автоматически их обнаружит.

Пример добавления сервиса:
```yaml
services:
  myapp:
    image: myapp:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.local`)"
      - "traefik.http.routers.myapp.entrypoints=web"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
```

### 4. Настроить бэкап

См. `04_backup_restore.md`.

## Обновление сервисов

```bash
cd /srv/homelab/homelab-server

# Опционально: бэкап перед обновлением
./scripts/backup.sh

# Pull новых образов
docker compose --env-file compose/.env -f compose/compose.yml pull

# Перезапуск сервисов
./scripts/deploy.sh

# Проверка работоспособности
docker compose ps
```

## Удаление сервисов

```bash
cd /srv/homelab/homelab-server

# Остановить и удалить контейнеры
docker compose --env-file compose/.env -f compose/compose.yml down

# Удалить volumes (ОСТОРОЖНО! Данные будут удалены!)
docker compose --env-file compose/.env -f compose/compose.yml down -v

# Удалить образы (опционально)
docker image prune -a
```

## Troubleshooting

Если что-то не работает:
1. Проверьте логи: `docker compose logs traefik`
2. Проверьте статус: `docker compose ps`
3. Проверьте healthcheck: `docker inspect homelab-traefik | grep -A 10 Health`
4. См. `06_troubleshooting.md` для детальной диагностики
