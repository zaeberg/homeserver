# Systemd Units

Эта директория содержит systemd unit files для автоматизации бэкапов и тестирования восстановления.

## Обзор

Systemd timers используются для планирования периодического выполнения задач:
- **Локальные бэкапы** — ежедневно в 03:00
- **Облачные бэкапы** — еженедельно по воскресеньям в 04:00
- **Restore test** — ручной или через отдельный timer (настраивается отдельно)

## Unit Files

### Backup Timers

#### homelab-backup-local.{service,timer}

**Назначение:** Ежедневные локальные бэкапы на внешний диск

**Расписание:** Ежедневно в `03:00`

**Выполняемый скрипт:** `/srv/homelab/homelab-server/scripts/backup.sh local`

**Параметры:**
```ini
[Service]
Nice=10                   # Низкий приоритет CPU
IOSchedulingClass=idle    # Низкий приоритет I/O
IOSchedulingPriority=7    # Приоритет внутри idle класса
```

**Files:**
- `homelab-backup-local.service` — описание выполняемой команды
- `homelab-backup-local.timer` — расписание запуска

#### homelab-backup-cloud.{service,timer}

**Назначение:** Еженедельные облачные бэкапы (Yandex Disk через rclone)

**Расписание:** Еженедельно по воскресеньям в `04:00`

**Выполняемый скрипт:** `/srv/homelab/homelab-server/scripts/backup.sh cloud`

**Параметры:**
```ini
[Service]
Nice=15                   # Более низкий приоритет (cloud медленнее)
IOSchedulingClass=idle    # Низкий приоритет I/O
IOSchedulingPriority=7    # Приоритет внутри idle класса
```

**Files:**
- `homelab-backup-cloud.service` — описание выполняемой команды
- `homelab-backup-cloud.timer` — расписание запуска

### Restore Test

#### homelab-restore-test.service

**Назначение:** Тест восстановления бэкапа

**Расписание:** Нет встроенного timer (запускается вручную или создаётся отдельный timer)

**Выполняемый скрипт:** `/srv/homelab/homelab-server/scripts/restore_test.sh`

**Files:**
- `homelab-restore-test.service` — описание выполняемой команды

## Установка

### 1. Скопировать unit files

```bash
# Копировать все unit files в systemd
sudo cp systemd/homelab-*.service /etc/systemd/system/
sudo cp systemd/homelab-*.timer /etc/systemd/system/
```

### 2. Перезагрузить systemd

```bash
# Перечитать конфигурацию systemd
sudo systemctl daemon-reload
```

### 3. Включить timers

```bash
# Включить автоматический запуск
sudo systemctl enable homelab-backup-local.timer
sudo systemctl enable homelab-backup-cloud.timer

# Запустить timers немедленно (не ждать до следующего расписания)
sudo systemctl start homelab-backup-local.timer
sudo systemctl start homelab-backup-cloud.timer
```

### 4. Проверить статус

```bash
# Проверить статус timers
sudo systemctl status homelab-backup-local.timer
sudo systemctl status homelab-backup-cloud.timer

# Проверить расписание
sudo systemctl list-timers
```

## Управление

### Проверка статуса

```bash
# Статус timer (расписание, время следующего запуска)
sudo systemctl status homelab-backup-local.timer

# Статус service (последний запуск, результат)
sudo systemctl status homelab-backup-local.service

# Все timers проекта
sudo systemctl list-timers 'homelab-*'
```

### Ручной запуск

```bash
# Локальный бэкап (немедленно)
sudo systemctl start homelab-backup-local.service

# Облачный бэкап (немедленно)
sudo systemctl start homelab-backup-cloud.service

# Тест восстановления (немедленно)
sudo systemctl start homelab-restore-test.service
```

### Просмотр логов

```bash
# Логи последнего запуска
sudo journalctl -u homelab-backup-local.service -n 50

# Логи всех запусков
sudo journalctl -u homelab-backup-local.service

# Логи в real-time (если запущен сейчас)
sudo journalctl -u homelab-backup-local.service -f

# Локи за сегодня
sudo journalctl -u homelab-backup-local.service --since today

# Локи с фильтром
sudo journalctl -u homelab-backup-local.service | grep -i error
```

### Включение/отключение

```bash
# Включить автоматический запуск
sudo systemctl enable homelab-backup-local.timer

# Отключить автоматический запуск
sudo systemctl disable homelab-backup-local.timer

# Остановить timer (но не отключать)
sudo systemctl stop homelab-backup-local.timer

# Запустить заново
sudo systemctl start homelab-backup-local.timer
```

## Изменение расписания

### Формат OnCalendar

```ini
# Ежедневно в 03:00
OnCalendar=*-*-* 03:00:00

# Еженедельно по воскресеньям в 04:00
OnCalendar=Sun *-*-* 04:00:00

# Ежемесячно 1-го числа в 02:00
OnCalendar=*-*-1 02:00:00

# Каждые 6 часов
OnCalendar=*-*-* 00/6:00:00

# Каждую неделю в понедельник в 03:30
OnCalendar=Mon *-*-* 03:30:00

# В будние дни в 22:00
OnCalendar=Mon..Fri *-*-* 22:00:00
```

### Процедура изменения

1. **Отредактировать timer file:**
   ```bash
   sudo nano /etc/systemd/system/homelab-backup-local.timer
   ```

2. **Изменить OnCalendar:**
   ```ini
   [Timer]
   # Новое расписание
   OnCalendar=*-*-* 02:00:00  # Вместо 03:00
   Persistent=true
   ```

3. **Перезагрузить systemd:**
   ```bash
   sudo systemctl daemon-reload
   ```

4. **Перезапустить timer:**
   ```bash
   sudo systemctl restart homelab-backup-local.timer
   ```

5. **Проверить новое расписание:**
   ```bash
   sudo systemctl status homelab-backup-local.timer
   ```

## Параметры Service

### Nice (CPU приоритет)

```ini
Nice=10   # Низкий приоритет (диапазон: -20 высший, 19 низший)
```

**Значения:**
- `0` (по умолчанию) — нормальный приоритет
- `10` — низкий приоритет (для бэкапов)
- `15` — более низкий приоритет (для cloud бэкапов)
- `19` — самый низкий приоритет

### IOSchedulingClass (I/O приоритет)

```ini
IOSchedulingClass=idle    # Выполнять только когда система простаивает
```

**Значения:**
- `none` (по умолчанию) — нормальный приоритет
- `realtime` — наивысший приоритет (для realtime систем)
- `best-effort` — обычный приоритет (по умолчанию для большинства процессов)
- `idle` — низкий приоритет (для фоновых задач, бэкапов)

### IOSchedulingPriority (I/O приоритет внутри класса)

```ini
IOSchedulingPriority=7    # Приоритет 0-7 (0 = высший, 7 = низший)
```

**Только для `best-effort` и `idle` классов:**
- `0-3` — высокий приоритет
- `4` — средний приоритет
- `5-7` — низкий приоритет

### Security Settings

```ini
NoNewPrivileges=true    # Запретить получение новых привилегий
PrivateTmp=true        # Изолированная /tmp директория
```

**Дополнительные (опционально):**
```ini
ProtectSystem=strict    # Read-only доступ к /usr, /boot
ProtectHome=true        # Нет доступа к /home, /root
ReadWritePaths=/srv/data/backup  # Разрешить запись только в эту директорию
```

## Добавление restore test timer

**По умолчанию** нет timer для restore test. Создадим еженедельный:

### 1. Создать timer file

```bash
sudo nano /etc/systemd/system/homelab-restore-test.timer
```

```ini
[Unit]
Description=Homelab Restore Test Timer
Requires=homelab-restore-test.service

[Timer]
# Запускать еженедельно по субботам в 05:00 (после бэкапов)
OnCalendar=Sat *-*-* 05:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

### 2. Включить timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable homelab-restore-test.timer
sudo systemctl start homelab-restore-test.timer
```

### 3. Проверить

```bash
sudo systemctl status homelab-restore-test.timer
sudo systemctl list-timers 'homelab-*'
```

## Troubleshooting

### Timer не запускается

**Проблема:** Timer активен, но service не запускается

**Решение:**
```bash
# Проверить, что timer enabled и running
sudo systemctl status homelab-backup-local.timer

# Проверить логи timer
sudo journalctl -u homelab-backup-local.timer

# Попробовать запустить вручную
sudo systemctl start homelab-backup-local.service

# Проверить права на скрипт
ls -la /srv/homelab/homelab-server/scripts/backup.sh
chmod +x /srv/homelab/homelab-server/scripts/backup.sh
```

### Service failed

**Проблема:** Service завершился с ошибкой

**Решение:**
```bash
# Проверить exit code
sudo journalctl -u homelab-backup-local.service -n 50

# Проверить, что .env существует
ls -la /srv/homelab/homelab-server/compose/.env

# Проверить Restic репозиторий
export RESTIC_PASSWORD="your-password"
export RESTIC_REPOSITORY="/mnt/backup/restic"
restic snapshots
```

### Timer пропустил запуск

**Проблема:** Компьютер был выключен в расписанное время

**Решение:**
```ini
# Проверить, что Persistent=true в timer
[Timer]
Persistent=true  # Запустить при следующей возможности, если был пропущен
```

Если `Persistent=false`, timer пропустит запуск, если система была выключена.

### Backup занимает слишком много времени

**Проблема:** Бэкап тормозит систему

**Решение:**
```ini
# Увеличить Nice (снизить приоритет)
Nice=19

# Убедиться, что IOSchedulingClass=idle
IOSchedulingClass=idle

# Или изменить расписание на менее загруженное время
OnCalendar=*-*-* 05:00:00  # Вместо 03:00
```

## Мониторинг

### Проверить последнее выполнение

```bash
# Время последнего запуска
sudo systemctl status homelab-backup-local.service

# Логи последнего запуска
sudo journalctl -u homelab-backup-local.service -n 1 --show-cursor

# Все запуски за сегодня
sudo journalctl -u homelab-backup-local.service --since today
```

### Статистика запусков

```bash
# Показать все таймеры
sudo systemctl list-timers

# Показать только homelab таймеры
sudo systemctl list-timers 'homelab-*'

# Подробная информация
systemctl show homelab-backup-local.timer
```

### Интеграция с мониторингом

```bash
# Создать скрипт для проверки
cat > /usr/local/bin/check-backups.sh <<'EOF'
#!/bin/bash
LAST_BACKUP=$(systemctl show homelab-backup-local.service -p ExecMainExitTimestamp)
LAST_RUN=$(date -d "$LAST_BACKUP" +%s)
NOW=$(date +%s)
AGE=$(( (NOW - LAST_RUN) / 86400 ))

if [ $AGE -gt 2 ]; then
    echo "WARNING: Last backup is $AGE days old!"
    exit 1
fi
EOF

chmod +x /usr/local/bin/check-backups.sh

# Добавить в мониторинг (например, Uptime Kuma cron)
```

## Дальнейшее чтение

- `systemd.timer(5)` — man page по timers
- `systemd.service(5)` — man page по services
- `scripts/README.md` — описание скриптов
- `docs/04_backup_restore.md` — подробнее о бэкапах
- [systemd.time(7)](https://man7.org/linux/man-pages/man7/systemd.time.7.html) — формат OnCalendar
