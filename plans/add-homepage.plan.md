# Add Homepage Dashboard

**Status**: `ready`

## Problem Statement
Добавить дашборд Homepage как главную страницу homelab сервера. Сервис должен быть доступен по адресу `home.local` в локальной сети и содержать навигационные ссылки на другие сервисы, начиная с Traefik.

## Problem Analysis
**Почему это нужно:**
- **Централизованная точка входа**: Вместо того чтобы помнить адреса всех сервисов (traefik.home.local, portainer.home.local и т.д.), пользователь получает одну главную страницу со всеми ссылками
- **Удобство**: Homepage предоставляет красивый интерфейс с возможностью добавления виджетов, закладок и мониторинга состояния сервисов
- **Масштабируемость**: В будущем можно легко добавлять новые сервисы и виджеты без изменения кода, только через YAML конфиги

**Что будет сделано:**
1. Добавится контейнер Homepage в docker compose стек
2. Настроится маршрутизация через Traefik на `home.local`
3. Настроится mDNS публикация через traefik-avahi-helper
4. Создастся базовая конфигурация с одной закладкой на Traefik

**Технические детали:**
- Используется официальный образ: `ghcr.io/gethomepage/homepage:latest`
- Порт контейнера: 3000
- Конфигурация через YAML файлы в `/srv/data/homepage/config`
- Docker socket подключается только для будущих интеграций (опционально)

## Questions Resolved
- Q: Какой подход конфигурации использовать?
  A: YAML файлы. Пользователь выбрал классический подход через конфигурационные файлы.

- Q: Какие виджеты добавить?
  A: Только ссылка на Traefik. Минимальная конфигурация без виджетов.

## Edge Cases & Considerations
- [ ] Порт 3000 уже занят → Traefik маршрутизирует внутренний порт, так что конфликтов не будет
- [ ] Проблемы с правами на docker socket → Можно убрать volume с docker.sock, так как он не обязателен для базовой работы
- [ ] mDNS не публикует сервис → Нужно проверить что avahi-daemon установлен на хосте
- [ ] Конфигурационные файлы не созданы → Нужно создать директорию и базовые файлы bookmarks.yaml, settings.yaml
- [ ] Конфликт с Traefik dashboard на traefik.home.local → Конфликта нет, это разные сервисы на разных хостах

## Relevant Context
- `compose/compose.yml:27-85` - Текущая конфигурация Traefik с labels для routing
- `compose/traefik/traefik.yml` - Traefik статическая конфигурация
- `compose/traefik/dynamic.yml` - Traefik динамическая конфигурация (middlewares)
- `docs/07_adding_services.md` - Документация по добавлению новых сервисов
- `scripts/deploy.sh` - Скрипт деплоя для запуска изменений
- `scripts/validate.sh` - Скрипт валидации конфигурации

## Feature Steps

### 1. Пользователь может получить доступ к главной странице homelab по адресу home.local
- **Business Value**: Централизованная точка входа для всех сервисов домашнего сервера. Пользователю больше не нужно запоминать адреса каждого сервиса.
- **Depends on**: none
- **Definition of Done**:
  - [x] Контейнер Homepage добавлен в `compose/compose.yml` ✓
  - [x] Конфигурация валидна (проверено через `docker compose config`) ✓
  - [ ] Сервис доступен по адресу http://home.local из локальной сети (требует деплоя на сервере)
  - [ ] `curl -I http://home.local` с сервера возвращает HTTP 200 (требует деплоя на сервере)
  - [ ] Браузер на клиенте открывает http://home.local и показывает главную страницу (требует деплоя на сервере)
  - [ ] mDNS корректно публикует сервис (виден в сети как home.local) (требует деплоя на сервере)
  - [ ] Traefik маршрутизирует запросы на контейнер Homepage (требует деплоя на сервере)
  - [ ] Сервис появляется в Traefik Dashboard (требует деплоя на сервере)
  - [ ] Контейнер имеет статус "healthy" после запуска (требует деплоя на сервере)
- **Touches**: `compose/compose.yml`

### 2. Пользователь видит на главной странице ссылку на Traefik Dashboard
- **Business Value**: Быстрый доступ к управлению маршрутизацией без запоминания адреса. Это базовая навигация, которая будет расширяться в будущем.
- **Depends on**: "Пользователь может получить доступ к главной странице homelab по адресу home.local"
- **Definition of Done**:
  - [x] Созданы пример конфигурационных файлов в `infra/homepage/config-examples/` ✓
  - [x] `bookmarks.yaml` содержит закладку на Traefik ✓
  - [x] Все YAML файлы валидны (проверено через Python yaml.safe_load) ✓
  - [ ] Создана директория `/srv/data/homepage/config` на сервере (требует выполнения на сервере)
  - [ ] Конфиги скопированы на сервер (требует выполнения на сервере)
  - [ ] На странице Homepage отображается группа "Infrastructure" (требует деплоя на сервере)
  - [ ] В группе есть ссылка "Traefik" с аббревиатурой "TF" (требует деплоя на сервере)
  - [ ] Ссылка открывает http://traefik.home.local/dashboard/ (требует проверки в браузере)
  - [ ] При наведении на ссылку показывается описание (требует проверки в браузере)
- **Touches**: `/srv/data/homepage/config/bookmarks.yaml` (создаётся на сервере)

## Testing Strategy

**Метод деплоя:**
- Git pull на сервере
- После коммита изменений: `git pull` на сервере, затем `docker compose -f compose/compose.yml up -d homepage`

**Проверка работоспособности:**

1. **Серверная проверка (curl):**
   ```bash
   # Проверка HTTP ответа
   curl -I http://home.local

   # Ожидаемый результат: HTTP/1.1 200 OK
   ```

2. **Клиентская проверка (браузер):**
   - Открыть http://home.local в браузере с устройства в локальной сети
   - Проверить что загружается главная страница Homepage
   - Проверить что отображается закладка на Traefik

3. **Проверка в Traefik Dashboard (опционально):**
   - Открыть http://traefik.home.local/dashboard/
   - Проверить что сервис homepage виден в HTTP routers

4. **Проверка логов (в случае проблем):**
   ```bash
   docker logs homelab-homepage
   ```

**Unit/Integration тесты:**
- Homepage не предоставляет официальные tools для тестирования YAML конфигов
- Валидация YAML будет выполняться через онлайн validator перед коммитом
- Нет необходимости писать автоматические тесты для данного scope

## Notes

### [2026-01-18] Реализация в репозитории завершена

**Выполнено:**
- ✓ Контейнер Homepage добавлен в `compose/compose.yml`
- ✓ Созданы пример конфигов в `infra/homepage/config-examples/`:
  - `bookmarks.yaml` — с закладкой на Traefik
  - `services.yaml` — пустой, с примерами
  - `settings.yaml` — базовая конфигурация
  - `widgets.yaml` — пустой, с примерами
  - `docker.yaml` — для будущей Docker интеграции
- ✓ Создана документация `infra/homepage/README.md` и `DEPLOY.md`
- ✓ Все YAML файлы и compose конфиг валидны

**Требуется выполнение на сервере:**
1. `git pull` для получения изменений
2. Создать директорию `/srv/data/homepage/config`
3. Скопировать конфиги из `infra/homepage/config-examples/`
4. Запустить `docker compose -f compose/compose.yml up -d homepage`
5. Проверить работоспособность (curl + браузер)

Инструкции для деплоя: `infra/homepage/DEPLOY.md`
---
**Источники:**
- [Homepage Documentation](https://gethomepage.dev/)
- [Homepage Configuration Guide](https://gethomepage.dev/latest/configs/)
- [Bookmarks Configuration](https://gethomepage.dev/latest/configs/bookmarks/)
- [Docker Installation](https://gethomepage.dev/latest/installation/docker/)
- [Homepage GitHub](https://github.com/benphelps/homepage)
