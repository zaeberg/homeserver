# Repo Overview

## Что внутри репозитория

```
homeserver/
├── compose/
│   ├── compose.yml          # Docker Compose стек с сервисами
│   ├── .env.example         # Шаблон переменных окружения
│   ├── traefik/
│   │   ├── traefik.yml      # Статическая конфигурация Traefik
│   │   └── dynamic.yml      # Динамическая конфигурация (middlewares)
│   └── .env                 # Реальный файл с секретами (не коммитится!)
├── scripts/
│   ├── validate.sh          # Валидация конфигурации
│   ├── deploy.sh            # Деплой сервисов
│   ├── healthcheck.sh       # Проверка работоспособности
│   ├── backup.sh            # Бэкап через Restic
│   └── restore_test.sh      # Тест восстановления бэкапа
├── systemd/
│   ├── homelab-backup.service   # Unit для бэкапа
│   ├── homelab-backup.timer     # Timer для ежедневного бэкапа
│   └── homelab-restore-test.service  # Unit для теста восстановления
├── infra/
│   └── docker/
│       └── daemon.json      # Конфигурация Docker daemon
└── docs/
    ├── 01_repo_overview.md
    ├── 03_deploy.md
    ├── 04_backup_restore.md
    ├── 05_operations.md
    └── 06_troubleshooting.md
```

## Сервисы

### Traefik (Reverse Proxy)
- **Версия**: v3.6.7
- **Порты**:
  - 80 (HTTP)
  - 443 (HTTPS)
  - 8080 (Dashboard, только в локальной сети!)
- **Данные**: `/srv/data/traefik/letsencrypt` (SSL сертификаты)
- **Назначение**: reverse proxy с Docker auto-discovery
- **Конфигурация**:
  - `compose/traefik/traefik.yml` — статическая конфигурация (entryPoints, providers)
  - `compose/traefik/dynamic.yml` — динамическая конфигурация (middlewares, security headers)
- **Dashboard**: доступен на `traefik.home.local` с Basic Auth (test:test)
- **Особенности**:
  - Автоматическое обнаружение сервисов через Docker labels
  - Встроенная поддержка Let's Encrypt для HTTPS
  - Security headers middleware
  - Healthcheck для мониторинга работоспособности

## Хранение данных

### На сервере
```
/srv/homelab/homelab-server/    # Репозиторий (конфиги, скрипты)
/srv/data/                      # Данные сервисов
├── traefik/
│   └── letsencrypt/            # SSL сертификаты (для будущего использования)
└── backup/                     # Логи бэкапов
```

### На внешнем диске
```
/mnt/backup/restic/             # Restic репозиторий (бэкапы)
```

## Что является секретом

**НИКОГДА не коммитить в git:**
- `compose/.env` — содержит все секреты
- Любые `.env` файлы
- API ключи, токены, пароли
- SSH ключи
- Сертификаты SSL/TLS
- Database файлы

**Защищено в .gitignore:**
- `.env` файлы
- `**/data/`
- `**/*.db`, `**/*.sqlite*`
- `**/backups/`
- `**/*.log`

## Как создать .env на сервере

```bash
cd /srv/homelab/homelab-server
cp compose/.env.example compose/.env
chmod 600 compose/.env
nano compose/.env  # Отредактируйте секреты
```

**Обязательные переменные:**
- `RESTIC_PASSWORD` — пароль для шифрования бэкапов

**Необязательные (с дефолтными значениями):**
- `BASE_URL` — http://home.local (базовый URL для сервисов)
- `RESTIC_REPO_LOCAL` — путь к локальному бэкапу (/mnt/backup/restic)
- `RESTIC_REPO_CLOUD` — путь к облачному бэкапу (rclone:yandex:homelab-backups)
- `BACKUP_TARGETS` — что бэкапить (/srv/homelab/homelab-server)
