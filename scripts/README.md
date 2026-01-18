# Скрипты автоматизации

Эта директория содержит Bash-скрипты для автоматизации деплоя, валидации, бэкапов и мониторинга homeserver'а.

## Требования

Для работы скриптов необходимы следующие компоненты:

### Обязательные

| Компонент | Версия | Для чего |
|-----------|--------|----------|
| **Bash** | 4.0+ | Исполнение всех скриптов |
| **Docker** | 20.10+ | Запуск контейнеров |
| **Docker Compose** | v2 | Оркестрация сервисов |

### Опциональные

| Компонент | Версия | Для чего |
|-----------|--------|----------|
| **curl** или **wget** | Любая | HTTP healthchecks |
| **Restic** | 0.14+ | Бэкапы (backup.sh, restore_test.sh) |
| **jq** | 1.6+ | Парсинг JSON в restore_test.sh |
| **yamllint** | Любая | Валидация YAML (опционально) |

### Установка требований

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose-v2 curl wget jq restic yamllint

# Добавить пользователя в docker group (чтобы не писать sudo)
sudo usermod -aG docker $USER
newgrp docker
```

## Скрипты

### deploy.sh

**Назначение:** Деплой всех сервисов на сервер

**Использование:**
```bash
./scripts/deploy.sh
```

**Что делает:**
1. Проверяет наличие `compose/.env`
2. Останавливает существующие контейнеры
3. Pull'ит последние Docker образы
4. Запускает все сервисы в фоне (`-d`)

**Exit codes:**
- `0` — Деплой успешен
- `1` — `.env` файл не найден или docker compose failed

**Пример вывода:**
```
=== Homelab Deployment ===

✓ Environment file found

Stopping existing containers (if any)...

Starting services and pulling latest images...
✓ Services deployed successfully
```

**Примечания:**
- Скрипт перезапускает ВСЕ сервисы, включая те, что уже работают
- Использует `--pull always` для гарантии актуальности образов
- После деплоя рекомендуется запустить `healthcheck.sh`

---

### validate.sh

**Назначение:** Валидация конфигурации и проверка безопасности

**Использование:**
```bash
./scripts/validate.sh
```

**Что делает:**
1. Проверяет наличие обязательных файлов (compose.yml, traefik configs)
2. Проверяет Docker Compose синтаксис
3. Ищет секреты в файлах (PASSWORD, SECRET, API_KEY, etc.)
4. Проверяет права доступа к `.env` (должен быть `600`)

**Exit codes:**
- `0` — Все проверки пройдены
- `1` — Найдены ошибки или критичные проблемы

**Проверяемые файлы:**
```
compose/compose.yml
compose/traefik/traefik.yml
compose/traefik/dynamic.yml
compose/.env (на наличие и права доступа)
```

**Пример вывода:**
```
=== Homelab Repository Validation ===

Checking required files...
✓ File exists: compose/compose.yml
✓ File exists: compose/traefik/traefik.yml
✓ File exists: compose/traefik/dynamic.yml

Validating Docker Compose configuration...
✓ Docker Compose configuration is valid

Checking for secrets in tracked files...
✓ No secrets found in tracked files

Checking .env file permissions...
✓ .env file has correct permissions (600)

=========================================
✓ All validation checks passed!
```

**Примечания:**
- Запускайте этот скрипт перед коммитом изменений
- Если найдены секреты, НЕ коммитьте их!
- Для изменения прав доступа: `chmod 600 compose/.env`

---

### healthcheck.sh

**Назначение:** Проверка HTTP доступности сервисов

**Использование:**
```bash
./scripts/healthcheck.sh
```

**Что делает:**
1. Проверяет каждый endpoint через HTTP GET
2. Проверяет статус код (200-399 = OK)
3. Подсчитывает количество failed сервисов

**Exit codes:**
- `0` — Все сервисы здоровы
- `1` — Один или более сервисов недоступны
- `2` — Не найдены `curl` или `wget`

**Проверяемые endpoints:**
```
$BASE_URL/              - Landing page
$BASE_URL/vault/        - Vaultwarden (если настроен)
$BASE_URL/sync/         - Syncthing (если настроен)
$BASE_URL/files/        - Filebrowser (если настроен)
$BASE_URL/status/       - Uptime Kuma (если настроен)
```

**Environment variables:**
```bash
# Базовый URL для проверок (по умолчанию: http://localhost)
export BASE_URL="http://home.local"
./scripts/healthcheck.sh
```

**Пример вывода:**
```
=== Homelab Healthcheck ===

Checking endpoints at http://home.local...

✓ Landing page is accessible (200)
✓ Traefik Dashboard is accessible (200)

=========================================
✓ All services are healthy!
```

**Примечания:**
- Скрипт использует `curl` если доступен, иначе `wget`
- Таймаут каждого запроса: 5 секунд
- Для работы нужна переменная `BASE_URL` (или `http://localhost` по умолчанию)

---

### backup.sh

**Назначение:** Создание бэкапов через Restic

**Использование:**
```bash
# Локальный бэкап
./scripts/backup.sh local

# Облачный бэкап
./scripts/backup.sh cloud
```

**Что делает:**
1. Загружает переменные из `compose/.env`
2. Проверяет наличие RESTIC_PASSWORD и RESTIC_REPO_*
3. Запускает `restic backup` с указанными целями
4. Применяет retention policy (keep daily: 7, weekly: 4, monthly: 6)
5. Сохраняет лог в `/srv/data/backup/backup.log`

**Exit codes:**
- `0` — Бэкап успешен
- `1` — Ошибка (отсутствует `.env`, не настроен Restic, etc.)

**Environment variables (из .env):**
```bash
# Обязательные
RESTIC_PASSWORD=your-secure-password
BACKUP_TARGETS="/srv/data /srv/homelab/homelab-server"

# Локальный репозиторий (для backup.sh local)
RESTIC_REPO_LOCAL=/mnt/backup/restic

# Облачный репозиторий (для backup.sh cloud)
RESTIC_REPO_CLOUD=rclone:yandex:homelab-backups

# Опциональные (retention policy)
# По умолчанию: --keep-daily 7 --keep-weekly 4 --keep-monthly 6
```

**Retention policy:**
```bash
# Оставлять:
--keep-daily 7      # Последние 7 дневных бэкапов
--keep-weekly 4     # Последние 4 недельных бэкапа
--keep-monthly 6    # Последние 6 месячных бэкапов
```

**Пример вывода:**
```
[2025-01-18 03:00:00] Starting local backup...
✓ Restic repository initialized
✓ Backup completed: 1.2GB, 453 files added
✓ Retention policy applied
✓ Backup successful
```

**Примечания:**
- **КРИТИЧНО:** Сохраните `RESTIC_PASSWORD` в надёжном месте (password manager)
- Без пароля восстановление бэкапа НЕВОЗМОЖНО
- Первый бэкап будет полным, последующие — инкрементальными (дедупликация)
- Логи сохраняются в `/srv/data/backup/backup.log`
- Автоматический запуск через systemd timers (см. `systemd/README.md`)

---

### restore_test.sh

**Назначение:** Тест восстановления бэкапа

**Использование:**
```bash
./scripts/restore_test.sh [local|cloud]
```

**Что делает:**
1. Восстанавливает последний бэкап во временную директорию (`/tmp/restore-test-`)
2. Проверяет наличие критичных файлов
3. Сравнивает размер данных
4. Удаляет временную директорию

**Exit codes:**
- `0` — Тест успешен
- `1` — Тест failed (бэкап повреждён или не восстанавливается)
- `2` — Не найден `jq`

**Требования:**
- `jq` для парсинга JSON вывода Restic
- Смонтированный backup disk (для local) или настроенный rclone (для cloud)

**Пример вывода:**
```
=== Restore Test ===

Testing local backup restoration...
✓ Restoring latest snapshot to /tmp/restore-test-12345
✓ Snapshot restored: 1.2GB, 453 files
✓ Critical files present:
  - compose/compose.yml
  - compose/traefik/traefik.yml
✓ Data size matches expected
✓ Test completed successfully

Cleaning up...
✓ Temporary files removed
```

**Примечания:**
- Рекомендуется запускать еженедельно (автоматически через systemd)
- При failure — проверить логи в `/tmp/restore-test-diagnostic.log`
- Временная директория удаляется автоматически даже при ошибке

---

## Error Handling

Все скрипты используют `set -e` для немедленного выхода при ошибке. Цветной вывод помогает быстро идентифицировать проблемы:

```
✓  - Зелёный: успех
✗  - Красный: ошибка
⚠  - Жёлтый: предупреждение
```

## Troubleshooting

### Permission denied при запуске скрипта

```bash
chmod +x scripts/*.sh
```

### validate.sh находит секреты

**Проблема:** В коммитимых файлах найдены секреты

**Решение:**
```bash
# 1. Удалить секреты из файлов
# 2. Переместить их в compose/.env
# 3. Добавить compose/.env в .gitignore (если ещё нет)
git add compose/.env
git commit -m "chore: move secrets to .env"
```

### backup.sh failed: repository not found

**Проблема:** Restic репозиторий не инициализирован

**Решение:**
```bash
# Инициализировать локальный репозиторий
export RESTIC_PASSWORD="your-password"
export RESTIC_REPOSITORY="/mnt/backup/restic"
restic init

# Или облачный (через rclone)
export RESTIC_REPOSITORY="rclone:yandex:homelab-backups"
restic init
```

### healthcheck.sh fails: connection refused

**Проблема:** Сервисы не запущены или неправильный BASE_URL

**Решение:**
```bash
# Проверить, что контейнеры запущены
docker ps

# Проверить правильный BASE_URL
export BASE_URL="http://home.local"  # Или ваш домен
./scripts/healthcheck.sh
```

## Best Practices

1. **Всегда запускайте `validate.sh` перед коммитом**
   ```bash
   ./scripts/validate.sh && git commit -m "..."
   ```

2. **Проверяйте healthcheck после деплоя**
   ```bash
   ./scripts/deploy.sh && ./scripts/healthcheck.sh
   ```

3. **Регулярно тестируйте восстановление бэкапов**
   - Systemd timer запускает `restore_test.sh` еженедельно
   - Проверяйте логи: `journalctl -u homelab-restore-test`

4. **Мониторьте логи бэкапов**
   ```bash
   # Локи бэкапов
   cat /srv/data/backup/backup.log

   # Systemd logs
   journalctl -u homelab-backup-local
   journalctl -u homelab-backup-cloud
   ```

## Дальнейшее чтение

- `systemd/README.md` — автоматизация через systemd timers
- `docs/04_backup_restore.md` — подробнее о бэкапах и восстановлении
- `DEVELOPMENT.md` — workflow для разработчиков
- [Restic Documentation](https://restic.readthedocs.io/)
