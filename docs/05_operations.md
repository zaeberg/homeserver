# Operations Guide

## Обновление контейнеров

### Безопасное обновление

```bash
cd /srv/homelab/homelab-server

# 1. Бэкап перед обновлением
./scripts/backup.sh

# 2. Pull новых образов
docker compose --env-file compose/.env -f compose/compose.yml pull

# 3. Перезапуск сервисов
./scripts/deploy.sh

# 4. Проверка работоспособности
./scripts/healthcheck.sh
```

### Обновление только одного сервиса

```bash
# Pull конкретного образа
docker pull vaultwarden/server:1.30.1

# Перезапуск только этого сервиса
docker compose --env-file compose/.env -f compose/compose.yml up -d vaultwarden

# Проверка
docker compose ps vaultwarden
```

### Откат обновления

```bash
# Найти предыдущий образ
docker images | grep vaultwarden

# Запустить с предыдущей версией (отредактируйте тег в compose.yml)
nano compose/compose.yml

# Перезапустить
./scripts/deploy.sh
```

## Просмотр логов

### Все контейнеры

```bash
# Статус контейнеров
docker compose ps

# Логи всех контейнеров (последние 100 строк)
docker compose logs --tail=100

# Логи в реальном времени
docker compose logs -f
```

### Отдельный сервис

```bash
# Логи vaultwarden
docker compose logs vaultwarden

# Логи в реальном времени
docker compose logs -f vaultwarden

# Последние 50 строк
docker compose logs --tail=50 vaultwarden

# Логи с метками времени
docker compose logs -t vaultwarden
```

### Логи с поиском

```bash
# Поиск ошибки в логах
docker compose logs vaultwarden | grep -i error

# Последние ошибки
docker compose logs --tail=100 vaultwarden | grep -i error

# Логи с контекстом (5 строк до и после)
docker compose logs vaultwarden | grep -C 5 -i error
```

### Systemd логи

```bash
# Логи бэкапа
journalctl -u homelab-backup.service -f

# Логи timer
journalctl -u homelab-backup.timer

# Последние 50 строк
journalctl -u homelab-backup.service -n 50
```

## Перезапуск сервисов

### Перезапуск всех сервисов

```bash
cd /srv/homelab/homelab-server

# Полный перезапуск
docker compose --env-file compose/.env -f compose/compose.yml restart

# Или через deploy.sh
./scripts/deploy.sh
```

### Перезапуск одного сервиса

```bash
# Перезапустить vaultwarden
docker compose --env-file compose/.env -f compose/compose.yml restart vaultwarden

# Или по ID контейнера
docker restart homelab-vaultwarden
```

### Остановка и запуск

```bash
# Остановить все сервисы
docker compose --env-file compose/.env -f compose/compose.yml stop

# Запустить все сервисы
docker compose --env-file compose/.env -f compose/compose.yml start

# Остановить один сервис
docker compose --env_file compose/.env -f compose/compose.yml stop vaultwarden
```

## Управление данными

### Просмотр volumes

```bash
# Список volumes
docker volume ls

# Информация о volume
docker volume inspect homelab_data

# Используемое место
du -sh /srv/data/*
```

### Резервное копирование вручную

```bash
# Быстрый бэкап vaultwarden (tar)
sudo tar -czf /tmp/vaultwarden-$(date +%F).tar.gz /srv/data/vaultwarden

# Бэкап через restic
./scripts/backup.sh
```

### Очистка места

```bash
# Очистить Docker образы (неиспользуемые)
docker image prune -a

# Очистить volumes (ОСТОРОЖНО! Удаляет данные!)
docker volume prune

# Очистить систему Docker (кэш, сети, времённые файлы)
docker system prune -a

# Очистить логи Docker
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log
```

## Мониторинг ресурсов

### Использование ресурсов контейнерами

```bash
# Статистика в реальном времени
docker stats

# Статистика без потока
docker stats --no-stream

# Статистика конкретного контейнера
docker stats homelab-vaultwarden
```

### Использование диска

```bash
# Размер директорий данных
du -sh /srv/data/*

# Размер Docker volumes
docker system df

# Свободное место на диске
df -h
```

### Использование RAM

```bash
# Общая память
free -h

# Память процессов
ps aux --sort=-%mem | head
```

## Healthcheck

### Ручная проверка

```bash
# Запустить healthcheck скрипт
./scripts/healthcheck.sh

# Проверить отдельный endpoint
curl -I http://localhost/vault
curl -I http://localhost/sync
curl -I http://localhost/files
curl -I http://localhost/status
```

### Healthcheck контейнеров

```bash
# Проверить статус healthcheck всех контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}"

# Подробная информация
docker inspect homelab-vaultwarden | grep -A 10 Health
```

## Управление конфигурацией

### Изменение переменных окружения

```bash
# Редактировать .env
nano compose/.env

# Перезапустить сервисы для применения изменений
docker compose --env-file compose/.env -f compose/compose.yml up -d

# Или перезапустить все сервисы
./scripts/deploy.sh
```

### Изменение compose.yml

```bash
# Редактировать compose.yml
nano compose/compose.yml

# Валидация конфигурации
docker compose -f compose/compose.yml config

# Применить изменения
./scripts/deploy.sh
```

### Изменение Caddyfile

```bash
# Редактировать Caddyfile
nano caddy/Caddyfile

# Перезапустить caddy
docker compose --env-file compose/.env -f compose/compose.yml restart caddy

# Проверить конфигурацию Caddy
docker exec homelab-caddy caddy validate --config /etc/caddy/Caddyfile
```

## Доступ к контейнерам

### Запуск shell в контейнере

```bash
# Запустить bash в контейнере
docker exec -it homelab-vaultwarden /bin/bash

# Или sh (если bash недоступен)
docker exec -it homelab-vaultwarden /bin/sh

# Выполнить команду без входа в shell
docker exec homelab-vaultwarden ls /data
```

### Копирование файлов

```bash
# Из контейнера на хост
docker cp homelab-vaultwarden:/data/vaultwarden.db /tmp/

# С хоста в контейнер
docker cp /tmp/config.json homelab-vaultwarden:/data/
```

## Обновление репозитория

### Если используете git

```bash
cd /srv/homelab/homelab-server

# Проверить изменения
git status

# Сохранить локальные изменения (если есть)
git stash

# Pull обновлений
git pull origin main

# Восстановить локальные изменения
git stash pop

# Перезапустить сервисы (если compose.yml изменился)
./scripts/deploy.sh
```

### Если копируете файлы

```bash
# На локальной машине
scp -r /path/to/local/repo/* user@server:/srv/homelab/homelab-server/

# Или через rsync
rsync -avz --delete /path/to/local/repo/ user@server:/srv/homelab/homelab-server/
```

## Плановое обслуживание

### Еженедельное обслуживание

```bash
#!/bin/bash
# weekly_maintenance.sh

cd /srv/homelab/homelab-server

echo "=== Weekly Maintenance ==="

# 1. Бэкап
echo "Running backup..."
./scripts/backup.sh

# 2. Обновление образов
echo "Pulling new images..."
docker compose --env-file compose/.env -f compose/compose.yml pull

# 3. Перезапуск
echo "Restarting services..."
./scripts/deploy.sh

# 4. Проверка
echo "Running healthcheck..."
./scripts/healthcheck.sh

# 5. Очистка старых образов
echo "Cleaning up old images..."
docker image prune -f

echo "Maintenance complete!"
```

### Ежемесячное обслуживание

```bash
#!/bin/bash
# monthly_maintenance.sh

cd /srv/homelab/homelab-server

echo "=== Monthly Maintenance ==="

# 1. Полный бэкап
./scripts/backup.sh

# 2. Restore-test
./scripts/restore_test.sh

# 3. Обновление системы
sudo apt update && sudo apt upgrade -y

# 4. Проверка диска
df -h
du -sh /srv/data/*

# 5. Очистка Docker
docker system prune -a --volumes -f

echo "Monthly maintenance complete!"
```

## Безопасность

### Регулярное обновление паролей

```bash
# Изменить пароль filebrowser
nano compose/.env  # FILEBROWSER_PASSWORD

# Изменить admin token vaultwarden
nano compose/.env  # VAULTWARDEN_ADMIN_TOKEN

# Перезапустить сервисы
./scripts/deploy.sh
```

### Проверка безопасности

```bash
# Сканирование на секреты в репозитории
./scripts/validate.sh

# Проверка прав доступа к .env
ls -la compose/.env  # Должно быть -rw------- (600)

# Проверка открытых портов
sudo ss -tulpn | grep LISTEN
```

## Работа с сервисами индивидуально

### Vaultwarden

```bash
# Сброс пароля администратора
docker exec -it homelab-vaultwarden /vaultwarden hash --preset

# Создание нового пользователя
# См. документацию Vaultwarden: https://github.com/dani-garcia/vaultwarden/wiki
```

### Syncthing

```bash
# Доступ к GUI Syncthing
# http://SERVER_IP:8384 (если открыт порт) или через /sync

# Редактирование конфига
nano /srv/data/syncthing/config/config.xml
```

### Filebrowser

```bash
# Изменение прав доступа
nano /srv/data/filebrowser/filebrowser.db

# Или через веб-интерфейс
```

### Uptime Kuma

```bash
# Доступ к настройкам мониторов
# http://SERVER_IP/status

# Резервное копирование конфига
cp /srv/data/uptime-kuma/kuma.db /tmp/kuma.db.backup
```
