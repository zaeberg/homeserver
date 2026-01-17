# Repo Overview

## Что внутри репозитория

```
homeserver/
├── compose/
│   ├── compose.yml          # Docker Compose стек с сервисами
│   ├── .env.example         # Шаблон переменных окружения
│   └── .env                 # Реальный файл с секретами (не коммитится!)
├── caddy/
│   └── Caddyfile            # Конфигурация reverse proxy
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

### 1. Vaultwarden (Password Manager)
- **Порт**: доступен через Caddy на `/vault`
- **Данные**: `/srv/data/vaultwarden`
- **Назначение**: менеджер паролей, совместим с Bitwarden
- **Важно**: настройте надёжный `VAULTWARDEN_ADMIN_TOKEN` в `.env`

### 2. Syncthing (File Synchronization)
- **Порт**: доступен через Caddy на `/sync`
- **Данные**: `/srv/data/syncthing`
- **Назначение**: синхронизация файлов между устройствами
- **Важно**: первое подключение требует подтверждения на веб-интерфейсе

### 3. Filebrowser (File Management)
- **Порт**: доступен через Caddy на `/files`
- **Данные**: `/srv/data/filebrowser` (конфиг), `/srv/data` (файлы)
- **Назначение**: веб-интерфейс для управления файлами
- **Учётные данные**: настраиваются в `.env` (FILEBROWSER_USERNAME/PASSWORD)

### 4. Uptime Kuma (Monitoring)
- **Порт**: доступен через Caddy на `/status`
- **Данные**: `/srv/data/uptime-kuma`
- **Назначение**: мониторинг доступности сервисов
- **Важно**: создаётся администратор при первом запуске

### 5. Caddy (Reverse Proxy)
- **Порт**: 80 (единственный порт, открытый наружу)
- **Данные**: `/srv/data/caddy`
- **Назначение**: reverse proxy, path-based routing ко всем сервисам
- **Landing page**: доступен на `/`

## Хранение данных

### На сервере
```
/srv/homelab/homelab-server/    # Репозиторий (конфиги, скрипты)
/srv/data/                      # Данные сервисов
├── vaultwarden/
├── syncthing/
├── filebrowser/
├── uptime-kuma/
├── caddy/
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
- `VAULTWARDEN_ADMIN_TOKEN` — сгенерируйте через `openssl rand -base64 48`
- `FILEBROWSER_PASSWORD` — надёжный пароль для filebrowser
- `RESTIC_PASSWORD` — пароль для шифрования бэкапов

**Необязательные (с дефолтными значениями):**
- `BASE_URL` — http://IP_сервера или http://homelab.local
- `VAULTWARDEN_SIGNUPS_ALLOWED` — false (после создания админа)
- `RESTIC_REPO` — путь к бэкапу (/mnt/backup/restic)
