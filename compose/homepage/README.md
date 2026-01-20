# Homepage Configuration

Homepage - это главная страница homelab с навигацией по всем сервисам, мониторингом их состояния и информационными виджетами.

## 📍 Расположение конфигов

**Конфигурационные файлы хранятся в репозитории:**
```
compose/homepage/config/
├── bookmarks.yaml       # Закладки (быстрые ссылки на сервисы)
├── services.yaml        # Сервисы для мониторинга состояния (online/offline)
├── settings.yaml        # Основные настройки (тема, заголовок, логотип)
└── widgets.yaml         # Информационные виджеты (ресурсы, погода, etc.)
```

**Они автоматически монтируются в контейнер при деплое.**

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
```

### Способ 2: На сервере (если нужно быстро поправить)

```bash
cd /srv/homelab/homelab-server
nano compose/homepage/config/services.yaml
./scripts/deploy.sh
```

⚠️ **Важно:** Все изменения в конфигах нужно коммитить в git! Иначе они потеряются при следующем деплое.

## 📁 Структура конфигов

### bookmarks.yaml

Закладки - быстрые ссылки на сервисы. Структура:

```yaml
- Infrastructure:
    - Traefik:
        - abbr: TF
          href: http://traefik.home.local/dashboard/
          description: Reverse Proxy & Load Balancer Dashboard
```

### services.yaml

Сервисы для мониторинга их состояния (online/offline). Homepage будет показывать статус для каждого сервиса:

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

1. Добавь в `services.yaml`:

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

2. Добавь в `bookmarks.yaml`:

```yaml
- Infrastructure:
    - Portainer:
        - abbr: PT
          href: http://portainer.home.local
          description: Docker Management UI
```

3. Деплой: `./scripts/deploy.sh`

## 🎨 Доступные widget типы

Homepage поддерживает множество виджетов для разных сервисов:

- **Infrastructure**: traefik, portainer, glances, pihole, etc.
- **Media**: plex, jellyfin, sonarr, radarr, etc.
- **Cloud**: nextcloud, dropbox, etc.
- **Networking**: cloudflare, etc.
- **And many more!** - [см. документацию](https://gethomepage.dev/latest/widgets/)

## 🌐 Иконки

Для иконок используется [dashboard-icons](https://github.com/walkxcode/dashboard-icons):

```yaml
icon: https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons@master/png/traefik.png
```

Или Material Design Icons (для логотипа):

```yaml
logo:
  icon: mdi-server-network
```

## ⚙️ Деплой

```bash
# Применить изменения конфигов
./scripts/deploy.sh

# Перезапустить только Homepage
docker compose -f compose/compose.yml restart homepage

# Посмотреть логи
docker logs homelab-homepage
```

## 📖 Документация

- [Homepage Official Documentation](https://gethomepage.dev/)
- [Bookmarks Configuration](https://gethomepage.dev/latest/configs/bookmarks/)
- [Services Configuration](https://gethomepage.dev/latest/configs/services/)
- [Settings Configuration](https://gethomepage.dev/latest/configs/settings/)
- [Widgets Documentation](https://gethomepage.dev/latest/widgets/)
- [Docker Integration](https://gethomepage.dev/latest/configs/docker/)

## ⚠️ Важные примечания

1. **Конфиги только для чтения:** Контейнер монтирует конфиги как `read-only`. Редактирование через веб-интерфейс невозможно (и не нужно - всё в git!)

2. **YAML отступы:** Используй 2 пробела для отступов. YAML чувствителен к отступам!

3. **Валидация:** Перед деплоем проверь YAML синтаксис:
   ```bash
   # Валидация YAML (требуется python-yaml)
   python3 -c "import yaml; yaml.safe_load(open('compose/homepage/config/services.yaml'))"
   ```

4. **Чувствительные данные:** Не коммить API ключи и пароли! Используй переменные окружения в `.env` если нужно.

5. **Бэкап:** Конфиги автоматически бэкапятся как часть репозитория (через `BACKUP_TARGETS`).

## 🔧 Troubleshooting

### Homepage показывает старую версию конфигов

**Проблема:** Изменял конфиги, но в браузере ничего не изменилось.

**Решение:**
```bash
# Перезапусти контейнер
docker compose -f compose/compose.yml restart homepage

# Или сбрось кэш браузера (Ctrl+Shift+R / Cmd+Shift+R)
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

### Виджет не показывает статус

**Проблема:** Сервис отображается как "Unknown" или "Offline".

**Решение:**
1. Проверь, что сервис доступен: `curl http://service.home.local`
2. Проверь логи сервиса: `docker logs homelab-service`
3. Проверь логи Homepage: `docker logs homelab-homepage`

## 📦 Архивная документация

Старая документация (для версии с конфигами в `/srv/data/`) доступна в `infra/homepage/DEPLOY.md`.
