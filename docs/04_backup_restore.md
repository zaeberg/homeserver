# Backup & Restore

## Обзор

Система бэкапов использует **Restic** — надёжный инструмент для дедуплицированных бэкапов с поддержкой шифрования.

### Что бэкапится
- `/srv/data/vaultwarden` — данные Vaultwarden (самое важное!)
- `/srv/homelab/homelab-server` — конфиги репозитория (без `.env`)

### Исключается из бэкапа
- `.env` файлы (секреты)
- `*.log` файлы
- `data/` директории (временные данные)
- `backups/` директории

### Политика удержания (retention policy)
- 7 ежедневных бэкапов
- 4 еженедельных бэкапов
- 6 ежемесячных бэкапов

## Инициализация Restic репозитория

### 1. Подготовка хранилища

```bash
# Смонтировать внешний диск (если ещё не)
sudo lsblk  # Найти диск
sudo mkdir -p /mnt/backup
sudo mount /dev/sdX1 /mnt/backup

# Добавить в /etc/fstab для автозапуска
echo '/dev/sdX1 /mnt/backup ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

### 2. Установка Restic

```bash
# Ubuntu/Debian
sudo apt install restic

# Проверить версию
restic version
```

### 3. Инициализация репозитория

```bash
cd /srv/homelab/homelab-server

# Загрузить переменные из .env
source compose/.env

# Проверить переменные
echo "RESTIC_REPO: $RESTIC_REPO"
echo "RESTIC_PASSWORD: [HIDDEN]"

# Инициализировать restic репозиторий
restic init
```

Ожидаемый вывод:
```
created restic repository <ID> at ...
```

## Ручной бэкап

```bash
cd /srv/homelab/homelab-server

# Запустить бэкап
./scripts/backup.sh
```

Скрипт выполнит:
1. Проверку переменных `RESTIC_REPO` и `RESTIC_PASSWORD`
2. Бэкап указанных директорий
3. Очистку старых снапшотов по политике
4. Запись в лог `/srv/data/backup/backup.log`

## Автоматический бэкап (systemd timer)

### 1. Копирование unit файлов

```bash
# Скопировать unit файлы в systemd
sudo cp systemd/homelab-backup.{service,timer} /etc/systemd/system/
sudo cp systemd/homelab-restore-test.service /etc/systemd/system/

# Перезагрузить systemd
sudo systemctl daemon-reload
```

### 2. Включение автоматического бэкапа

```bash
# Включить timer
sudo systemctl enable homelab-backup.timer

# Запустить timer
sudo systemctl start homelab-backup.timer

# Проверить статус
sudo systemctl status homelab-backup.timer
sudo systemctl list-timers | grep homelab
```

Бэкап будет запускаться ежедневно в 03:00.

### 3. Проверка следующего запуска

```bash
systemctl status homelab-backup.timer
```

## Управление бэкапами

### Просмотр снапшотов

```bash
# Все снапшоты
restic snapshots

# В формате таблицы
restic snapshots --table

# Только последние 10
restic snapshots --latest 10
```

### Статистика репозитория

```bash
# Общий размер
restic stats

# По отдельным снапшотам
restic stats latest
```

### Ручная очистка

```bash
# Удалить снапшоты по политике (но не применять --prune)
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --dry-run

# Применить очистку (удалить данные)
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
```

### Проверка целостности

```bash
# Проверить целостность репозитория
restic check

# С подробным выводом
restic check --read-data
```

## Восстановление (Restore)

### Восстановление последних данных

```bash
# Восстановить в ту же директорию
restic restore latest --target /

# Восстановить в другую директорию
restic restore latest --target /tmp/restore
```

### Восстановление конкретного снапшота

```bash
# Найти ID снапшота
restic snapshots

# Восстановить по ID
restic restore <ID> --target /tmp/restore
```

### Восстановление только одного файла

```bash
# Найти файл в бэкапе
restic find vaultwarden.db

# Восстановить файл
restic restore latest --target /tmp --include="/srv/data/vaultwarden/data/vaultwarden.db"
```

### Восстановление на новом сервере

```bash
# 1. Установить restic
sudo apt install restic

# 2. Смонтировать backup диск
sudo mount /dev/sdX1 /mnt/backup

# 3. Скопировать репозиторий
cd /srv/homelab/homelab-server
cp compose/.env.example compose/.env
nano compose/.env  # Заполнить RESTIC_REPO и RESTIC_PASSWORD

# 4. Восстановить данные
source compose/.env
restic restore latest --target /

# 5. Создать директории для данных
sudo mkdir -p /srv/data/{vaultwarden,syncthing,filebrowser,uptime-kuma,caddy}
sudo chown -R $USER:$USER /srv/data

# 6. Деплойнуть сервисы
./scripts/deploy.sh
```

## Restore-test (проверка восстановимости)

### Запуск restore-test

```bash
cd /srv/homelab/homelab-server

# Запустить тест восстановления
./scripts/restore_test.sh
```

Скрипт выполнит:
1. Восстановление последнего снапшота во временную директорию
2. Запуск временного контейнера с восстановленными данными
3. Проверку доступности сервиса
4. Очистку времённых контейнеров и данных

### Запуск через systemd

```bash
# Ручной запуск
sudo systemctl start homelab-restore-test.service

# Проверить логи
journalctl -u homelab-restore-test.service -f
```

## Резервное копирование .env файла

ВАЖНО: `.env` файл не бэкапится автоматически (он содержит секреты). Создайте отдельную защищённую копию:

```bash
# Экспортировать переменные (без паролей!)
cp compose/.env compose/.env.backup

# Скопировать на безопасное хранилище
scp compose/.env.backup user@backup-server:/secure/location/

# Или использовать password manager для хранения секретов
```

## Альтернативные бэкап-хранилища

### S3-совместимые хранилища

```bash
# В .env:
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export RESTIC_REPO="s3:https://s3.example.com/bucket"
export RESTIC_PASSWORD="your-password"
```

### Rest Server (бэкап по HTTP)

```bash
# На backup-сервере:
docker run -d --name rest-server \
  -p 8000:8000 \
  -v /data/restic:/data \
  restic/rest-server

# На homelab сервере в .env:
export RESTIC_REPO="rest:http://backup-server:8000/homelab"
```

### SFTP

```bash
export RESTIC_REPO="sftp:user@backup-server:/backup/path"
```

## Мониторинг бэкапов

### Проверить логи

```bash
# Логи бэкапов
tail -f /srv/data/backup/backup.log

# Логи systemd timer
journalctl -u homelab-backup.service -f
```

### Уведомления (опционально)

Добавьте в `backup.sh` отправку уведомлений после успешного бэкапа:

```bash
# Пример для Telegram
curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id=<CHAT_ID> \
  -d text="Homelab backup completed successfully"
```

## Troubleshooting

### Репозиторий заблокирован

```bash
# Разблокировать (если уверены, что другой процесс не запущен)
restic unlock
```

### Забыт пароль от репозитория

Пароль от Restic восстановить **нельзя**. Храните его в безопасном месте (password manager).

### Ошибка "backend not ready"

Проверьте подключение к хранилищу:
```bash
# Для локального диска
ls /mnt/backup/restic

# Для S3
curl https://s3.example.com
```
