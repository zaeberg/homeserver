# Homelab Server

Self-hosted сервер на Docker Compose для домашнего использования. Репозиторий содержит всю конфигурацию, скрипты деплоя/бэкапа и документацию для развёртывания на miniPC.

## Сервисы

- **Vaultwarden** — менеджер паролей (совместим с Bitwarden)
- **Syncthing** — синхронизация файлов между устройствами
- **Filebrowser** — веб-интерфейс для управления файлами
- **Uptime Kuma** — мониторинг доступности сервисов
- **Caddy** — reverse proxy с автоматическим HTTPS

## Требования

- Ubuntu Server 24.04 LTS на miniPC
- Docker Engine + Docker Compose v2
- Restic (для бэкапов)

## Структура данных

- **Путь размещения на сервере**: `/srv/homelab/homelab-server`
- **Данные сервисов**: `/srv/data/<service>/`

## Быстрый старт (на сервере)

```bash
# 1. Клонировать/скопировать репозиторий
sudo mkdir -p /srv/homelab
cd /srv/homelab
# Скопировать repo в /srv/homelab/homelab-server

# 2. Создать .env из шаблона
cd /srv/homelab/homelab-server
cp compose/.env.example compose/.env
chmod 600 compose/.env
# Отредактировать compose/.env, заполнив секреты

# 3. Создать директории для данных
sudo mkdir -p /srv/data/{vaultwarden,syncthing,filebrowser,uptime-kuma,backup}

# 4. Запустить деплой
./scripts/deploy.sh
```

## Валидация (локально)

```bash
# Проверить конфигурацию без запуска контейнеров
./scripts/validate.sh
```

## Документация

Подробная документация находится в директории `docs/`:

- `01_repo_overview.md` — обзор репозитория
- `02_server_bootstrap.md` — bootstrap ОС на miniPC
- `03_deploy.md` — деплой на сервер
- `04_backup_restore.md` — бэкап и восстановление
- `05_operations.md` — операции обслуживания
- `06_troubleshooting.md` — решение проблем

## Безопасность

- Секреты никогда не коммитятся в git
- Все чувствительные данные хранятся в `compose/.env` (создаётся на сервере)
- Бэкапы шифруются через Restic
- Сервисы доступны только через reverse proxy

## Лицензия

MIT
