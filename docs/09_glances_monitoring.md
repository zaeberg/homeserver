# Glances - System Monitoring

Glances - это кроссплатформенная система мониторинга ресурсов сервера в реальном времени с веб-интерфейсом. Альтернатива htop/iotop с возможностью мониторинга через браузер.

## Что мониторит Glances

- **CPU** - загрузка процессоров по ядрам и в целом
- **Memory** - RAM, SWAP, использование
- **Disk** - I/O операции, использование файловой системы
- **Network** - трафик по интерфейсам
- **Processes** - список процессов с сортировкой по CPU/RAM
- **Docker** - состояние Docker контейнеров
- **Sensors** - температура, напряжение, вентиляторы (если поддерживаются)
- **SMART** - состояние дисков (требует дополнительной настройки)

## Доступ к сервису

- **Web UI**: http://glances.home.local
- **Traefik Dashboard**: http://traefik.home.local/dashboard/ (проверка маршрутизации)

## Структура файлов

```
compose/
├── compose.yml              # Docker Compose конфиг (сервис glances)
└── glances/
    └── glances.conf         # Конфигурационный файл
```

## Конфигурация

Основные настройки находятся в `compose/glances/glances.conf`:

```ini
[global]
# Частота обновления (секунды)
refresh=1

# История для графиков (секунды)
history=20

[webserver]
# Порт web-сервера
port=61208

[docker]
# Мониторинг Docker контейнеров
enabled=true
```

Документация по конфигурации: https://glances.readthedocs.io/en/latest/config.html

## Изменение порта Web UI

По умолчанию Glances работает на порту **61208**. Чтобы изменить порт:

1. Отредактируйте `compose/glances/glances.conf`:
   ```ini
   [webserver]
   port=8080  # Новый порт
   ```

2. Измените Traefik labels в `compose/compose.yml`:
   ```yaml
   labels:
     - "traefik.http.services.glances.loadbalancer.server.port=8080"  # Новый порт
   ```

3. Перезапустите сервис:
   ```bash
   ./scripts/deploy.sh
   ```

## Расширенные функции

### SMART мониторинг дисков

Для мониторинга S.M.A.R.T. состояния дисков требуются дополнительные права:

1. Раскомментируйте в `compose/compose.yml`:
   ```yaml
   cap_add:
     - SYS_RAWIO   # Для SATA дисков
     # или
     - SYS_ADMIN   # Для NVMe дисков
   ```

2. Раскомментируйте в `compose/glances/glances.conf`:
   ```ini
   [smart]
   enabled=true
   ```

3. Перезапустите сервис.

### GPU мониторинг (Nvidia)

Для мониторинга GPU Nvidia:

1. Раскомментируйте в `compose/compose.yml`:
   ```yaml
   deploy:
     resources:
       reservations:
         devices:
           - driver: nvidia
             count: 1
             capabilities: [gpu]
   ```

2. Установите Nvidia Runtime на хост-системе.

### Защита веб-интерфейса паролем

Glances поддерживает Basic Auth. Для настройки:

1. Создайте файл с паролем:
   ```bash
   echo "mysecretpassword" > compose/glances/password.txt
   ```

2. Измените `GLANCES_OPT` в `compose/compose.yml`:
   ```yaml
   environment:
     - GLANCES_OPT=-C /glances/conf/glances.conf -w --password /glances/conf/password.txt
   ```

3. Альтернативно - используйте Traefik Basic Auth middleware (см. `docs/07_adding_services.md`).

## Troubleshooting

### Glances не видит все процессы

**Проблема**: Glances показывает только свои процессы.

**Решение**: Проверьте, что `pid: host` установлен в `compose/compose.yml`:
```yaml
glances:
  pid: "host"  # Это обязательно!
```

### Glances не видит Docker контейнеры

**Проблема**: Раздел Docker пустой.

**Решение**:
1. Проверьте, что docker.sock примонтирован:
   ```bash
   docker exec homelab-glances ls -la /var/run/docker.sock
   ```

2. Проверьте логи:
   ```bash
   docker logs homelab-glances | grep -i docker
   ```

### Web UI недоступен

**Проблема**: `http://glances.home.local` не открывается.

**Решение**:
1. Проверьте, что контейнер запущен:
   ```bash
   docker ps | grep glances
   ```

2. Проверьте логи:
   ```bash
   docker logs homelab-glances
   ```

3. Проверьте Traefik:
   ```bash
   docker logs homelab-traefik | grep glances
   ```

4. Проверьте healthcheck:
   ```bash
   docker exec homelab-glances curl -f http://localhost:61208/api/4/status
   ```

### Высокая нагрузка на CPU

**Проблема**: Glances потребляет много CPU.

**Решение**: Увеличьте интервал обновления в `compose/glances/glances.conf`:
```ini
[global]
refresh=5  # Вместо 1 секунды
```

### Проблемы с часовым поясом

**Проблема**: Неверное время в графиках.

**Решение**: Измените `TZ` в `compose/compose.yml`:
```yaml
environment:
  - TZ=Europe/Moscow  # Ваш часовой пояс
```

Список часовых поясов: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

## Бэкап и восстановление

### Что бэкапить

- **Конфигурация**: `compose/glances/glances.conf` - уже включена в `BACKUP_TARGETS`
- **Данные**: Glances не хранит постоянные данные (все метрики в реальном времени)

### Восстановление

1. Скопируйте конфиг из бэкапа:
   ```bash
   restic restore latest --target / --path-compose/glances/glances.conf
   ```

2. Перезапустите сервис:
   ```bash
   ./scripts/deploy.sh
   ```

## Мониторинг через API

Glances предоставляет REST API для интеграции с другими системами:

```bash
# Статус сервиса
curl http://glances.home.local/api/4/status

# Все метрики
curl http://glances.home.local/api/4/all

# Только CPU
curl http://glances.home.local/api/4/cpu

# Только процессы
curl http://glances.home.local/api/4/processlist
```

Документация по API: https://glances.readthedocs.io/en/latest/api.html

## Производительность и безопасность

### Resource Limits

Glances - лёгкий сервис, но при большом количестве процессов может потреблять ресурсы. Рекомендуемые лимиты:

```yaml
# В compose/compose.yml
glances:
  deploy:
    resources:
      limits:
        cpus: '0.5'
        memory: 256M
      reservations:
        cpus: '0.1'
        memory: 64M
```

### Безопасность

- ✅ Все volumes монтируются как read-only (кроме `/tmp`)
- ✅ Docker socket только на чтение (`:ro`)
- ✅ Не используется `privileged: true`
- ⚠️ `pid: host` требуется для мониторинга всех процессов (необходимо для работы)

Для дополнительной безопасности добавьте Basic Auth через Traefik middleware.

## Альтернативы

Если Glances не подходит, рассмотрите:
- **Netdata** - более тяжёлый, но с богатыми возможностями (https://www.netdata.cloud/)
- **Prometheus + Grafana** - для продвинутых пользователей (https://prometheus.io/)
- **htop** - локальный мониторинг без веб-интерфейса

## Полезные ссылки

- [Официальная документация](https://glances.readthedocs.io/)
- [GitHub репозиторий](https://github.com/nicolargo/glances)
- [Docker Hub](https://hub.docker.com/r/nicolargo/glances/)
- [Архитектура системы](./00_architecture.md)
- [Добавление сервисов](./07_adding_services.md)
