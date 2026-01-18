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
docker pull traefik:v3.6.7

# Перезапуск только этого сервиса
docker compose --env-file compose/.env -f compose/compose.yml up -d traefik

# Проверка
docker compose ps traefik
```

### Откат обновления

```bash
# Найти предыдущий образ
docker images | grep traefik

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
# Логи traefik
docker compose logs traefik

# Логи в реальном времени
docker compose logs -f traefik

# Последние 50 строк
docker compose logs --tail=50 traefik

# Логи с метками времени
docker compose logs -t traefik
```

### Логи с поиском

```bash
# Поиск ошибки в логах
docker compose logs traefik | grep -i error

# Последние ошибки
docker compose logs --tail=100 traefik | grep -i error

# Логи с контекстом (5 строк до и после)
docker compose logs traefik | grep -C 5 -i error
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
# Перезапустить traefik
docker compose --env-file compose/.env -f compose/compose.yml restart traefik

# Или по ID контейнера
docker restart homelab-traefik
```

### Остановка и запуск

```bash
# Остановить все сервисы
docker compose --env-file compose/.env -f compose/compose.yml stop

# Запустить все сервисы
docker compose --env-file compose/.env -f compose/compose.yml start

# Остановить один сервис
docker compose --env_file compose/.env -f compose/compose.yml stop traefik
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
# Быстрый бэкап traefik конфигов (tar)
sudo tar -czf /tmp/traefik-configs-$(date +%F).tar.gz /srv/homelab/homelab-server/compose/traefik/

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
docker stats homelab-traefik
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
docker inspect homelab-traefik | grep -A 10 Health
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

### Изменение конфигурации Traefik

```bash
# Редактировать статическую конфигурацию (entryPoints, providers)
nano compose/traefik/traefik.yml

# Или редактировать динамическую конфигурацию (middlewares)
nano compose/traefik/dynamic.yml

# Перезапустить Traefik
docker compose --env-file compose/.env -f compose/compose.yml restart traefik

# Проверить статус Traefik
docker compose ps traefik
docker compose logs traefik
```

## Доступ к контейнерам

### Запуск shell в контейнере

```bash
# Запустить shell в контейнере
docker exec -it homelab-traefik /bin/sh

# Выполнить команду без входа в shell
docker exec homelab-traefik version
```

### Копирование файлов

```bash
# Из контейнера на хост
docker cp homelab-traefik:/etc/traefik/traefik.yml /tmp/

# С хоста в контейнер
docker cp /tmp/traefik.yml homelab-traefik:/tmp/
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
# Изменить Basic Auth для Traefik Dashboard
nano compose/compose.yml  # Найти traefik.http.middlewares.auth.basicauth.users

# Сгенерировать новый хеш
htpasswd -nb username password | sed -e s/\\$/\\$\\$/g

# Перезапустить Traefik
docker compose restart traefik
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

### Traefik

```bash
# Проверка версии
docker exec homelab-traefik traefik version

# Просмотр dashboard
# http://SERVER_IP:8080 (Basic Auth: test:test)

# Проверка конфигурации без перезапуска
docker exec homelab-traefik cat /etc/traefik/traefik.yml

# Тестирование новых правил (добавить в dynamic.yml)
# Traefik автоматически подхватит изменения

# Резервное копирование конфигов
cp -r /srv/homelab/homelab-server/compose/traefik /tmp/traefik-backup
```
