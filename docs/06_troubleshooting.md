# Troubleshooting Guide

## Общие шаги диагностики

Если что-то не работает, выполните следующие шаги по порядку:

```bash
cd /srv/homelab/homelab-server

# 1. Проверить статус контейнеров
docker compose ps

# 2. Проверить логи
docker compose logs --tail=50

# 3. Запустить healthcheck
./scripts/healthcheck.sh

# 4. Проверить валидацию конфигурации
./scripts/validate.sh
```

---

## Проблема: Сервис не стартует

### Симптомы
```bash
docker compose ps
# Output: Exit 1 или Restarting
```

### Диагностика

```bash
# Проверить логи контейнера
docker compose logs <service-name>

# Последние 100 строк
docker compose logs --tail=100 <service-name>

# Подробная информация о контейнере
docker inspect <container-name>
```

### Возможные причины и решения

#### 1. Ошибка в конфигурации

**Симптом:** В логах есть сообщения об ошибках конфигурации

**Решение:**
```bash
# Проверить .env
cat compose/.env

# Валидация compose.yml
docker compose -f compose/compose.yml config

# Проверить Traefik конфигурацию
cat compose/traefik/traefik.yml
cat compose/traefik/dynamic.yml
```

#### 2. Нет доступа к данным

**Симптом:** `Permission denied` в логах

**Решение:**
```bash
# Проверить права на директорию
ls -la /srv/data/vaultwarden

# Исправить права
sudo chown -R $USER:$USER /srv/data
sudo chmod -R 755 /srv/data

# Перезапустить сервис
docker compose --env-file compose/.env -f compose/compose.yml restart <service>
```

#### 3. Порт уже занят

**Симптом:** `port is already allocated`

**Решение:**
```bash
# Найти процесс, занимающий порт
sudo ss -tulpn | grep :80
sudo lsof -i :80

# Остановить конфликтующий сервис
sudo systemctl stop apache2  # или другой сервис

# Или изменить порт в compose.yml
nano compose/compose.yml
```

#### 4: Недостаточно памяти

**Симптом:** `Cannot allocate memory`

**Решение:**
```bash
# Проверить свободную память
free -h

# Остановить другие контейнеры
docker stop <other-container>

# Добавить swap (если нужно)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## Проблема: Диск заполнен

### Симптомы
- Контейнеры не запускаются
- Ошибки `No space left on device`
- Бэкапы не выполняются

### Диагностика

```bash
# Проверить свободное место
df -h

# Размер директорий данных
du -sh /srv/data/*

# Размер Docker
docker system df
```

### Решения

#### 1. Очистка Docker

```bash
# Удалить неиспользуемые образы
docker image prune -a

# Удалить неиспользуемые volumes (ОСТОРОЖНО!)
docker volume prune

# Полная очистка
docker system prune -a --volumes
```

#### 2. Очистка логов

```bash
# Логи контейнеров
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Логи бэкапа
sudo truncate -s 0 /srv/data/backup/backup.log

# Или настроить ротацию логов (см. infra/docker/daemon.json)
```

#### 3. Очистка старых бэкапов

```bash
# Проверить размер бэкапов
restic stats

# Удалить старые снапшоты
restic forget --keep-daily 3 --keep-weekly 2 --prune
```

#### 4. Расширение диска

Если на диске регулярно заканчивается место, рассмотрите:
- Добавление второго диска для бэкапов
- Использование сетевого хранилища для бэкапов (NFS, S3)
- Перенос данных на больший диск

---

## Проблема: Restic repo недоступен

### Симптомы
- Бэкап не выполняется
- Ошибка `backend not ready` или `connection refused`

### Диагностика

```bash
# Проверить переменные окружения
source compose/.env
echo $RESTIC_REPO

# Проверить подключение к хранилищу
ls /mnt/backup/restic
```

### Решения

#### 1. Диск не смонтирован

```bash
# Смонтировать диск
sudo mount /mnt/backup

# Или добавить в /etc/fstab для автозапуска
echo '/dev/sdX1 /mnt/backup ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

#### 2. Неверный путь к репозиторию

```bash
# Проверить путь
ls -la /mnt/backup/

# Исправить в .env
nano compose/.env
# RESTIC_REPO=/mnt/backup/restic
```

#### 3. Репозиторий заблокирован

```bash
# Разблокировать
restic unlock
```

#### 4. Rclone backend недоступен (Яндекс Диск)

**Симптомы:**
- Ошибка `rclone not found`
- Ошибка `backend not ready` для rclone
- Ошибка авторизации Яндекс Диск

**Диагностика:**
```bash
# Проверить, что rclone установлен
which rclone
rclone version

# Проверить конфигурацию rclone
rclone config show yandex

# Проверить подключение к Яндекс Диск
rclone lsd yandex:
rclone about yandex:
```

**Решения:**

```bash
# Если rclone не установлен
sudo apt install rclone

# Настроить rclone заново
rclone config
# Выбрать: n) New remote
# Имя: yandex
# Storage: yandex
# Пройти авторизацию в браузере

# Проверить подключение после настройки
rclone about yandex:
```

**Проверка переменных окружения:**
```bash
# В .env должно быть:
RESTIC_REPO_CLOUD=rclone:yandex:homelab-backups

# Проверить
source compose/.env
echo $RESTIC_REPO_CLOUD
```

---

## Проблема: Сервис недоступен по HTTP

### Симптомы
- `curl: (7) Failed to connect`
- `502 Bad Gateway`
- `503 Service Unavailable`

### Диагностика

```bash
# Проверить, что контейнер работает
docker compose ps

# Проверить логи
docker compose logs traefik
docker compose logs <service>

# Проверить, что порты открыты
sudo ss -tulpn | grep ':80\|443\|8080'
```

### Решения

#### 1. Traefik не работает

```bash
# Проверить логи Traefik
docker compose logs traefik

# Проверить конфигурацию
docker compose ps traefik
docker exec homelab-traefik cat /etc/traefik/traefik.yml

# Перезапустить Traefik
docker compose --env-file compose/.env -f compose/compose.yml restart traefik
```

#### 2. Сервис не отвечает

```bash
# Проверить логи сервиса
docker compose logs vaultwarden

# Проверить, что сервис запущен внутри контейнера
docker exec homelab-vaultwarden ps aux

# Проверить здоровье сервиса
docker exec homelab-vaultwarden wget -O- http://localhost:80/alive
```

#### 3. Firewall блокирует

```bash
# Проверить правила firewall
sudo ufw status

# Разрешить порт 80
sudo ufw allow 80/tcp

# Или временно отключить firewall для теста
sudo ufw disable
```

---

## Проблема: Медленная работа сервисов

### Симптомы
- Долгая загрузка страниц
- Таймауты при подключении

### Диагностика

```bash
# Проверить загрузку системы
htop
# или
top

# Проверить использование ресурсов контейнерами
docker stats

# Проверить диск I/O
iostat -x 1
```

### Решения

#### 1. Недостаточно CPU/RAM

```bash
# Остановить тяжёлые сервисы
docker compose stop uptime-kuma

# Или обновить сервер
```

#### 2. Медленный диск

```bash
# Проверить скорость диска
dd if=/dev/zero of=/tmp/test bs=1M count=100 oflag=direct

# Рассмотреть использование SSD вместо HDD
```

#### 3. Перегрузка контейнера

```bash
# Перезапустить контейнер
docker compose restart vaultwarden
```

---

## Проблема: Данные потеряны

### Симптомы
- Сервис запускается с "чистой" конфигурацией
- Данные не сохраняются после перезапуска

### Диагностика

```bash
# Проверить, что volume подключён
docker inspect homelab-vaultwarden | grep -A 10 Mounts

# Проверить наличие данных
ls -la /srv/data/vaultwarden
```

### Решения

#### 1. Volume не подключён

```bash
# Проверить compose.yml
cat compose/compose.yml | grep -A 5 volumes

# Должно быть:
# volumes:
#   - /srv/data/vaultwarden:/data
```

#### 2. Восстановление из бэкапа

```bash
# Восстановить последние данные
restic restore latest --target /

# Перезапустить сервис
docker compose --env-file compose/.env -f compose/compose.yml restart vaultwarden
```

---

## Проблема: Systemd timer не работает

### Симптомы
- Бэкап не запускается автоматически
- Timer в статусе `inactive`

### Диагностика

```bash
# Проверить статус timer
systemctl status homelab-backup.timer

# Проверить следующее выполнение
systemctl list-timers | grep homelab

# Проверить логи
journalctl -u homelab-backup.service -n 50
```

### Решения

#### 1. Timer не включён

```bash
# Включить timer
sudo systemctl enable homelab-backup.timer

# Запустить timer
sudo systemctl start homelab-backup.timer
```

#### 2. Неправильный путь в unit файле

```bash
# Проверить unit файл
cat /etc/systemd/system/homelab-backup.service

# Путь должен быть:
# ExecStart=/srv/homelab/homelab-server/scripts/backup.sh

# Перезагрузить systemd
sudo systemctl daemon-reload
sudo systemctl restart homelab-backup.timer
```

#### 3. Нет прав на выполнение скрипта

```bash
# Сделать скрипт исполняемым
chmod +x scripts/backup.sh
```

---

## Проблема: Vaultwarden не работает

### Частые проблемы

#### Не могу войти как администратор

```bash
# Проверить, что ADMIN_TOKEN установлен
source compose/.env
echo $VAULTWARDEN_ADMIN_TOKEN

# Сбросить токен (сгенерировать новый)
openssl rand -base64 48

# Обновить .env и перезапустить
nano compose/.env
docker compose restart vaultwarden
```

#### Регистрация отключена, не могу создать пользователя

```bash
# Временно включить регистрацию
nano compose/.env
# VAULTWARDEN_SIGNUPS_ALLOWED=true

# Перезапустить
docker compose restart vaultwarden

# После создания пользователя отключить
```

---

## Проблема: Syncthing не синхронизирует

### Диагностика

```bash
# Проверить логи
docker compose logs syncthing

# Проверить статус соединений
# Открыть http://SERVER_IP/sync -> Actions -> Connections
```

### Решения

#### 1. Устройства не подключены

```bash
# Убедитесь, что устройства приняты с обеих сторон
# Syncthing GUI -> Actions -> Connections -> Show ID
```

#### 2. Папки не расшарены

```bash
# Проверить, что папки добавлены на обоих устройствах
# И расшарены с правильными устройствами
```

---

## Логи и отчёты для диагностики

### Собрать полный отчёт

```bash
#!/bin/bash
# collect_diagnostic_info.sh

REPORT_FILE="/tmp/homelab-diagnostic-$(date +%F).txt"

{
  echo "=== Homelab Diagnostic Report ==="
  echo "Date: $(date)"
  echo ""

  echo "=== System Info ==="
  uname -a
  echo ""

  echo "=== Docker Info ==="
  docker --version
  docker compose version
  echo ""

  echo "=== Container Status ==="
  docker compose ps
  echo ""

  echo "=== Disk Usage ==="
  df -h
  echo ""

  echo "=== Memory ==="
  free -h
  echo ""

  echo "=== Docker Logs (last 50 lines) ==="
  docker compose logs --tail=50
  echo ""

  echo "=== Healthcheck ==="
  ./scripts/healthcheck.sh || true
  echo ""

  echo "=== Validation ==="
  ./scripts/validate.sh || true
} > "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
cat "$REPORT_FILE"
```

---

## Когда обратиться за помощью

Если вы не смогли решить проблему самостоятельно:

1. Соберите диагностическую информацию (см. выше)
2. Подготовьте логи:
   ```bash
   docker compose logs > docker-compose.log
   journalctl -u homelab-backup.service > backup.log
   ```
3. Опишите:
   - Что вы делали перед проблемой
   - Какие действия уже предприняли
   - Что ожидали, а что получили
