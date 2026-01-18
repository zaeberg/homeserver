# Homepage Configuration

Эта директория содержит примеры конфигурационных файлов для Homepage.

## Структура

```
infra/homepage/
├── README.md                # Этот файл
└── config-examples/         # Примеры конфигов
    ├── bookmarks.yaml       # Закладки (ссылки на сервисы)
    ├── services.yaml        # Сервисы для мониторинга состояния
    ├── settings.yaml        # Основные настройки (тема, заголовок, etc.)
    ├── widgets.yaml         # Информационные виджеты
    └── docker.yaml          # Интеграция с Docker (опционально)
```

## Установка на сервере

### 1. Создать директорию для конфигов

```bash
sudo mkdir -p /srv/data/homepage/config
```

### 2. Скопировать примеры конфигов

```bash
# Из директории репозитория на сервере
cp infra/homepage/config-examples/*.yaml /srv/data/homepage/config/
```

### 3. Отредактировать конфиги по необходимости

```bash
cd /srv/data/homepage/config
nano bookmarks.yaml  # Добавить свои закладки
nano settings.yaml   # Настроить тему, заголовок, etc.
```

## Минимальная конфигурация

Для базовой работы Homepage нужны только файлы:

- **`bookmarks.yaml`** — обязательно (пусть будет пустым или с одной закладкой)
- **`services.yaml`** — опционально (мониторинг состояния сервисов)
- **`settings.yaml`** — опционально (есть дефолтные значения)
- **`widgets.yaml`** — опционально (информационные виджеты)
- **`docker.yaml`** — опционально (интеграция с Docker)

## Документация

- [Homepage Documentation](https://gethomepage.dev/)
- [Bookmarks Configuration](https://gethomepage.dev/latest/configs/bookmarks/)
- [Services Configuration](https://gethomepage.dev/latest/configs/services/)
- [Settings Configuration](https://gethomepage.dev/latest/configs/settings/)
- [Widgets Configuration](https://gethomepage.dev/latest/widgets/)

## Примечания

- Все файлы валидны и могут быть использованы как есть
- В примерах есть закомментированные секции для будущего использования
- YAML чувствителен к отступам (используйте 2 пробела)
