# Homelab Server

Self-hosted сервер на Docker Compose для домашнего использования. Содержит конфигурацию, скрипты деплоя/бэкапа и документацию.

## Сервисы

- **Traefik** — reverse proxy с Docker auto-discovery и автоматическим HTTPS (v3.6.7)
- **Homepage** — главная страница с навигацией по сервисам
- **traefik-avahi-helper** — mDNS/Bonjour для локальной сети (*.home.local)

## Требования

- Ubuntu Server 24.04 LTS на miniPC
- Docker Engine + Docker Compose v2
- Restic (для бэкапов)

## Структура данных

- **Путь на сервере**: `/srv/homelab/homelab-server`
- **Данные сервисов**: `/srv/data/<service>/`

## Быстрый старт (на сервере)

```bash
# 1. Разместить репозиторий
sudo mkdir -p /srv/homelab
cd /srv/homelab
# Скопировать repo в /srv/homelab/homelab-server

# 2. Создать .env из шаблона
cd /srv/homelab/homelab-server
cp compose/.env.example compose/.env
chmod 600 compose/.env
# Отредактировать compose/.env

# 3. Создать директории для данных
sudo mkdir -p /srv/data/{traefik,backup}

# 4. Деплой
./scripts/deploy.sh
```

## Валидация (локально)

```bash
# Проверить конфигурацию без запуска контейнеров
./scripts/validate.sh
```

## Разработка

См. [`DEVELOPMENT.md`](DEVELOPMENT.md) — workflow, code style, testing.

## Документация

Подробная документация в `docs/`:

- `00_architecture.md` — архитектура системы
- `01_repo_overview.md` — обзор репозитория
- `02_server_bootstrap.md` — bootstrap ОС на miniPC
- `03_deploy.md` — деплой на сервер
- `04_backup_restore.md` — бэкап и восстановление
- `05_operations.md` — операции обслуживания
- `06_troubleshooting.md` — решение проблем
- `07_adding_services.md` — добавление сервисов
- `08_security.md` — security guidelines

## Безопасность

- Секреты не коммитятся в git
- Чувствительные данные в `compose/.env` (создаётся на сервере)
- Бэкапы шифруются через Restic
- Сервисы доступны только через reverse proxy

## Лицензия

MIT
