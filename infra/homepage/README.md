# Homepage Configuration

Homepage - это главная страница homelab с навигацией по всем сервисам, мониторингом их состояния и информационными виджетами.

## 📍 Как это работает

Конфиги Homepage хранятся в репозитории и автоматически копируются на сервер при деплое:

```
compose/homepage/config/          # Исходные конфиги (в репозитории)
       ↓ (копируются при деплое)
/srv/data/homepage/config/        # Рабочие конфиги (на сервере)
       ↓ (монтируются в контейнер)
homelab-homepage контейнер        # Homepage использует эти конфиги
```

## 🚀 Редактирование конфигов

### Способ 1: Локально (рекомендуется)

1. Отредактируй файлы в `compose/homepage/config/` в своём редакторе
2. Запушь изменения на сервер: `git push`
3. На сервере примени изменения: `./scripts/deploy.sh`

```bash
# Пример: добавить новый сервис
nano compose/homepage/config/services.yaml
git add compose/homepage/config/services.yaml
git commit -m "add new service to Homepage"
git push

# На сервере:
cd /srv/homelab/homelab-server
git pull
./scripts/deploy.sh
```

### Способ 2: Только деплой Homepage конфигов

Если нужно обновить только конфиги без перезапуска всех сервисов:

```bash
# На сервере
cd /srv/homelab/homelab-server
./scripts/deploy-homepage-config.sh

# Перезапустить только Homepage
docker compose -f compose/compose.yml restart homepage
```

### Способ 3: Редактирование на сервере (временно)

⚠️ **Важно:** При следующем деплое изменения будут перезаписаны!

```bash
# На сервере - быстрое редактирование
cd /srv/homelab/homelab-server
nano compose/homepage/config/services.yaml  # Изменить исходник
./scripts/deploy-homepage-config.sh         # Скопировать в /srv/data
```

Или:
```bash
# Прямое редактирование рабочих конфигов (потеряется при деплое!)
sudo nano /srv/data/homepage/config/services.yaml
docker compose -f compose/compose.yml restart homepage
```

## 📁 Структура конфигов

```
compose/homepage/config/
├── settings.yaml       # Основные настройки (тема, заголовок, логотип)
├── services.yaml        # Сервисы для мониторинга состояния (online/offline)
├── bookmarks.yaml       # Закладки (быстрые ссылки на сервисы)
└── widgets.yaml         # Информационные виджеты (ресурсы, погода, etc.)
```

### settings.yaml

Основные настройки внешнего вида:

```yaml
title: Homelab
subtitle: Home Server Dashboard
logo:
  icon: mdi-server-network
background:
  image: https://images.unsplash.com/photo-1451187580459-43490279c0fa
theme: dark
cardBlur: md
```

### services.yaml

Сервисы для мониторинга их состояния (online/offline):

```yaml
- Infrastructure:
    - Traefik:
        href: http://traefik.home.local/dashboard/
        description: Reverse Proxy & Load Balancer
        widget:
          type: traefik
          url: http://traefik.home.local
          icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@master/png/traefik.png
```

### bookmarks.yaml

Закладки - быстрые ссылки на сервисы:

```yaml
- Infrastructure:
    - Traefik:
        - abbr: TF
          href: http://traefik.home.local/dashboard/
          description: Reverse Proxy Dashboard
```

### widgets.yaml

Информационные виджеты:

```yaml
# Ресурсы системы
- resource:
    cpu: true
    memory: true
    disk: /

# Погода (Open-Meteo, бесплатный API)
- openmeteo:
    label: Kaliningrad
    latitude: 54.7104
    longitude: 20.4522
    units: metric
    timezone: Europe/Kaliningrad
    forecast: days=3
```

## ➕ Добавление нового сервиса

### Пример: Добавить Portainer

1. Отредактируй `compose/homepage/config/services.yaml`:

```yaml
- Infrastructure:
    - Portainer:
        href: http://portainer.home.local
        description: Docker Management UI
        widget:
          type: portainer
          url: http://portainer.home.local
          icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@master/png/portainer.png
```

2. Отредактируй `compose/homepage/config/bookmarks.yaml`:

```yaml
- Infrastructure:
    - Portainer:
        - abbr: PT
          href: http://portainer.home.local
          description: Docker Management UI
```

3. Деплой:
```bash
git add compose/homepage/config/
git commit -m "add Portainer to Homepage"
git push

# На сервере:
cd /srv/homelab/homelab-server
git pull
./scripts/deploy.sh
```

## 🎨 Доступные widget типы

Homepage поддерживает множество виджетов:

- **Infrastructure**: traefik, portainer, glances, pihole, etc.
- **Media**: plex, jellyfin, sonarr, radarr, etc.
- **Cloud**: nextcloud, dropbox, etc.
- **Networking**: cloudflare, etc.
- **And many more!** - [см. документацию](https://gethomepage.dev/latest/widgets/)

## 🌐 Иконки

Используется [dashboard-icons](https://github.com/walkxcode/dashboard-icons):

```yaml
icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@master/png/traefik.png
```

Или Material Design Icons:

```yaml
logo:
  icon: mdi-server-network
```

## ⚙️ Скрипт деплоя Homepage конфигов

Скрипт `scripts/deploy-homepage-config.sh` делает следующее:

1. **Проверяет** исходную директорию `compose/homepage/config/`
2. **Создаёт** целевую директорию `/srv/data/homepage/config/` (если нужно)
3. **Бэкапит** существующие конфиги (если есть)
4. **Копирует** все YAML файлы из репозитория в `/srv/data/`
5. **Проверяет** что копирование прошло успешно

Бэкапы создаются в виде: `/srv/data/homepage/config.backup.YYYYMMDD_HHMMSS`

## ⚙️ Деплой

### Полный деплой (все сервисы + конфиги)

```bash
# На сервере
cd /srv/homelab/homelab-server
./scripts/deploy.sh
```

**Что делает:**
1. Копирует конфиги Homepage из репозитория в `/srv/data/`
2. Останавливает все контейнеры
3. Запускает все контейнеры с обновлёнными конфигами
4. Проверяет здоровье сервисов

### Только конфиги Homepage (без перезапуска всех сервисов)

```bash
# На сервере
cd /srv/homelab/homelab-server
./scripts/deploy-homepage-config.sh

# Перезапустить только Homepage
docker compose -f compose/compose.yml restart homepage
```

### Только перезапуск Homepage

```bash
docker compose -f compose/compose.yml restart homepage
```

## 📖 Документация

- [Homepage Official Documentation](https://gethomepage.dev/)
- [Bookmarks Configuration](https://gethomepage.dev/latest/configs/bookmarks/)
- [Services Configuration](https://gethomepage.dev/latest/configs/services/)
- [Settings Configuration](https://gethomepage.dev/latest/configs/settings/)
- [Widgets Documentation](https://gethomepage.dev/latest/widgets/)

## ⚠️ Важные примечания

1. **Источники правды:**
   - `compose/homepage/config/` - исходные конфиги (в репозитории)
   - `/srv/data/homepage/config/` - рабочие конфиги (на сервере, копируются при деплое)

2. **Изменения в `/srv/data/` будут перезаписаны** при следующем деплое. Всегда редактируй файлы в `compose/homepage/config/`!

3. **YAML отступы:** Используй 2 пробела для отступов. YAML чувствителен к отступам!

4. **Чувствительные данные:** Не коммить API ключи и пароли! Используй переменные окружения в `.env` если нужно.

5. **Бэкапы:** Скрипт автоматически создаёт бэкап перед копированием конфигов.

6. **Git контроль:** Всегда коммить изменения в `compose/homepage/config/` - это источник правды!

## 🔧 Troubleshooting

### Homepage показывает старую версию конфигов

**Проблема:** Изменял конфиги, но в браузере ничего не изменилось.

**Решение:**
```bash
# Перезапусти контейнер
docker compose -f compose/compose.yml restart homepage

# Или сбрось кэш браузера (Ctrl+Shift+R / Cmd+Shift+R)
```

### Изменения в конфигах не применяются

**Проблема:** Отредактировал `compose/homepage/config/`, но Homepage не изменился.

**Решение:**
```bash
# Конфиги нужно скопировать в /srv/data/
./scripts/deploy-homepage-config.sh

# И перезапустить контейнер
docker compose -f compose/compose.yml restart homepage
```

### Ошибка валидации YAML

**Проблема:** Homepage не запускается с ошибкой `Invalid YAML`.

**Решение:**
```bash
# Проверь YAML синтаксис
cat compose/homepage/config/services.yaml

# Обрати внимание на:
# - Отступы (2 пробела)
# - Кавычки
# - Пустые строки
# - Специальные символы
```

### Скрипт деплоя не работает

**Проблема:** Ошибка при запуске `./scripts/deploy-homepage-config.sh`

**Решение:**
```bash
# Проверь права доступа
ls -la scripts/deploy-homepage-config.sh
# Должен быть executable

# Если нет, сделай исполняемым
chmod +x scripts/deploy-homepage-config.sh

# Проверь что ты на сервере
ls /srv/data
# Должна существовать
```

### Восстановление из бэкапа

**Проблема:** Нужно откатить изменения конфигов.

**Решение:**
```bash
# Найти бэкап
ls -la /srv/data/ | grep homepage.config.backup

# Восстановить из бэкапа
sudo rm -rf /srv/data/homepage/config
sudo cp -r /srv/data/homepage.config.backup.YYYYMMDD_HHMMSS /srv/data/homepage/config

# Перезапустить Homepage
docker compose -f compose/compose.yml restart homepage
```

### Виджет не показывает статус

**Проблема:** Сервис отображается как "Unknown" или "Offline".

**Решение:**
1. Проверь, что сервис доступен: `curl http://service.home.local`
2. Проверь логи сервиса: `docker logs homelab-service`
3. Проверь логи Homepage: `docker logs homelab-homepage`
