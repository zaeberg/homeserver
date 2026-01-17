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
- Порты 80/tcp и 22/tcp открыты в firewall

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
# Базовый URL
BASE_URL=http://192.168.1.100

# Vaultwarden
VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -base64 48)
VAULTWARDEN_SIGNUPS_ALLOWED=false

# Filebrowser
FILEBROWSER_USERNAME=admin
FILEBROWSER_PASSWORD=your_secure_password

# Restic
RESTIC_REPO=/mnt/backup/restic
RESTIC_PASSWORD=your_restic_password
```

### 4. Создание директорий для данных

```bash
# Создать все необходимые директории
sudo mkdir -p /srv/data/{vaultwarden,syncthing,filebrowser,uptime-kuma,caddy,backup}

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
✓ File exists: caddy/Caddyfile
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
# Вручную проверить все endpoints
./scripts/healthcheck.sh
```

Откройте в браузере:
- http://SERVER_IP/ — landing page со ссылками
- http://SERVER_IP/vault — Vaultwarden
- http://SERVER_IP/sync — Syncthing
- http://SERVER_IP/files — Filebrowser
- http://SERVER_IP/status — Uptime Kuma

## Что делать после деплоя

### 1. Настроить Vaultwarden

1. Откройте http://SERVER_IP/vault
2. Создайте учётную запись администратора
3. Отключите регистрации в `.env`:
   ```bash
   VAULTWARDEN_SIGNUPS_ALLOWED=false
   ```
4. Перезапустите vaultwarden:
   ```bash
   cd /srv/homelab/homelab-server
   docker compose --env-file compose/.env -f compose/compose.yml restart vaultwarden
   ```

### 2. Настроить Syncthing

1. Откройте http://SERVER_IP/sync
2. Примите условия использования
3. Настройте устройства для синхронизации
4. (Опционально) Ограничьте доступ по паролю в настройках

### 3. Настроить Filebrowser

Учётные данные уже настроены из `.env`:
- Username: `FILEBROWSER_USERNAME` (по умолчанию `admin`)
- Password: `FILEBROWSER_PASSWORD`

Измените пароль в веб-интерфейсе при первом входе.

### 4. Настроить Uptime Kuma

1. Откройте http://SERVER_IP/status
2. Создайте учётную запись администратора
3. Добавьте мониторы для ваших сервисов

### 5. Настроить бэкап

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
./scripts/healthcheck.sh
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
1. Проверьте логи: `docker compose logs <service>`
2. Проверьте статус: `docker compose ps`
3. Запустите healthcheck: `./scripts/healthcheck.sh`
4. См. `06_troubleshooting.md` для детальной диагностики
